import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexi_trainer/core/auth/current_user_role_provider.dart';
import 'package:lexi_trainer/core/auth/sign_out_button.dart';
import 'package:lexi_trainer/core/auth/user_role.dart';
import 'package:lexi_trainer/core/theme/app_colors.dart';
import 'package:lexi_trainer/features/learning/data/models/learning_assignment.dart';
import 'package:lexi_trainer/features/learning/data/repositories/learning_repository.dart';
import 'package:lexi_trainer/features/vocabulary/presentation/vocabulary_training_screen.dart';

class LearningAssignmentsScreen extends ConsumerStatefulWidget {
  const LearningAssignmentsScreen({super.key});

  @override
  ConsumerState<LearningAssignmentsScreen> createState() =>
      _LearningAssignmentsScreenState();
}

class _LearningAssignmentsScreenState
    extends ConsumerState<LearningAssignmentsScreen> {
  int? _openingTaskId;

  Future<void> _openAssignment(LearningAssignment assignment) async {
    if (_openingTaskId != null) {
      return;
    }

    setState(() => _openingTaskId = assignment.id);
    try {
      final repository = ref.read(learningRepositoryProvider);
      final words = await repository.fetchTrainingWords(
        vocabularySetId: assignment.vocabularySetId,
      );

      if (!mounted) {
        return;
      }

      if (words.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('В этом наборе пока нет слов.')),
        );
        return;
      }

      final taskExecutionId = await repository.startAssignment(
        taskId: assignment.id,
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VocabularyTrainingScreen(
            learningRepository: repository,
            taskId: assignment.id,
            taskExecutionId: taskExecutionId,
            translateToRussian: assignment.translateToRussian,
            words: [
              for (final word in words)
                TrainingWordInput(
                  id: word.id,
                  russian: word.russianWord,
                  english: word.englishTranslation,
                ),
            ],
          ),
        ),
      );

      ref.invalidate(learningAssignmentsProvider);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть задание: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _openingTaskId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(currentUserRoleProvider);

    return roleAsync.when(
      data: (role) {
        if (role.canOpenAdminSection) {
          return const _LearningAccessDeniedScreen();
        }

        return _buildAssignmentsScaffold();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => _RoleLoadErrorScreen(
        error: error,
        onRetry: () => ref.invalidate(currentUserRoleProvider),
      ),
    );
  }

  Widget _buildAssignmentsScaffold() {
    final assignments = ref.watch(learningAssignmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои задания'),
        actions: const [SignOutButton()],
      ),
      body: SafeArea(
        child: assignments.when(
          data: (items) {
            if (items.isEmpty) {
              return _EmptyState(
                onRefresh: () => ref.invalidate(learningAssignmentsProvider),
              );
            }

            return RefreshIndicator(
              onRefresh: () => ref.refresh(learningAssignmentsProvider.future),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final assignment = items[index];
                  return _AssignmentCard(
                    assignment: assignment,
                    isOpening: _openingTaskId == assignment.id,
                    onOpen: () => _openAssignment(assignment),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            error: error,
            onRetry: () => ref.invalidate(learningAssignmentsProvider),
          ),
        ),
      ),
    );
  }
}

class _LearningAccessDeniedScreen extends StatelessWidget {
  const _LearningAccessDeniedScreen();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Доступ к заданиям')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 56,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Этот раздел доступен только студентам',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Учителя и администраторы не проходят задания и не получают достижения. Для управления курсом используйте админ-панель.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Вернуться назад'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleLoadErrorScreen extends StatelessWidget {
  const _RoleLoadErrorScreen({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Мои задания')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: AppColors.accent,
              ),
              const SizedBox(height: 16),
              Text(
                'Не удалось определить доступ к разделу',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('$error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.isOpening,
    required this.onOpen,
  });

  final LearningAssignment assignment;
  final bool isOpening;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final availability = _AssignmentAvailability.fromAssignment(assignment);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.vocabularySetName,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _assignmentSubtitle(assignment),
                        style: textTheme.bodyMedium?.copyWith(height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  label: _statusLabel(assignment.latestExecution?.statusName),
                  icon: Icons.flag_outlined,
                ),
                _InfoChip(
                  label: availability.label,
                  icon: availability.icon,
                  color: availability.color,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: availability.canOpen && !isOpening ? onOpen : null,
                child: isOpening
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(availability.actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.icon,
    this.color = AppColors.success,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_late_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              'Пока нет заданий',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Когда преподаватель назначит набор слов, он появится здесь.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRefresh, child: const Text('Обновить')),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.accent),
            const SizedBox(height: 16),
            Text(
              'Не удалось загрузить задания',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}

class _AssignmentAvailability {
  const _AssignmentAvailability({
    required this.canOpen,
    required this.label,
    required this.actionLabel,
    required this.icon,
    required this.color,
  });

  final bool canOpen;
  final String label;
  final String actionLabel;
  final IconData icon;
  final Color color;

  factory _AssignmentAvailability.fromAssignment(
    LearningAssignment assignment,
  ) {
    final now = DateTime.now();
    final statusName = assignment.latestExecution?.statusName;

    if (statusName == 'completed') {
      return const _AssignmentAvailability(
        canOpen: false,
        label: 'Завершено',
        actionLabel: 'Завершено',
        icon: Icons.check_circle_outline,
        color: AppColors.success,
      );
    }

    if (assignment.startDate != null && assignment.startDate!.isAfter(now)) {
      return _AssignmentAvailability(
        canOpen: false,
        label: 'Откроется ${_formatDateTime(assignment.startDate!)}',
        actionLabel: 'Пока недоступно',
        icon: Icons.schedule_outlined,
        color: AppColors.accent,
      );
    }

    if (assignment.deadline != null &&
        assignment.deadline!.isBefore(now) &&
        !assignment.availableAfterEnd) {
      return const _AssignmentAvailability(
        canOpen: false,
        label: 'Дедлайн прошёл',
        actionLabel: 'Недоступно',
        icon: Icons.event_busy_outlined,
        color: AppColors.accent,
      );
    }

    if (statusName == 'in_progress') {
      return const _AssignmentAvailability(
        canOpen: true,
        label: 'Можно продолжить',
        actionLabel: 'Продолжить',
        icon: Icons.play_circle_outline,
        color: AppColors.success,
      );
    }

    return const _AssignmentAvailability(
      canOpen: true,
      label: 'Доступно',
      actionLabel: 'Начать',
      icon: Icons.play_arrow_outlined,
      color: AppColors.success,
    );
  }
}

String _assignmentSubtitle(LearningAssignment assignment) {
  final direction = assignment.translateToRussian
      ? 'перевод на русский'
      : 'перевод на английский';
  final startDate = assignment.startDate == null
      ? 'без даты начала'
      : 'старт: ${_formatDateTime(assignment.startDate!)}';
  final deadline = assignment.deadline == null
      ? 'без дедлайна'
      : 'дедлайн: ${_formatDateTime(assignment.deadline!)}';
  return '$startDate · $deadline · попыток: ${assignment.attemptsCount} · $direction';
}

String _statusLabel(String? statusName) {
  return switch (statusName) {
    'assigned' => 'Назначено',
    'in_progress' => 'В работе',
    'completed' => 'Завершено',
    'overdue' => 'Просрочено',
    _ => 'Не начато',
  };
}

String _formatDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '$day.$month.${date.year} $hour:$minute';
}
