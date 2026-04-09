import 'package:flutter/material.dart';
import 'package:lexi_trainer/core/theme/app_colors.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final achievements = const <_AchievementItem>[
      _AchievementItem(
        title: 'Первые 10 слов',
        description: 'Выучите первые 10 слов.',
        progress: 1,
      ),
      _AchievementItem(
        title: 'Серия 7 дней',
        description: 'Занимайтесь без перерывов 7 дней.',
        progress: 0.57,
      ),
      _AchievementItem(
        title: 'Точность 90%',
        description: 'Держите точность 90% на 5 сессиях подряд.',
        progress: 0.4,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Достижения')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: achievements.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = achievements[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          item.progress >= 1
                              ? Icons.workspace_premium
                              : Icons.emoji_events_outlined,
                          color: item.progress >= 1
                              ? AppColors.success
                              : AppColors.accent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(item.description),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: item.progress,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Прогресс: ${(item.progress * 100).round()}%'),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AchievementItem {
  const _AchievementItem({
    required this.title,
    required this.description,
    required this.progress,
  });

  final String title;
  final String description;
  final double progress;
}
