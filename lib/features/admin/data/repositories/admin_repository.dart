import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexi_trainer/features/admin/data/models/admin_list_items.dart';
import 'package:lexi_trainer/features/admin/data/models/admin_report_metrics.dart';
import 'package:lexi_trainer/features/admin/data/models/admin_vocabulary_word_input.dart';
import 'package:lexi_trainer/features/admin/data/models/admin_user_list_items.dart';
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

final adminStudentsProvider = FutureProvider<List<AdminStudentListItem>>((ref) {
  return ref.watch(adminRepositoryProvider).fetchStudents();
});

final adminTasksProvider = FutureProvider<List<AdminTaskListItem>>((ref) {
  return ref.watch(adminRepositoryProvider).fetchTasks();
});

final adminReportMetricsProvider = FutureProvider<AdminReportMetrics>((ref) {
  return ref.watch(adminRepositoryProvider).fetchReportMetrics();
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

  Future<List<AdminStudentListItem>> fetchStudents() async {
    final studentRoleId = await _fetchRoleId('student');
    final rows = await _client
        .from('users')
        .select('id, username, email, study_group_id, study_groups(name)')
        .eq('role_id', studentRoleId)
        .order('username');

    return rows
        .map(
          (row) =>
              AdminStudentListItem.fromJson(Map<String, dynamic>.from(row)),
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

  Future<AdminVocabularySetDetails> fetchVocabularySetDetails(int id) async {
    final row = await _client
        .from('vocabulary_sets')
        .select(
          'id, theme_name, cefr_level, created_at, user_id, set_words_link(words(id, russian_word, english_translation, transcription, example_sentence))',
        )
        .eq('id', id)
        .single();

    return AdminVocabularySetDetails.fromJson(Map<String, dynamic>.from(row));
  }

  Future<AdminStudyGroupDetails> fetchStudyGroupDetails(int id) async {
    final groupRow = await _client
        .from('study_groups')
        .select('id, name, created_at')
        .eq('id', id)
        .single();
    final memberRows = await _client
        .from('users')
        .select('id, username, email')
        .eq('study_group_id', id)
        .order('username');

    return AdminStudyGroupDetails.fromJson(
      groupJson: Map<String, dynamic>.from(groupRow),
      memberRows: memberRows
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false),
    );
  }

  Future<AdminReportMetrics> fetchReportMetrics() async {
    final completedStatusIdFuture = _fetchStatusId('completed');
    final vocabularySetCountFuture = _client.from('vocabulary_sets').count();
    final taskCountFuture = _client.from('tasks').count();
    final taskExecutionsFuture = _client
        .from('task_executions')
        .select('user_id, status_id');
    final questionAnswersFuture = _client
        .from('question_answers')
        .select('is_correct');

    final completedStatusId = await completedStatusIdFuture;
    final vocabularySetCount = await vocabularySetCountFuture;
    final taskCount = await taskCountFuture;
    final taskExecutionRows = await taskExecutionsFuture;
    final questionAnswerRows = await questionAnswersFuture;

    final activeStudentIds = <String>{};
    var completedTaskCount = 0;
    for (final row in taskExecutionRows) {
      final json = Map<String, dynamic>.from(row);
      final userId = json['user_id'];
      if (userId != null) {
        activeStudentIds.add(userId.toString());
      }

      final statusId = _readInt(json['status_id']);
      if (statusId == completedStatusId) {
        completedTaskCount++;
      }
    }

    var correctAnswerCount = 0;
    for (final row in questionAnswerRows) {
      final json = Map<String, dynamic>.from(row);
      if (json['is_correct'] == true) {
        correctAnswerCount++;
      }
    }

    final totalAnswerCount = questionAnswerRows.length;
    final averageAccuracyPercent = totalAnswerCount == 0
        ? 0.0
        : (correctAnswerCount / totalAnswerCount) * 100.0;

    return AdminReportMetrics(
      vocabularySetCount: vocabularySetCount,
      taskCount: taskCount,
      completedTaskCount: completedTaskCount,
      averageAnswerAccuracyPercent: averageAccuracyPercent,
      activeStudentCount: activeStudentIds.length,
    );
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

  Future<void> createStudyGroup({
    required String name,
    required List<String> studentIds,
  }) async {
    final insertedRow = await _client
        .from('study_groups')
        .insert({'name': name})
        .select('id')
        .single();

    final groupId = _readInsertedId(insertedRow['id'], 'учебной группы');

    if (studentIds.isEmpty) {
      return;
    }

    try {
      await _client
          .from('users')
          .update({'study_group_id': groupId})
          .inFilter('id', studentIds);
    } catch (_) {
      try {
        await _client.from('study_groups').delete().eq('id', groupId);
      } catch (_) {
        // Best-effort cleanup.
      }
      rethrow;
    }
  }

  Future<void> updateVocabularySet({
    required int id,
    required String themeName,
    required String cefrLevel,
  }) async {
    await _client
        .from('vocabulary_sets')
        .update({'theme_name': themeName, 'cefr_level': cefrLevel})
        .eq('id', id);
  }

  Future<void> deleteVocabularySet({required int id}) async {
    await _client.from('vocabulary_sets').delete().eq('id', id);
  }

  Future<void> updateStudyGroup({
    required int id,
    required String name,
    required List<String> studentIds,
  }) async {
    await _client.from('study_groups').update({'name': name}).eq('id', id);

    final currentMemberRows = await _client
        .from('users')
        .select('id')
        .eq('study_group_id', id);
    final selectedStudentIds = studentIds.toSet();
    final removedStudentIds = currentMemberRows
        .map((row) => Map<String, dynamic>.from(row)['id'].toString())
        .where((studentId) => !selectedStudentIds.contains(studentId))
        .toList(growable: false);

    if (removedStudentIds.isNotEmpty) {
      await _client
          .from('users')
          .update({'study_group_id': null})
          .inFilter('id', removedStudentIds);
    }

    if (studentIds.isNotEmpty) {
      await _client
          .from('users')
          .update({'study_group_id': id})
          .inFilter('id', studentIds);
    }
  }

  Future<void> deleteStudyGroup({required int id}) async {
    await _client
        .from('users')
        .update({'study_group_id': null})
        .eq('study_group_id', id);
    await _client.from('study_groups').delete().eq('id', id);
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

  Future<void> updateTask({
    required int id,
    required int vocabularySetId,
    required DateTime? deadline,
    required DateTime? startDate,
    required bool translateToRussian,
    required bool availableAfterEnd,
    required int attemptsCount,
  }) async {
    await _client
        .from('tasks')
        .update({
          'vocabulary_set_id': vocabularySetId,
          'deadline': deadline?.toIso8601String(),
          'start_date': startDate?.toIso8601String(),
          'translate_to_russian': translateToRussian,
          'available_after_end': availableAfterEnd,
          'attempts_count': attemptsCount,
        })
        .eq('id', id);
  }

  Future<void> deleteTask({required int id}) async {
    await _client.from('tasks').delete().eq('id', id);
  }

  Future<int> _fetchRoleId(String name) async {
    final row = await _client
        .from('roles')
        .select('id')
        .eq('name', name)
        .single();

    final json = Map<String, dynamic>.from(row);
    return _readInt(json['id']);
  }

  Future<int> _fetchStatusId(String name) async {
    final row = await _client
        .from('statuses')
        .select('id')
        .eq('name', name)
        .single();

    final json = Map<String, dynamic>.from(row);
    return _readInt(json['id']);
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

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.parse(value);
  }

  throw FormatException('Unable to read integer value.');
}
