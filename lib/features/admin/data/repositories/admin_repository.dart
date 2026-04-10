import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexi_trainer/features/admin/data/models/admin_list_items.dart';
import 'package:lexi_trainer/features/admin/data/models/admin_vocabulary_word_input.dart';
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

  Future<void> createVocabularySetWithWords({
    required String themeName,
    required String cefrLevel,
    required List<AdminVocabularyWordInput> words,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Пользователь не авторизован.');
    }
    if (words.isEmpty) {
      throw StateError('Добавьте хотя бы одно слово.');
    }

    int? vocabularySetId;
    final createdWordIds = <int>[];

    try {
      vocabularySetId = await _insertVocabularySet(
        themeName: themeName,
        cefrLevel: cefrLevel,
        userId: userId,
      );

      for (final word in words) {
        final wordId = await _insertVocabularyWord(word);
        createdWordIds.add(wordId);
      }

      await _linkWordsToVocabularySet(
        vocabularySetId: vocabularySetId,
        wordIds: createdWordIds,
      );
    } catch (_) {
      await _cleanupVocabularySetDraft(
        vocabularySetId: vocabularySetId,
        wordIds: createdWordIds,
      );
      rethrow;
    }
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

  Future<int> _insertVocabularySet({
    required String themeName,
    required String cefrLevel,
    required String userId,
  }) async {
    final insertedRow = await _client
        .from('vocabulary_sets')
        .insert({
          'theme_name': themeName,
          'cefr_level': cefrLevel,
          'user_id': userId,
        })
        .select('id')
        .single();

    return _readInsertedId(insertedRow['id'], 'словарного набора');
  }

  Future<int> _insertVocabularyWord(AdminVocabularyWordInput word) async {
    final insertedRow = await _client
        .from('words')
        .insert(word.toInsertPayload())
        .select('id')
        .single();

    return _readInsertedId(insertedRow['id'], 'слова');
  }

  Future<void> _linkWordsToVocabularySet({
    required int vocabularySetId,
    required List<int> wordIds,
  }) async {
    if (wordIds.isEmpty) {
      return;
    }

    await _client
        .from('set_words_link')
        .insert(
          wordIds
              .map(
                (wordId) => {
                  'vocabulary_set_id': vocabularySetId,
                  'word_id': wordId,
                },
              )
              .toList(growable: false),
        );
  }

  Future<void> _cleanupVocabularySetDraft({
    required int? vocabularySetId,
    required List<int> wordIds,
  }) async {
    try {
      if (vocabularySetId != null) {
        await _client
            .from('vocabulary_sets')
            .delete()
            .eq('id', vocabularySetId);
      }
    } catch (_) {
      // Best-effort cleanup.
    }

    try {
      if (wordIds.isNotEmpty) {
        await _client.from('words').delete().inFilter('id', wordIds);
      }
    } catch (_) {
      // Best-effort cleanup.
    }
  }
}

int _readInsertedId(Object? value, String entityName) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.parse(value);
  }

  throw FormatException('Не удалось прочитать id для $entityName.');
}
