import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexi_trainer/core/auth/current_user_role_provider.dart';
import 'package:lexi_trainer/core/auth/sign_out_button.dart';
import 'package:lexi_trainer/core/auth/user_role.dart';
import 'package:lexi_trainer/core/theme/app_colors.dart';
import 'package:lexi_trainer/features/admin/data/models/admin_list_items.dart';
import 'package:lexi_trainer/features/admin/data/models/admin_report_metrics.dart';
import 'package:lexi_trainer/features/admin/data/models/admin_user_list_items.dart';
import 'package:lexi_trainer/features/admin/data/models/admin_vocabulary_word_input.dart';
import 'package:lexi_trainer/features/admin/data/repositories/admin_repository.dart';
import 'package:lexi_trainer/features/admin/presentation/admin_report_pdf_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  AdminRepository get _repository => ref.read(adminRepositoryProvider);

  void _refreshSets() {
    ref.invalidate(adminVocabularySetsProvider);
  }

  void _refreshGroups() {
    ref.invalidate(adminStudyGroupsProvider);
  }

  void _refreshTasks() {
    ref.invalidate(adminTasksProvider);
  }

  void _refreshStudents() {
    ref.invalidate(adminStudentsProvider);
  }

  void _refreshUsers() {
    ref.invalidate(adminUsersProvider);
  }

  void _refreshRoles() {
    ref.invalidate(adminRolesProvider);
  }

  Future<void> _showReport() async {
    ref.invalidate(adminReportMetricsProvider);
    await showDialog<void>(
      context: context,
      builder: (context) => const _ReportDialog(),
    );
  }

  Future<void> _createSet() async {
    final data = await showDialog<_CreateSetData>(
      context: context,
      builder: (context) => const _CreateSetDialog(),
    );
    if (data == null) {
      return;
    }

    try {
      await _repository.createVocabularySetWithWords(
        themeName: data.themeName,
        cefrLevel: data.cefrLevel,
        words: data.words,
      );
      if (!mounted) {
        return;
      }
      _refreshSets();
      _showMessage('Словарный набор со словами создан.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _createGroup() async {
    final students = await _loadStudentsForGroupDialog();
    if (!mounted || students == null) {
      return;
    }

    final data = await showDialog<_GroupFormData>(
      context: context,
      builder: (context) => _StudyGroupFormDialog(
        title: 'Новая учебная группа',
        actionLabel: 'Создать',
        students: students,
      ),
    );
    if (data == null) {
      return;
    }

    try {
      await _repository.createStudyGroup(
        name: data.name,
        studentIds: data.studentIds,
      );
      if (!mounted) {
        return;
      }
      _refreshGroups();
      _refreshStudents();
      _showMessage('Группа создана.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _createUser() async {
    final refs = await _loadUserFormRefs();
    if (!mounted || refs == null) {
      return;
    }
    if (refs.roles.isEmpty) {
      _showMessage('Сначала добавьте роли в таблицу roles.');
      return;
    }

    final data = await showDialog<_UserFormData>(
      context: context,
      builder: (context) => _UserFormDialog(
        title: 'Новый пользователь',
        actionLabel: 'Создать',
        roles: refs.roles,
        groups: refs.groups,
      ),
    );
    if (data == null) {
      return;
    }

    try {
      await _repository.createUserProfile(
        id: data.id!,
        username: data.username,
        email: data.email,
        roleId: data.roleId,
        studyGroupId: data.studyGroupId,
      );
      if (!mounted) {
        return;
      }
      _refreshUsers();
      _refreshStudents();
      _showMessage('Профиль пользователя создан.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _createTask() async {
    final sets = await _loadVocabularySetsForTaskDialog();
    if (!mounted) {
      return;
    }
    if (sets == null) {
      return;
    }
    if (sets.isEmpty) {
      _showMessage('Сначала создайте словарный набор.');
      return;
    }

    final data = await showDialog<_TaskFormData>(
      context: context,
      builder: (context) => _TaskFormDialog(
        title: 'Новое задание',
        actionLabel: 'Создать',
        sets: sets,
      ),
    );
    if (data == null) {
      return;
    }

    try {
      await _repository.createTask(
        vocabularySetId: data.vocabularySetId,
        deadline: data.deadline,
        startDate: data.startDate,
        translateToRussian: data.translateToRussian,
        availableAfterEnd: data.availableAfterEnd,
        attemptsCount: data.attemptsCount,
      );
      if (!mounted) {
        return;
      }
      _refreshTasks();
      _showMessage('Задание создано.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<List<AdminVocabularySetListItem>?>
  _loadVocabularySetsForTaskDialog() async {
    final cachedSets = ref
        .read(adminVocabularySetsProvider)
        .maybeWhen(data: (sets) => sets, orElse: () => null);
    if (cachedSets != null) {
      return cachedSets;
    }

    try {
      return await ref.read(adminVocabularySetsProvider.future);
    } catch (_) {
      ref.invalidate(adminVocabularySetsProvider);
      try {
        return await ref.read(adminVocabularySetsProvider.future);
      } catch (error) {
        if (mounted) {
          _showLoadError(error);
        }
        return null;
      }
    }
  }

  Future<List<AdminStudentListItem>?> _loadStudentsForGroupDialog() async {
    final cachedStudents = ref
        .read(adminStudentsProvider)
        .maybeWhen(data: (students) => students, orElse: () => null);
    if (cachedStudents != null) {
      return cachedStudents;
    }

    try {
      return await ref.read(adminStudentsProvider.future);
    } catch (_) {
      ref.invalidate(adminStudentsProvider);
      try {
        return await ref.read(adminStudentsProvider.future);
      } catch (error) {
        if (mounted) {
          _showLoadError(error);
        }
        return null;
      }
    }
  }

  Future<_UserFormRefs?> _loadUserFormRefs() async {
    try {
      final roles = await ref.read(adminRolesProvider.future);
      final groups = await ref.read(adminStudyGroupsProvider.future);
      return _UserFormRefs(roles: roles, groups: groups);
    } catch (_) {
      _refreshRoles();
      _refreshGroups();
      try {
        final roles = await ref.read(adminRolesProvider.future);
        final groups = await ref.read(adminStudyGroupsProvider.future);
        return _UserFormRefs(roles: roles, groups: groups);
      } catch (error) {
        if (mounted) {
          _showLoadError(error);
        }
        return null;
      }
    }
  }

  Future<void> _editUser(AdminUserListItem item) async {
    final refs = await _loadUserFormRefs();
    if (!mounted || refs == null) {
      return;
    }
    if (refs.roles.isEmpty) {
      _showMessage('Сначала добавьте роли в таблицу roles.');
      return;
    }

    final data = await showDialog<_UserFormData>(
      context: context,
      builder: (context) => _UserFormDialog(
        title: 'Редактировать пользователя',
        actionLabel: 'Сохранить',
        roles: refs.roles,
        groups: refs.groups,
        initialItem: item,
      ),
    );
    if (data == null) {
      return;
    }

    try {
      await _repository.updateUserProfile(
        id: item.id,
        username: data.username,
        email: data.email,
        roleId: data.roleId,
        studyGroupId: data.studyGroupId,
      );
      if (!mounted) {
        return;
      }
      _refreshUsers();
      _refreshStudents();
      _showMessage('Профиль пользователя обновлен.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _deleteUser(AdminUserListItem item) async {
    final confirmed = await _confirmDelete(
      title: 'Удалить профиль пользователя?',
      message:
          'Профиль "${item.displayName}" будет удален из public.users. Auth-аккаунт при этом не удаляется.',
    );
    if (!confirmed) {
      return;
    }

    try {
      await _repository.deleteUserProfile(id: item.id);
      if (!mounted) {
        return;
      }
      _refreshUsers();
      _refreshStudents();
      _showMessage('Профиль пользователя удален.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _viewSet(AdminVocabularySetListItem item) async {
    try {
      final details = await _repository.fetchVocabularySetDetails(item.id);
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => _VocabularySetDetailsDialog(details: details),
      );
    } catch (error) {
      _showLoadError(error);
    }
  }

  Future<void> _editSet(AdminVocabularySetListItem item) async {
    final data = await showDialog<_SetMetadataFormData>(
      context: context,
      builder: (context) => _SetMetadataDialog(item: item),
    );
    if (data == null) {
      return;
    }

    try {
      await _repository.updateVocabularySet(
        id: item.id,
        themeName: data.themeName,
        cefrLevel: data.cefrLevel,
      );
      if (!mounted) {
        return;
      }
      _refreshSets();
      _refreshTasks();
      _showMessage('Словарный набор обновлен.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _deleteSet(AdminVocabularySetListItem item) async {
    final confirmed = await _confirmDelete(
      title: 'Удалить словарный набор?',
      message:
          'Словарный набор "${item.themeName}" будет удален. Связанные задания также могут быть удалены.',
    );
    if (!confirmed) {
      return;
    }

    try {
      await _repository.deleteVocabularySet(id: item.id);
      if (!mounted) {
        return;
      }
      _refreshSets();
      _refreshTasks();
      _showMessage('Словарный набор удален.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _viewGroup(AdminStudyGroupListItem item) async {
    try {
      final details = await _repository.fetchStudyGroupDetails(item.id);
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => _StudyGroupDetailsDialog(details: details),
      );
    } catch (error) {
      _showLoadError(error);
    }
  }

  Future<void> _editGroup(AdminStudyGroupListItem item) async {
    final students = await _loadStudentsForGroupDialog();
    if (!mounted || students == null) {
      return;
    }

    final data = await showDialog<_GroupFormData>(
      context: context,
      builder: (context) => _StudyGroupFormDialog(
        title: 'Редактировать группу',
        actionLabel: 'Сохранить',
        initialGroupId: item.id,
        initialName: item.name,
        students: students,
      ),
    );
    if (data == null) {
      return;
    }

    try {
      await _repository.updateStudyGroup(
        id: item.id,
        name: data.name,
        studentIds: data.studentIds,
      );
      if (!mounted) {
        return;
      }
      _refreshGroups();
      _refreshStudents();
      _showMessage('Группа обновлена.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _deleteGroup(AdminStudyGroupListItem item) async {
    final confirmed = await _confirmDelete(
      title: 'Удалить группу?',
      message:
          'Группа "${item.name}" будет удалена. Студенты останутся без текущей группы.',
    );
    if (!confirmed) {
      return;
    }

    try {
      await _repository.deleteStudyGroup(id: item.id);
      if (!mounted) {
        return;
      }
      _refreshGroups();
      _refreshStudents();
      _showMessage('Группа удалена.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _viewTask(AdminTaskListItem item) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _TaskDetailsDialog(item: item),
    );
  }

  Future<void> _editTask(AdminTaskListItem item) async {
    final sets = await _loadVocabularySetsForTaskDialog();
    if (!mounted || sets == null) {
      return;
    }
    if (sets.isEmpty) {
      _showMessage('Сначала создайте словарный набор.');
      return;
    }

    final data = await showDialog<_TaskFormData>(
      context: context,
      builder: (context) => _TaskFormDialog(
        title: 'Редактировать задание',
        actionLabel: 'Сохранить',
        sets: sets,
        initialItem: item,
      ),
    );
    if (data == null) {
      return;
    }

    try {
      await _repository.updateTask(
        id: item.id,
        vocabularySetId: data.vocabularySetId,
        deadline: data.deadline,
        startDate: data.startDate,
        translateToRussian: data.translateToRussian,
        availableAfterEnd: data.availableAfterEnd,
        attemptsCount: data.attemptsCount,
      );
      if (!mounted) {
        return;
      }
      _refreshTasks();
      _showMessage('Задание обновлено.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _deleteTask(AdminTaskListItem item) async {
    final confirmed = await _confirmDelete(
      title: 'Удалить задание?',
      message: 'Задание по набору "${item.vocabularySetName}" будет удалено.',
    );
    if (!confirmed) {
      return;
    }

    try {
      await _repository.deleteTask(id: item.id);
      if (!mounted) {
        return;
      }
      _refreshTasks();
      _showMessage('Задание удалено.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<bool> _confirmDelete({
    required String title,
    required String message,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(Object error) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Не удалось сохранить: $error')));
  }

  void _showLoadError(Object error) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Не удалось загрузить данные: $error')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleAsyncValue = ref.watch(currentUserRoleProvider);

    return roleAsyncValue.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => _AdminAccessDeniedScreen(
        title: 'Не удалось проверить доступ',
        message:
            'Проверьте соединение и попробуйте еще раз. Если ошибка повторяется, войдите в аккаунт заново.',
        actionLabel: 'Повторить',
        onAction: () => ref.invalidate(currentUserRoleProvider),
      ),
      data: (role) {
        if (!role.canOpenAdminSection) {
          return _AdminAccessDeniedScreen(
            title: 'Доступ к админ-панели закрыт',
            message:
                'Эта страница доступна только администраторам и преподавателям.',
            actionLabel: 'Назад',
            onAction: () {
              Navigator.of(context).maybePop();
            },
          );
        }

        final sets = ref.watch(adminVocabularySetsProvider);
        final tasks = ref.watch(adminTasksProvider);
        final isAdmin = role == UserRole.admin;
        final panelTitle = isAdmin
            ? '\u041f\u0430\u043d\u0435\u043b\u044c \u0430\u0434\u043c\u0438\u043d\u0438\u0441\u0442\u0440\u0430\u0442\u043e\u0440\u0430'
            : '\u041f\u0430\u043d\u0435\u043b\u044c \u043f\u0440\u0435\u043f\u043e\u0434\u0430\u0432\u0430\u0442\u0435\u043b\u044f';
        final users = isAdmin ? ref.watch(adminUsersProvider) : null;
        final groups = ref.watch(adminStudyGroupsProvider);
        final tabs = <Tab>[
          if (isAdmin) const Tab(text: 'Пользователи'),
          if (isAdmin) const Tab(text: 'Группы'),
          const Tab(text: '\u041a\u043e\u043d\u0442\u0435\u043d\u0442'),
          const Tab(text: '\u0417\u0430\u0434\u0430\u043d\u0438\u044f'),
          if (!isAdmin) const Tab(text: 'Группы'),
        ];
        final tabViews = <Widget>[
          if (isAdmin)
            _UserManagementTab(
              items: users!,
              onRefresh: _refreshUsers,
              onCreate: _createUser,
              onEdit: _editUser,
              onDelete: _deleteUser,
            ),
          if (isAdmin)
            _GroupManagementTab(
              items: groups,
              onRefresh: _refreshGroups,
              onCreate: _createGroup,
              onView: _viewGroup,
              onEdit: _editGroup,
              onDelete: _deleteGroup,
              readOnly: false,
            ),
          _ContentManagementTab(
            items: sets,
            onRefresh: _refreshSets,
            onCreate: _createSet,
            onView: _viewSet,
            onEdit: _editSet,
            onDelete: _deleteSet,
          ),
          _TaskManagementTab(
            items: tasks,
            onRefresh: _refreshTasks,
            onCreate: _createTask,
            onView: _viewTask,
            onEdit: _editTask,
            onDelete: _deleteTask,
          ),
          if (!isAdmin)
            _GroupManagementTab(
              items: groups,
              onRefresh: _refreshGroups,
              onView: _viewGroup,
              readOnly: true,
            ),
        ];

        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            appBar: AppBar(
              title: Text(panelTitle),
              actions: [
                if (role.canOpenAdminSection)
                  IconButton(
                    tooltip: 'Отчет',
                    onPressed: _showReport,
                    icon: const Icon(Icons.receipt_long_outlined),
                  ),
                const SignOutButton(),
              ],
              bottom: TabBar(tabs: tabs),
            ),
            body: TabBarView(children: tabViews),
          ),
        );
      },
    );
  }
}

class _AdminAccessDeniedScreen extends StatelessWidget {
  const _AdminAccessDeniedScreen({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Админ-раздел')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(message),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: onAction,
                      child: Text(actionLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentManagementTab extends StatelessWidget {
  const _ContentManagementTab({
    required this.items,
    required this.onRefresh,
    required this.onCreate,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final AsyncValue<List<AdminVocabularySetListItem>> items;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;
  final ValueChanged<AdminVocabularySetListItem> onView;
  final ValueChanged<AdminVocabularySetListItem> onEdit;
  final ValueChanged<AdminVocabularySetListItem> onDelete;

  @override
  Widget build(BuildContext context) {
    return _TabLayout<AdminVocabularySetListItem>(
      title: 'Управление словарями',
      description:
          'Создавайте словарные наборы, наполняйте их словами и используйте как основу для заданий.',
      actionText: 'Добавить словарный набор',
      emptyText: 'Словарных наборов пока нет.',
      items: items,
      onRefresh: onRefresh,
      onCreate: onCreate,
      itemBuilder: (item) => _AdminItemCard(
        title: 'Тема: ${item.themeName}',
        subtitle:
            'CEFR ${item.cefrLevel} · автор: ${item.authorName} · создано: ${_formatDate(item.createdAt)}',
        status: 'Доступно',
        onView: () => onView(item),
        onEdit: () => onEdit(item),
        onDelete: () => onDelete(item),
      ),
    );
  }
}

class _UserManagementTab extends StatelessWidget {
  const _UserManagementTab({
    required this.items,
    required this.onRefresh,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  final AsyncValue<List<AdminUserListItem>> items;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;
  final ValueChanged<AdminUserListItem> onEdit;
  final ValueChanged<AdminUserListItem> onDelete;

  @override
  Widget build(BuildContext context) {
    return _TabLayout<AdminUserListItem>(
      title: 'Пользователи',
      description:
          'Создавайте профили для существующих auth UUID, меняйте роли и учебные группы.',
      actionText: 'Добавить пользователя',
      emptyText: 'Пользователей пока нет.',
      items: items,
      onRefresh: onRefresh,
      onCreate: onCreate,
      itemBuilder: (item) => _AdminItemCard(
        title: item.displayName,
        subtitle: item.subtitle,
        status: item.roleLabel,
        onEdit: () => onEdit(item),
        onDelete: () => onDelete(item),
      ),
    );
  }
}

class _GroupManagementTab extends StatelessWidget {
  const _GroupManagementTab({
    required this.items,
    required this.onRefresh,
    required this.onView,
    this.onCreate,
    this.onEdit,
    this.onDelete,
    this.readOnly = false,
  });

  final AsyncValue<List<AdminStudyGroupListItem>> items;
  final VoidCallback onRefresh;
  final VoidCallback? onCreate;
  final ValueChanged<AdminStudyGroupListItem> onView;
  final ValueChanged<AdminStudyGroupListItem>? onEdit;
  final ValueChanged<AdminStudyGroupListItem>? onDelete;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return _TabLayout<AdminStudyGroupListItem>(
      title: 'Управление учебными группами',
      description: readOnly
          ? 'Просматривайте учебные группы и состав студентов.'
          : 'Создавайте учебные группы для дальнейшего назначения студентов и преподавателей.',
      actionText: readOnly ? null : 'Создать группу',
      emptyText: 'Учебных групп пока нет.',
      items: items,
      onRefresh: onRefresh,
      onCreate: onCreate,
      itemBuilder: (item) => _AdminItemCard(
        title: 'Группа ${item.name}',
        subtitle: 'Создана: ${_formatDate(item.createdAt)}',
        status: 'Активна',
        onView: () => onView(item),
        onEdit: onEdit == null ? null : () => onEdit!(item),
        onDelete: onDelete == null ? null : () => onDelete!(item),
      ),
    );
  }
}

class _TaskManagementTab extends StatelessWidget {
  const _TaskManagementTab({
    required this.items,
    required this.onRefresh,
    required this.onCreate,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final AsyncValue<List<AdminTaskListItem>> items;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;
  final ValueChanged<AdminTaskListItem> onView;
  final ValueChanged<AdminTaskListItem> onEdit;
  final ValueChanged<AdminTaskListItem> onDelete;

  @override
  Widget build(BuildContext context) {
    return _TabLayout<AdminTaskListItem>(
      title: 'Управление заданиями',
      description:
          'Планируйте дедлайны, количество попыток и направление перевода.',
      actionText: 'Создать задание',
      emptyText: 'Заданий пока нет.',
      items: items,
      onRefresh: onRefresh,
      onCreate: onCreate,
      itemBuilder: (item) => _AdminItemCard(
        title: 'Задание: ${item.vocabularySetName}',
        subtitle: _taskSubtitle(item),
        status: _taskStatus(item),
        onView: () => onView(item),
        onEdit: () => onEdit(item),
        onDelete: () => onDelete(item),
      ),
    );
  }
}

class _ReportDialog extends ConsumerStatefulWidget {
  const _ReportDialog();

  @override
  ConsumerState<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<_ReportDialog> {
  void _refreshReport() {
    ref.invalidate(adminReportMetricsProvider);
  }

  Future<void> _downloadPdf(AdminReportMetrics metrics) async {
    try {
      final generatedAt = DateTime.now();
      final fileName = 'otchet_${_formatPdfFileStamp(generatedAt)}.pdf';
      final bytes = await AdminReportPdfHelper.build(
        metrics: metrics,
        generatedAt: generatedAt,
      );

      if (kIsWeb) {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF сформирован: $fileName')));
        return;
      }

      final targetDirectory =
          await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final filePath =
          '${targetDirectory.path}${Platform.pathSeparator}$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF сохранен: $filePath')));
    } on MissingPluginException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Плагин печати недоступен. PDF сохранение отключено.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось создать PDF: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(adminReportMetricsProvider);
    final reportMetrics = metricsAsync.maybeWhen(
      data: (metrics) => metrics,
      orElse: () => null,
    );
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      scrollable: true,
      title: const Text('Отчет по текущей базе'),
      content: SizedBox(
        width: 520,
        child: metricsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Не удалось сформировать отчет',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('$error'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _refreshReport,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          ),
          data: (AdminReportMetrics metrics) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ReportMetricCard(
                title: 'Количество доступных словарных наборов',
                value: metrics.vocabularySetCount.toString(),
                icon: Icons.menu_book_outlined,
                accentColor: Theme.of(context).colorScheme.primary,
              ),
              _ReportMetricCard(
                title: 'Количество назначенных заданий',
                value: metrics.taskCount.toString(),
                icon: Icons.assignment_outlined,
                accentColor: Theme.of(context).colorScheme.tertiary,
              ),
              _ReportMetricCard(
                title: 'Количество выполненных заданий',
                value: metrics.completedTaskCount.toString(),
                icon: Icons.check_circle_outline,
                accentColor: AppColors.success,
              ),
              _ReportMetricCard(
                title: 'Средняя точность ответов',
                value: _formatPercent(metrics.averageAnswerAccuracyPercent),
                icon: Icons.insights_outlined,
                accentColor: Theme.of(context).colorScheme.secondary,
              ),
              _ReportMetricCard(
                title: 'Количество активных студентов',
                value: metrics.activeStudentCount.toString(),
                icon: Icons.groups_outlined,
                accentColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
        OutlinedButton.icon(
          onPressed: _refreshReport,
          icon: const Icon(Icons.refresh),
          label: const Text('Обновить'),
        ),
        FilledButton.icon(
          onPressed: reportMetrics == null
              ? null
              : () => _downloadPdf(reportMetrics),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Скачать PDF'),
        ),
      ],
    );
  }
}

String _formatPdfFileStamp(DateTime dateTime) {
  final local = dateTime.toLocal();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)}_'
      '${twoDigits(local.hour)}-${twoDigits(local.minute)}-${twoDigits(local.second)}';
}

class _ReportMetricCard extends StatelessWidget {
  const _ReportMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VocabularySetDetailsDialog extends StatelessWidget {
  const _VocabularySetDetailsDialog({required this.details});

  final AdminVocabularySetDetails details;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Детали словарного набора'),
      content: SizedBox(
        width: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _DetailRow(label: 'Тема', value: details.themeName),
            _DetailRow(label: 'CEFR', value: details.cefrLevel),
            _DetailRow(label: 'Создан', value: _formatDate(details.createdAt)),
            _DetailRow(label: 'Автор', value: details.authorName),
            const SizedBox(height: 16),
            Text(
              'Слова',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (details.words.isEmpty)
              const Text('Слова не найдены.')
            else
              ...details.words.map(
                (word) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      '${word.russianWord} - ${word.englishTranslation}',
                    ),
                    subtitle: Text(
                      [
                        if (word.transcription?.isNotEmpty ?? false)
                          'Транскрипция: ${word.transcription}',
                        if (word.exampleSentence?.isNotEmpty ?? false)
                          'Пример: ${word.exampleSentence}',
                      ].join('\n'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
}

class _StudyGroupDetailsDialog extends StatelessWidget {
  const _StudyGroupDetailsDialog({required this.details});

  final AdminStudyGroupDetails details;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Детали учебной группы'),
      content: SizedBox(
        width: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _DetailRow(label: 'Название', value: details.name),
            _DetailRow(label: 'Создана', value: _formatDate(details.createdAt)),
            const SizedBox(height: 16),
            Text(
              'Участники',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (details.members.isEmpty)
              const Text('В группе пока нет студентов.')
            else
              ...details.members.map(
                (member) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(member.displayName),
                  subtitle: Text(member.email),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
}

class _TaskDetailsDialog extends StatelessWidget {
  const _TaskDetailsDialog({required this.item});

  final AdminTaskListItem item;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Детали задания'),
      content: SizedBox(
        width: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _DetailRow(label: 'Словарный набор', value: item.vocabularySetName),
            _DetailRow(
              label: 'Дата начала',
              value: _formatNullableDate(item.startDate),
            ),
            _DetailRow(
              label: 'Дедлайн',
              value: _formatNullableDate(item.deadline),
            ),
            _DetailRow(
              label: 'Количество попыток',
              value: item.attemptsCount.toString(),
            ),
            _DetailRow(
              label: 'Направление',
              value: item.translateToRussian
                  ? 'Перевод на русский'
                  : 'Перевод на английский',
            ),
            _DetailRow(
              label: 'После дедлайна',
              value: item.availableAfterEnd ? 'Доступно' : 'Недоступно',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
}

class _SetMetadataDialog extends StatefulWidget {
  const _SetMetadataDialog({required this.item});

  final AdminVocabularySetListItem item;

  @override
  State<_SetMetadataDialog> createState() => _SetMetadataDialogState();
}

class _SetMetadataDialogState extends State<_SetMetadataDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _themeController;
  late final TextEditingController _cefrController;

  @override
  void initState() {
    super.initState();
    _themeController = TextEditingController(text: widget.item.themeName);
    _cefrController = TextEditingController(text: widget.item.cefrLevel);
  }

  @override
  void dispose() {
    _themeController.dispose();
    _cefrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редактировать словарный набор'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _themeController,
              decoration: const InputDecoration(labelText: 'Название темы'),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cefrController,
              decoration: const InputDecoration(labelText: 'CEFR уровень'),
              textCapitalization: TextCapitalization.characters,
              validator: _cefrLevelValidator,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop(
              _SetMetadataFormData(
                themeName: _themeController.text.trim(),
                cefrLevel: _cefrController.text.trim().toUpperCase(),
              ),
            );
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _TabLayout<T> extends StatelessWidget {
  const _TabLayout({
    required this.title,
    required this.description,
    required this.emptyText,
    required this.items,
    required this.onRefresh,
    required this.itemBuilder,
    this.actionText,
    this.onCreate,
  });

  final String title;
  final String description;
  final String? actionText;
  final String emptyText;
  final AsyncValue<List<T>> items;
  final VoidCallback onRefresh;
  final VoidCallback? onCreate;
  final Widget Function(T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          title,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(description),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (actionText != null && onCreate != null)
              ElevatedButton(onPressed: onCreate, child: Text(actionText!)),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Обновить'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        items.when(
          loading: () => const _LoadingState(),
          error: (error, _) => _ErrorState(error: error, onRetry: onRefresh),
          data: (loadedItems) {
            if (loadedItems.isEmpty) {
              return _EmptyState(message: emptyText);
            }

            return Column(
              children: loadedItems.map(itemBuilder).toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

enum _AdminCardAction { view, edit, delete }

class _AdminItemCard extends StatelessWidget {
  const _AdminItemCard({
    required this.title,
    required this.subtitle,
    required this.status,
    this.onView,
    this.onEdit,
    this.onDelete,
  });

  final String title;
  final String subtitle;
  final String status;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  void _handleAction(_AdminCardAction action) {
    switch (action) {
      case _AdminCardAction.view:
        onView?.call();
        break;
      case _AdminCardAction.edit:
        onEdit?.call();
        break;
      case _AdminCardAction.delete:
        onDelete?.call();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (onView != null || onEdit != null || onDelete != null)
                  PopupMenuButton<_AdminCardAction>(
                    tooltip: 'Действия',
                    onSelected: _handleAction,
                    itemBuilder: (context) => [
                      if (onView != null)
                        const PopupMenuItem(
                          value: _AdminCardAction.view,
                          child: Text('Просмотр'),
                        ),
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: _AdminCardAction.edit,
                          child: Text('Редактировать'),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: _AdminCardAction.delete,
                          child: Text('Удалить'),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Не удалось загрузить данные',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('$error'),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
    );
  }
}

class _CreateSetDialog extends StatefulWidget {
  const _CreateSetDialog();

  @override
  State<_CreateSetDialog> createState() => _CreateSetDialogState();
}

class _CreateSetDialogState extends State<_CreateSetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _themeController = TextEditingController();
  final _cefrController = TextEditingController(text: 'A1');
  final List<_VocabularyWordControllers> _wordRows = [
    _VocabularyWordControllers(),
  ];

  @override
  void dispose() {
    _themeController.dispose();
    _cefrController.dispose();
    for (final row in _wordRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addWordRow() {
    setState(() {
      _wordRows.add(_VocabularyWordControllers());
    });
  }

  void _removeWordRow(int index) {
    if (_wordRows.length == 1) {
      return;
    }

    setState(() {
      _wordRows.removeAt(index).dispose();
    });
  }

  List<AdminVocabularyWordInput> _buildWordInputs() {
    return _wordRows
        .map(
          (row) => AdminVocabularyWordInput(
            russianWord: row.russianController.text.trim(),
            englishTranslation: row.englishController.text.trim(),
            transcription: _textOrNull(row.transcriptionController.text),
            exampleSentence: _textOrNull(row.exampleController.text),
          ),
        )
        .toList(growable: false);
  }

  Widget _buildWordCard(int index, _VocabularyWordControllers controllers) {
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Слово ${index + 1}', style: titleStyle),
                const Spacer(),
                if (_wordRows.length > 1)
                  IconButton(
                    tooltip: 'Удалить слово',
                    onPressed: () => _removeWordRow(index),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers.russianController,
              decoration: const InputDecoration(labelText: 'Русское слово'),
              textInputAction: TextInputAction.next,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers.englishController,
              decoration: const InputDecoration(
                labelText: 'Английский перевод',
              ),
              textInputAction: TextInputAction.next,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers.transcriptionController,
              decoration: const InputDecoration(
                labelText: 'Транскрипция (необязательно)',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers.exampleController,
              decoration: const InputDecoration(
                labelText: 'Пример предложения (необязательно)',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Новый словарный набор'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _themeController,
                decoration: const InputDecoration(labelText: 'Название темы'),
                textInputAction: TextInputAction.next,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cefrController,
                decoration: const InputDecoration(labelText: 'CEFR уровень'),
                textCapitalization: TextCapitalization.characters,
                validator: _cefrLevelValidator,
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Слова набора',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ..._wordRows.asMap().entries.map(
                (entry) => _buildWordCard(entry.key, entry.value),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addWordRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить слово'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            if (_wordRows.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Добавьте хотя бы одно слово.')),
              );
              return;
            }

            Navigator.of(context).pop(
              _CreateSetData(
                themeName: _themeController.text.trim(),
                cefrLevel: _cefrController.text.trim().toUpperCase(),
                words: _buildWordInputs(),
              ),
            );
          },
          child: const Text('Создать'),
        ),
      ],
    );
  }
}

class _UserFormDialog extends StatefulWidget {
  const _UserFormDialog({
    required this.title,
    required this.actionLabel,
    required this.roles,
    required this.groups,
    this.initialItem,
  });

  final String title;
  final String actionLabel;
  final List<AdminRoleListItem> roles;
  final List<AdminStudyGroupListItem> groups;
  final AdminUserListItem? initialItem;

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late int _selectedRoleId;
  int? _selectedGroupId;

  bool get _isEditing => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    final initialItem = widget.initialItem;
    _idController = TextEditingController(text: initialItem?.id ?? '');
    _usernameController = TextEditingController(
      text: initialItem?.username ?? '',
    );
    _emailController = TextEditingController(text: initialItem?.email ?? '');
    final initialRoleId = initialItem?.roleId;
    _selectedRoleId =
        initialRoleId != null &&
            widget.roles.any((role) => role.id == initialRoleId)
        ? initialRoleId
        : widget.roles.first.id;
    final initialGroupId = initialItem?.studyGroupId;
    _selectedGroupId =
        initialGroupId != null &&
            widget.groups.any((group) => group.id == initialGroupId)
        ? initialGroupId
        : null;
  }

  @override
  void dispose() {
    _idController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(widget.title),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isEditing) ...[
                const Text(
                  'UUID должен уже существовать в Supabase Auth. Клиентский ключ не может создавать auth-аккаунты.',
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _idController,
                enabled: !_isEditing,
                decoration: const InputDecoration(labelText: 'Auth user UUID'),
                validator: _uuidValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Имя пользователя',
                ),
                textInputAction: TextInputAction.next,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Эл. почта'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: _emailValidator,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _selectedRoleId,
                decoration: const InputDecoration(labelText: 'Роль'),
                items: widget.roles
                    .map(
                      (role) => DropdownMenuItem<int>(
                        value: role.id,
                        child: Text(role.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _selectedRoleId = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _selectedGroupId ?? 0,
                decoration: const InputDecoration(labelText: 'Учебная группа'),
                items: [
                  const DropdownMenuItem<int>(
                    value: 0,
                    child: Text('Без группы'),
                  ),
                  ...widget.groups.map(
                    (group) => DropdownMenuItem<int>(
                      value: group.id,
                      child: Text(group.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedGroupId = value == 0 ? null : value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }

            Navigator.of(context).pop(
              _UserFormData(
                id: _isEditing ? null : _idController.text.trim(),
                username: _usernameController.text.trim(),
                email: _emailController.text.trim(),
                roleId: _selectedRoleId,
                studyGroupId: _selectedGroupId,
              ),
            );
          },
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}

class _StudyGroupFormDialog extends StatefulWidget {
  const _StudyGroupFormDialog({
    required this.title,
    required this.actionLabel,
    required this.students,
    this.initialName = '',
    this.initialGroupId,
  });

  final String title;
  final String actionLabel;
  final List<AdminStudentListItem> students;
  final String initialName;
  final int? initialGroupId;

  @override
  State<_StudyGroupFormDialog> createState() => _StudyGroupFormDialogState();
}

class _StudyGroupFormDialogState extends State<_StudyGroupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final Set<String> _selectedStudentIds = <String>{};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    final initialGroupId = widget.initialGroupId;
    if (initialGroupId != null) {
      _selectedStudentIds.addAll(
        widget.students
            .where((student) => student.studyGroupId == initialGroupId)
            .map((student) => student.id),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleStudentSelection(String studentId, bool selected) {
    setState(() {
      if (selected) {
        _selectedStudentIds.add(studentId);
      } else {
        _selectedStudentIds.remove(studentId);
      }
    });
  }

  Widget _buildStudentTile(AdminStudentListItem student) {
    final subtitle = student.subtitle;

    return CheckboxListTile(
      value: _selectedStudentIds.contains(student.id),
      onChanged: (value) {
        _toggleStudentSelection(student.id, value ?? false);
      },
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(student.displayName),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
    );
  }

  Widget _buildStudentList() {
    if (widget.students.isEmpty) {
      return const Center(child: Text('Список студентов пока пуст.'));
    }

    return ListView.separated(
      itemCount: widget.students.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) =>
          _buildStudentTile(widget.students[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Название группы'),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),
              Text(
                'Выберите студентов',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Если студент уже состоит в группе, выбор перенесет его в эту группу.',
              ),
              const SizedBox(height: 8),
              SizedBox(height: 280, child: _buildStudentList()),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop(
              _GroupFormData(
                name: _nameController.text.trim(),
                studentIds: _selectedStudentIds.toList(growable: false),
              ),
            );
          },
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}

class _TaskFormDialog extends StatefulWidget {
  const _TaskFormDialog({
    required this.title,
    required this.actionLabel,
    required this.sets,
    this.initialItem,
  });

  final String title;
  final String actionLabel;
  final List<AdminVocabularySetListItem> sets;
  final AdminTaskListItem? initialItem;

  @override
  State<_TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<_TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _deadlineController;
  late final TextEditingController _startDateController;
  late final TextEditingController _attemptsController;
  late int _selectedSetId;
  late bool _translateToRussian;
  late bool _availableAfterEnd;

  @override
  void initState() {
    super.initState();
    final initialItem = widget.initialItem;
    final initialSetId = initialItem?.vocabularySetId;
    _selectedSetId =
        initialSetId != null && widget.sets.any((set) => set.id == initialSetId)
        ? initialSetId
        : widget.sets.first.id;
    _deadlineController = TextEditingController(
      text: _formatDateForInput(initialItem?.deadline),
    );
    _startDateController = TextEditingController(
      text: _formatDateForInput(initialItem?.startDate),
    );
    _attemptsController = TextEditingController(
      text: (initialItem?.attemptsCount ?? 1).toString(),
    );
    _translateToRussian = initialItem?.translateToRussian ?? true;
    _availableAfterEnd = initialItem?.availableAfterEnd ?? false;
  }

  @override
  void dispose() {
    _deadlineController.dispose();
    _startDateController.dispose();
    _attemptsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _selectedSetId,
                decoration: const InputDecoration(labelText: 'Словарный набор'),
                items: widget.sets
                    .map(
                      (set) => DropdownMenuItem<int>(
                        value: set.id,
                        child: Text(set.themeName),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedSetId = value;
                  });
                },
              ),
              TextFormField(
                controller: _startDateController,
                decoration: const InputDecoration(
                  labelText: 'Дата начала',
                  hintText: 'ГГГГ-ММ-ДД',
                ),
                validator: _optionalDateValidator,
              ),
              TextFormField(
                controller: _deadlineController,
                decoration: const InputDecoration(
                  labelText: 'Дедлайн',
                  hintText: 'ГГГГ-ММ-ДД',
                ),
                validator: (value) =>
                    _deadlineValidator(value, _startDateController.text),
              ),
              TextFormField(
                controller: _attemptsController,
                decoration: const InputDecoration(
                  labelText: 'Количество попыток',
                ),
                keyboardType: TextInputType.number,
                validator: _attemptsValidator,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Перевод на русский'),
                value: _translateToRussian,
                onChanged: (value) {
                  setState(() {
                    _translateToRussian = value;
                  });
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Доступно после дедлайна'),
                value: _availableAfterEnd,
                onChanged: (value) {
                  setState(() {
                    _availableAfterEnd = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop(
              _TaskFormData(
                vocabularySetId: _selectedSetId,
                deadline: _parseDate(_deadlineController.text),
                startDate: _parseDate(_startDateController.text),
                translateToRussian: _translateToRussian,
                availableAfterEnd: _availableAfterEnd,
                attemptsCount: int.parse(_attemptsController.text.trim()),
              ),
            );
          },
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}

class _VocabularyWordControllers {
  _VocabularyWordControllers({
    String russianWord = '',
    String englishTranslation = '',
    String transcription = '',
    String exampleSentence = '',
  }) : russianController = TextEditingController(text: russianWord),
       englishController = TextEditingController(text: englishTranslation),
       transcriptionController = TextEditingController(text: transcription),
       exampleController = TextEditingController(text: exampleSentence);

  final TextEditingController russianController;
  final TextEditingController englishController;
  final TextEditingController transcriptionController;
  final TextEditingController exampleController;

  void dispose() {
    russianController.dispose();
    englishController.dispose();
    transcriptionController.dispose();
    exampleController.dispose();
  }
}

class _CreateSetData {
  const _CreateSetData({
    required this.themeName,
    required this.cefrLevel,
    required this.words,
  });

  final String themeName;
  final String cefrLevel;
  final List<AdminVocabularyWordInput> words;
}

class _UserFormRefs {
  const _UserFormRefs({required this.roles, required this.groups});

  final List<AdminRoleListItem> roles;
  final List<AdminStudyGroupListItem> groups;
}

class _UserFormData {
  const _UserFormData({
    required this.id,
    required this.username,
    required this.email,
    required this.roleId,
    required this.studyGroupId,
  });

  final String? id;
  final String username;
  final String email;
  final int roleId;
  final int? studyGroupId;
}

class _SetMetadataFormData {
  const _SetMetadataFormData({
    required this.themeName,
    required this.cefrLevel,
  });

  final String themeName;
  final String cefrLevel;
}

class _GroupFormData {
  const _GroupFormData({required this.name, required this.studentIds});

  final String name;
  final List<String> studentIds;
}

class _TaskFormData {
  const _TaskFormData({
    required this.vocabularySetId,
    required this.deadline,
    required this.startDate,
    required this.translateToRussian,
    required this.availableAfterEnd,
    required this.attemptsCount,
  });

  final int vocabularySetId;
  final DateTime? deadline;
  final DateTime? startDate;
  final bool translateToRussian;
  final bool availableAfterEnd;
  final int attemptsCount;
}

String? _requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Заполните поле';
  }
  return null;
}

String? _emailValidator(String? value) {
  final requiredError = _requiredValidator(value);
  if (requiredError != null) {
    return requiredError;
  }

  final email = value!.trim();
  if (!email.contains('@')) {
    return 'Введите корректный адрес.';
  }
  return null;
}

String? _uuidValidator(String? value) {
  final requiredError = _requiredValidator(value);
  if (requiredError != null) {
    return requiredError;
  }

  final uuid = value!.trim();
  final isUuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(uuid);
  if (!isUuid) {
    return 'Введите UUID в формате xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
  }
  return null;
}

String? _cefrLevelValidator(String? value) {
  final requiredError = _requiredValidator(value);
  if (requiredError != null) {
    return requiredError;
  }

  final level = value!.trim().toUpperCase();
  const allowedLevels = {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'};
  if (!allowedLevels.contains(level)) {
    return 'Введите уровень A1, A2, B1, B2, C1 или C2';
  }
  return null;
}

String? _optionalDateValidator(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return null;
  }
  if (_parseDate(text) == null) {
    return 'Введите дату в формате ГГГГ-ММ-ДД';
  }
  return null;
}

String? _deadlineValidator(String? value, String startDateValue) {
  final dateError = _optionalDateValidator(value);
  if (dateError != null) {
    return dateError;
  }

  final startDate = _parseDate(startDateValue);
  final deadline = _parseDate(value ?? '');
  if (startDate != null && deadline != null && deadline.isBefore(startDate)) {
    return 'Дедлайн не может быть раньше даты начала';
  }
  return null;
}

String? _attemptsValidator(String? value) {
  final attempts = int.tryParse(value?.trim() ?? '');
  if (attempts == null || attempts < 1) {
    return 'Введите число больше 0';
  }
  return null;
}

DateTime? _parseDate(String value) {
  final text = value.trim();
  if (text.isEmpty) {
    return null;
  }

  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
  if (match == null) {
    return null;
  }

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final parsed = DateTime.tryParse(text);
  if (parsed == null ||
      parsed.year != year ||
      parsed.month != month ||
      parsed.day != day) {
    return null;
  }
  return parsed;
}

String _formatNullableDate(DateTime? date) {
  if (date == null) {
    return 'Не задано';
  }
  return _formatDate(date);
}

String _formatDateForInput(DateTime? date) {
  if (date == null) {
    return '';
  }
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _taskSubtitle(AdminTaskListItem item) {
  final direction = item.translateToRussian ? 'на русский' : 'на английский';
  final startDate = item.startDate == null
      ? 'без даты начала'
      : 'старт: ${_formatDate(item.startDate!)}';
  final deadline = item.deadline == null
      ? 'без дедлайна'
      : 'дедлайн: ${_formatDate(item.deadline!)}';

  return '$startDate · $deadline · попыток: ${item.attemptsCount} · перевод $direction';
}

String _taskStatus(AdminTaskListItem item) {
  final now = DateTime.now();
  if (item.deadline != null && item.deadline!.isBefore(now)) {
    return item.availableAfterEnd
        ? 'Доступно после дедлайна'
        : 'Дедлайн прошёл';
  }
  if (item.startDate != null && item.startDate!.isAfter(now)) {
    return 'Запланировано';
  }
  return 'Активно';
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

String _formatPercent(double value) {
  final fixed = value.toStringAsFixed(1).replaceAll('.', ',');
  return '$fixed %';
}

String? _textOrNull(String value) {
  final text = value.trim();
  if (text.isEmpty) {
    return null;
  }
  return text;
}
