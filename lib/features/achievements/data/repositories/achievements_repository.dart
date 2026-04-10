import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final achievementsRepositoryProvider = Provider<AchievementsRepositoryBase>((
  ref,
) {
  return SupabaseAchievementsRepository(Supabase.instance.client);
});

final achievementsProvider = StreamProvider.autoDispose<List<AchievementItem>>((
  ref,
) {
  return ref.watch(achievementsRepositoryProvider).watchAchievements();
});

abstract class AchievementsRepositoryBase {
  Stream<List<AchievementItem>> watchAchievements();
}

class SupabaseAchievementsRepository implements AchievementsRepositoryBase {
  const SupabaseAchievementsRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<List<AchievementItem>> watchAchievements() async* {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User is not authenticated.');
    }

    final completedStatusId = await _fetchCompletedStatusId();

    yield* _client
        .from('task_executions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map(
          (rows) =>
              _buildAchievements(rows, completedStatusId: completedStatusId),
        );
  }

  Future<int> _fetchCompletedStatusId() async {
    final row = await _client
        .from('statuses')
        .select('id')
        .eq('name', 'completed')
        .single();

    final json = Map<String, dynamic>.from(row);
    return json['id'] as int;
  }

  List<AchievementItem> _buildAchievements(
    List<Map<String, dynamic>> rows, {
    required int completedStatusId,
  }) {
    final completedExecutions =
        rows
            .map(_TaskExecutionSnapshot.fromJson)
            .where((execution) => execution.statusId == completedStatusId)
            .toList()
          ..sort((a, b) {
            final aDate = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final dateComparison = aDate.compareTo(bDate);
            if (dateComparison != 0) {
              return dateComparison;
            }
            return a.id.compareTo(b.id);
          });

    final completedCount = completedExecutions.length;

    return _achievementDefinitions
        .map((definition) {
          final isUnlocked = completedCount >= definition.requiredCompleted;
          final earnedAt =
              isUnlocked &&
                  completedExecutions.length >= definition.requiredCompleted
              ? completedExecutions[definition.requiredCompleted - 1].updatedAt
              : null;

          return AchievementItem(
            id: definition.id,
            title: definition.title,
            description: definition.description,
            progress: (completedCount / definition.requiredCompleted)
                .clamp(0.0, 1.0)
                .toDouble(),
            isUnlocked: isUnlocked,
            earnedAt: earnedAt,
          );
        })
        .toList(growable: false);
  }
}

class AchievementItem {
  const AchievementItem({
    required this.id,
    required this.title,
    required this.description,
    required this.progress,
    required this.isUnlocked,
    required this.earnedAt,
  });

  final int id;
  final String title;
  final String description;
  final double progress;
  final bool isUnlocked;
  final DateTime? earnedAt;
}

class _TaskExecutionSnapshot {
  const _TaskExecutionSnapshot({
    required this.id,
    required this.statusId,
    required this.updatedAt,
  });

  final int id;
  final int statusId;
  final DateTime? updatedAt;

  factory _TaskExecutionSnapshot.fromJson(Map<String, dynamic> json) {
    return _TaskExecutionSnapshot(
      id: json['id'] as int,
      statusId: json['status_id'] as int,
      updatedAt: _parseNullableDate(json['updated_at']),
    );
  }
}

class _AchievementDefinition {
  const _AchievementDefinition({
    required this.id,
    required this.requiredCompleted,
    required this.title,
    required this.description,
  });

  final int id;
  final int requiredCompleted;
  final String title;
  final String description;
}

const _achievementDefinitions = <_AchievementDefinition>[
  _AchievementDefinition(
    id: 1,
    requiredCompleted: 1,
    title:
        '\u041f\u0435\u0440\u0432\u043e\u0435 \u0434\u043e\u0441\u0442\u0438\u0436\u0435\u043d\u0438\u0435',
    description:
        '\u0417\u0430\u0432\u0435\u0440\u0448\u0438\u0442\u0435 1 \u0437\u0430\u0434\u0430\u043d\u0438\u0435.',
  ),
  _AchievementDefinition(
    id: 2,
    requiredCompleted: 3,
    title:
        '\u0412 \u0440\u0430\u0431\u043e\u0447\u0435\u043c \u0440\u0438\u0442\u043c\u0435',
    description:
        '\u0417\u0430\u0432\u0435\u0440\u0448\u0438\u0442\u0435 3 \u0437\u0430\u0434\u0430\u043d\u0438\u044f.',
  ),
  _AchievementDefinition(
    id: 3,
    requiredCompleted: 5,
    title:
        '\u041f\u044f\u0442\u0435\u0440\u043a\u0430 \u0437\u0430\u0434\u0430\u0447',
    description:
        '\u0417\u0430\u0432\u0435\u0440\u0448\u0438\u0442\u0435 5 \u0437\u0430\u0434\u0430\u043d\u0438\u0439.',
  ),
  _AchievementDefinition(
    id: 4,
    requiredCompleted: 10,
    title:
        '\u0414\u0435\u0441\u044f\u0442\u044c \u0432\u044b\u043f\u043e\u043b\u043d\u0435\u043d\u0438\u0439',
    description:
        '\u0417\u0430\u0432\u0435\u0440\u0448\u0438\u0442\u0435 10 \u0437\u0430\u0434\u0430\u043d\u0438\u0439.',
  ),
  _AchievementDefinition(
    id: 5,
    requiredCompleted: 20,
    title:
        '\u041f\u043e\u0441\u0442\u043e\u044f\u043d\u043d\u044b\u0439 \u043f\u0440\u043e\u0433\u0440\u0435\u0441\u0441',
    description:
        '\u0417\u0430\u0432\u0435\u0440\u0448\u0438\u0442\u0435 20 \u0437\u0430\u0434\u0430\u043d\u0438\u0439.',
  ),
];

DateTime? _parseNullableDate(Object? value) {
  if (value == null) {
    return null;
  }

  return DateTime.parse(value as String);
}
