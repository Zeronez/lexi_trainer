import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexi_trainer/core/theme/app_colors.dart';
import 'package:lexi_trainer/features/learning/data/models/learning_assignment.dart';
import 'package:lexi_trainer/features/learning/data/repositories/learning_repository.dart';

class MonthlyAssignmentsCard extends ConsumerWidget {
  const MonthlyAssignmentsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignments = ref.watch(learningAssignmentsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: assignments.when(
          data: (items) {
            final stats = _MonthlyAssignmentsStats.fromAssignments(items);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calendar_month_outlined,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Задания за месяц',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Показываем текущие задания, выполненные попытки и просрочки.',
                            style: textTheme.bodyMedium?.copyWith(height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${stats.completedThisMonth}',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'из ${stats.totalRelevant}',
                        style: textTheme.titleMedium,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      stats.progressLabel,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 12,
                    value: stats.progress,
                  ),
                ),
                if (stats.totalRelevant == 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Пока нет заданий для показа в этом месяце.',
                    style: textTheme.bodyMedium?.copyWith(height: 1.35),
                  ),
                ],
                const SizedBox(height: 18),
                _MetricRow(
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                  value: stats.completedThisMonth.toString(),
                  label: 'Выполнено за текущий месяц',
                ),
                const SizedBox(height: 12),
                _MetricRow(
                  icon: Icons.play_circle_outline,
                  color: AppColors.accent,
                  value: stats.activeNow.toString(),
                  label: 'Активны сейчас',
                ),
                const SizedBox(height: 12),
                _MetricRow(
                  icon: Icons.event_busy_outlined,
                  color: Colors.deepOrange,
                  value: stats.overdue.toString(),
                  label: 'Просрочены',
                ),
              ],
            );
          },
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Задания за месяц',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Собираем статистику...'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const LinearProgressIndicator(),
            ],
          ),
          error: (error, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Задания за месяц',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Не удалось загрузить статистику: $error',
                          style: textTheme.bodyMedium?.copyWith(height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(learningAssignmentsProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthlyAssignmentsStats {
  const _MonthlyAssignmentsStats({
    required this.completedThisMonth,
    required this.activeNow,
    required this.overdue,
    required this.totalRelevant,
  });

  final int completedThisMonth;
  final int activeNow;
  final int overdue;
  final int totalRelevant;

  double get progress => totalRelevant == 0
      ? 0
      : (completedThisMonth / totalRelevant).clamp(0.0, 1.0).toDouble();

  String get progressLabel {
    final percent = (progress * 100).round();
    return '$percent%';
  }

  factory _MonthlyAssignmentsStats.fromAssignments(
    List<LearningAssignment> assignments,
  ) {
    final now = DateTime.now();

    var completedThisMonth = 0;
    var activeNow = 0;
    var overdue = 0;
    var totalRelevant = 0;

    for (final assignment in assignments) {
      final completed = assignment.latestExecution?.statusName == 'completed';
      final completedInMonth =
          completed &&
          _isInCurrentMonth(assignment.latestExecution?.updatedAt, now);
      final isActiveNow = !completed && _isActiveNow(assignment, now);
      final isOverdue = !completed && _isOverdue(assignment, now);

      if (completedInMonth) {
        completedThisMonth++;
      }

      if (isActiveNow) {
        activeNow++;
      }

      if (isOverdue) {
        overdue++;
      }

      if (completedInMonth || isActiveNow || isOverdue) {
        totalRelevant++;
      }
    }

    return _MonthlyAssignmentsStats(
      completedThisMonth: completedThisMonth,
      activeNow: activeNow,
      overdue: overdue,
      totalRelevant: totalRelevant,
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(label, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

bool _isInCurrentMonth(DateTime? value, DateTime now) {
  if (value == null) {
    return false;
  }

  final monthStart = DateTime(now.year, now.month);
  final nextMonthStart = DateTime(now.year, now.month + 1);
  return !value.isBefore(monthStart) && value.isBefore(nextMonthStart);
}

bool _isActiveNow(LearningAssignment assignment, DateTime now) {
  final started =
      assignment.startDate == null || !assignment.startDate!.isAfter(now);
  final withinDeadline =
      assignment.deadline == null ||
      !assignment.deadline!.isBefore(now) ||
      assignment.availableAfterEnd;

  return started && withinDeadline;
}

bool _isOverdue(LearningAssignment assignment, DateTime now) {
  final deadline = assignment.deadline;
  if (deadline == null) {
    return false;
  }

  return deadline.isBefore(now) && !assignment.availableAfterEnd;
}
