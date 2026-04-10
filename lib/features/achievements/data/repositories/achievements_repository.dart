import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final achievementsRepositoryProvider = Provider<AchievementsRepositoryBase>((
  ref,
) {
  return SupabaseAchievementsRepository(Supabase.instance.client);
});

final achievementsProvider = FutureProvider<List<AchievementItem>>((ref) {
  return ref.watch(achievementsRepositoryProvider).fetchAchievements();
});

abstract class AchievementsRepositoryBase {
  Future<List<AchievementItem>> fetchAchievements();
}

class SupabaseAchievementsRepository implements AchievementsRepositoryBase {
  const SupabaseAchievementsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AchievementItem>> fetchAchievements() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User is not authenticated.');
    }

    // Keep achievements in sync with latest progress before reading.
    try {
      await _client.rpc('recalculate_user_achievements');
    } catch (_) {
      // Non-blocking: still render existing DB state.
    }

    final unlockedRows = await _client
        .from('user_achievements_link')
        .select('achievement_id, received_at')
        .eq('user_id', userId);

    final unlockedByAchievementId = <int, DateTime?>{};
    for (final row in unlockedRows) {
      final json = Map<String, dynamic>.from(row);
      final achievementId = json['achievement_id'] as int;
      final receivedAt = AchievementItem._parseNullableDate(
        json['received_at'],
      );
      unlockedByAchievementId[achievementId] = receivedAt;
    }

    final rows = await _client
        .from('achievements')
        .select('id, name, description')
        .order('id', ascending: true);

    return rows
        .map(
          (row) => AchievementItem.fromJson(
            Map<String, dynamic>.from(row),
            unlockedByAchievementId: unlockedByAchievementId,
          ),
        )
        .toList();
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

  factory AchievementItem.fromJson(
    Map<String, dynamic> json, {
    required Map<int, DateTime?> unlockedByAchievementId,
  }) {
    final id = json['id'] as int;
    final unlockedAt = unlockedByAchievementId[id];

    return AchievementItem(
      id: id,
      title: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      progress: unlockedAt != null ? 1 : 0,
      isUnlocked: unlockedAt != null,
      earnedAt: unlockedAt,
    );
  }

  static DateTime? _parseNullableDate(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.parse(value as String);
  }
}
