import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexi_trainer/features/admin/data/models/admin_list_items.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(Supabase.instance.client);
});

final adminVocabularySetsProvider =
    FutureProvider<List<AdminVocabularySetListItem>>((ref) {
      return ref.watch(adminRepositoryProvider).fetchVocabularySets();
    });

final adminStudyGroupsProvider = FutureProvider<List<AdminStudyGroupListItem>>((
  ref,
) {
  return ref.watch(adminRepositoryProvider).fetchStudyGroups();
});

final adminTasksProvider = FutureProvider<List<AdminTaskListItem>>((ref) {
  return ref.watch(adminRepositoryProvider).fetchTasks();
});

class AdminRepository {
  const AdminRepository(this._client);

  final SupabaseClient _client;

  Future<List<AdminVocabularySetListItem>> fetchVocabularySets() async {
    final rows = await _client
        .from('vocabulary_sets')
        .select('id, theme_name, cefr_level, created_at, user_id')
        .order('created_at', ascending: false);

    return rows
        .map(
          (row) => AdminVocabularySetListItem.fromJson(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  Future<List<AdminStudyGroupListItem>> fetchStudyGroups() async {
    final rows = await _client
        .from('study_groups')
        .select('id, name, created_at')
        .order('created_at', ascending: false);

    return rows
        .map(
          (row) =>
              AdminStudyGroupListItem.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<List<AdminTaskListItem>> fetchTasks() async {
    final rows = await _client
        .from('tasks')
        .select(
          'id, deadline, start_date, translate_to_russian, available_after_end, attempts_count, vocabulary_set_id, vocabulary_sets(theme_name)',
        )
        .order('id', ascending: false);

    return rows
        .map(
          (row) => AdminTaskListItem.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<void> createVocabularySet({
    required String themeName,
    required String cefrLevel,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Пользователь не авторизован.');
    }

    await _client.from('vocabulary_sets').insert({
      'theme_name': themeName,
      'cefr_level': cefrLevel,
      'user_id': userId,
    });
  }

  Future<void> createStudyGroup({required String name}) async {
    await _client.from('study_groups').insert({'name': name});
  }

  Future<void> createTask({
    required int vocabularySetId,
    required DateTime? deadline,
    required DateTime? startDate,
    required bool translateToRussian,
    required bool availableAfterEnd,
    required int attemptsCount,
  }) async {
    await _client.from('tasks').insert({
      'vocabulary_set_id': vocabularySetId,
      'deadline': deadline?.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'translate_to_russian': translateToRussian,
      'available_after_end': availableAfterEnd,
      'attempts_count': attemptsCount,
    });
  }
}
