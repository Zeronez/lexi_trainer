import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexi_trainer/core/auth/current_user_role_provider.dart';
import 'package:lexi_trainer/core/auth/sign_out_button.dart';
import 'package:lexi_trainer/core/auth/user_role.dart';
import 'package:lexi_trainer/core/theme/app_colors.dart';
import 'package:lexi_trainer/features/admin/data/models/admin_list_items.dart';
import 'package:lexi_trainer/features/admin/data/models/admin_vocabulary_word_input.dart';
import 'package:lexi_trainer/features/admin/data/repositories/admin_repository.dart';

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
    final data = await showDialog<_CreateGroupData>(
      context: context,
      builder: (context) => const _CreateGroupDialog(),
    );
    if (data == null) {
      return;
    }

    try {
      await _repository.createStudyGroup(name: data.name);
      if (!mounted) {
        return;
      }
      _refreshGroups();
      _showMessage('Группа создана.');
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

    final data = await showDialog<_CreateTaskData>(
      context: context,
      builder: (context) => _CreateTaskDialog(sets: sets),
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
        final groups = ref.watch(adminStudyGroupsProvider);
        final tasks = ref.watch(adminTasksProvider);

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Панель администратора'),
              actions: const [SignOutButton()],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Контент'),
                  Tab(text: 'Группы'),
                  Tab(text: 'Задания'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _ContentManagementTab(
                  items: sets,
                  onRefresh: _refreshSets,
                  onCreate: _createSet,
                ),
                _GroupManagementTab(
                  items: groups,
                  onRefresh: _refreshGroups,
                  onCreate: _createGroup,
                ),
                _TaskManagementTab(
                  items: tasks,
                  onRefresh: _refreshTasks,
                  onCreate: _createTask,
                ),
              ],
            ),
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
  });

  final AsyncValue<List<AdminVocabularySetListItem>> items;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;

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
            'CEFR ${item.cefrLevel} · создано: ${_formatDate(item.createdAt)}',
        status: 'Доступно',
      ),
    );
  }
}

class _GroupManagementTab extends StatelessWidget {
  const _GroupManagementTab({
    required this.items,
    required this.onRefresh,
    required this.onCreate,
  });

  final AsyncValue<List<AdminStudyGroupListItem>> items;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return _TabLayout<AdminStudyGroupListItem>(
      title: 'Управление учебными группами',
      description:
          'Создавайте учебные группы для дальнейшего назначения студентов и преподавателей.',
      actionText: 'Создать группу',
      emptyText: 'Учебных групп пока нет.',
      items: items,
      onRefresh: onRefresh,
      onCreate: onCreate,
      itemBuilder: (item) => _AdminItemCard(
        title: 'Группа ${item.name}',
        subtitle: 'Создана: ${_formatDate(item.createdAt)}',
        status: 'Активна',
      ),
    );
  }
}

class _TaskManagementTab extends StatelessWidget {
  const _TaskManagementTab({
    required this.items,
    required this.onRefresh,
    required this.onCreate,
  });

  final AsyncValue<List<AdminTaskListItem>> items;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;

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
      ),
    );
  }
}

class _TabLayout<T> extends StatelessWidget {
  const _TabLayout({
    required this.title,
    required this.description,
    required this.actionText,
    required this.emptyText,
    required this.items,
    required this.onRefresh,
    required this.onCreate,
    required this.itemBuilder,
  });

  final String title;
  final String description;
  final String actionText;
  final String emptyText;
  final AsyncValue<List<T>> items;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;
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
            ElevatedButton(onPressed: onCreate, child: Text(actionText)),
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

class _AdminItemCard extends StatelessWidget {
  const _AdminItemCard({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final String title;
  final String subtitle;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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

class _CreateGroupDialog extends StatefulWidget {
  const _CreateGroupDialog();

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Новая учебная группа'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Название группы'),
          validator: _requiredValidator,
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
            Navigator.of(
              context,
            ).pop(_CreateGroupData(name: _nameController.text.trim()));
          },
          child: const Text('Создать'),
        ),
      ],
    );
  }
}

class _CreateTaskDialog extends StatefulWidget {
  const _CreateTaskDialog({required this.sets});

  final List<AdminVocabularySetListItem> sets;

  @override
  State<_CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<_CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _deadlineController = TextEditingController();
  final _startDateController = TextEditingController();
  final _attemptsController = TextEditingController(text: '1');
  late int _selectedSetId = widget.sets.first.id;
  bool _translateToRussian = true;
  bool _availableAfterEnd = false;

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
      title: const Text('Новое задание'),
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
              _CreateTaskData(
                vocabularySetId: _selectedSetId,
                deadline: _parseDate(_deadlineController.text),
                startDate: _parseDate(_startDateController.text),
                translateToRussian: _translateToRussian,
                availableAfterEnd: _availableAfterEnd,
                attemptsCount: int.parse(_attemptsController.text.trim()),
              ),
            );
          },
          child: const Text('Создать'),
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

class _CreateGroupData {
  const _CreateGroupData({required this.name});

  final String name;
}

class _CreateTaskData {
  const _CreateTaskData({
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

String? _textOrNull(String value) {
  final text = value.trim();
  if (text.isEmpty) {
    return null;
  }
  return text;
}
