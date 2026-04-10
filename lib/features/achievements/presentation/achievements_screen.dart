import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexi_trainer/core/theme/app_colors.dart';
import 'package:lexi_trainer/features/achievements/data/repositories/achievements_repository.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '\u0414\u043e\u0441\u0442\u0438\u0436\u0435\u043d\u0438\u044f',
        ),
      ),
      body: SafeArea(
        child: achievements.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Text(
                  '\u041f\u043e\u043a\u0430 \u043d\u0435\u0442 \u0434\u043e\u0441\u0442\u0438\u0436\u0435\u043d\u0438\u0439',
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              item.isUnlocked
                                  ? Icons.workspace_premium
                                  : Icons.emoji_events_outlined,
                              color: item.isUnlocked
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
                        Text(
                          '\u041f\u0440\u043e\u0433\u0440\u0435\u0441\u0441: ${(item.progress * 100).round()}%',
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0437\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u044c \u0434\u043e\u0441\u0442\u0438\u0436\u0435\u043d\u0438\u044f: $error',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
