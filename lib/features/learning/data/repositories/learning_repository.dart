import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexi_trainer/features/learning/data/models/learning_assignment.dart';
import 'package:lexi_trainer/features/learning/data/models/learning_training_word.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return LearningRepository(Supabase.instance.client);
});

final learningAssignmentsProvider = FutureProvider<List<LearningAssignment>>((
  ref,
) {
  return ref.watch(learningRepositoryProvider).fetchAssignments();
});

class LearningRepository {
  const LearningRepository(this._client);

  final SupabaseClient _client;

  Future<List<LearningAssignment>> fetchAssignments() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Пользователь не авторизован.');
    }

    final taskRows = await _client
        .from('tasks')
        .select(
          'id, deadline, start_date, translate_to_russian, available_after_end, attempts_count, vocabulary_set_id, vocabulary_sets(theme_name)',
        )
        .order('id', ascending: false);

    final executionRows = await _client
        .from('task_executions')
        .select('id, task_id, updated_at, statuses(name)')
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .order('id', ascending: false);

    final latestExecutionByTaskId = <int, LearningTaskExecutionSummary>{};
    for (final row in executionRows) {
      final json = Map<String, dynamic>.from(row);
      final taskId = json['task_id'] as int;
      latestExecutionByTaskId.putIfAbsent(
        taskId,
        () => LearningTaskExecutionSummary.fromJson(json),
      );
    }

    return taskRows.map((row) {
      final json = Map<String, dynamic>.from(row);
      final taskId = json['id'] as int;

      return LearningAssignment.fromJson(
        json,
        latestExecution: latestExecutionByTaskId[taskId],
      );
    }).toList();
  }

  Future<List<LearningTrainingWord>> fetchTrainingWords({
    required int vocabularySetId,
  }) async {
    final rows = await _client
        .from('set_words_link')
        .select('words(id, russian_word, english_translation)')
        .eq('vocabulary_set_id', vocabularySetId);

    return rows
        .map(
          (row) => LearningTrainingWord.fromSetWordLinkJson(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  Future<int> startAssignment({required int taskId}) async {
    final executionId = await _client.rpc(
      'start_task_execution',
      params: {'p_task_id': taskId},
    );

    return _readRpcId(executionId, 'task execution');
  }

  Future<int> submitAttempt({
    required int taskExecutionId,
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    final attemptId = await _client.rpc(
      'submit_attempt',
      params: {
        'p_task_execution_id': taskExecutionId,
        'p_started_at': _toSupabaseTimestamp(startedAt),
        'p_ended_at': _toSupabaseTimestamp(endedAt),
      },
    );

    return _readRpcId(attemptId, 'attempt');
  }

  Future<int> submitQuestionAnswer({
    required int attemptId,
    required int wordId,
    required String enteredAnswer,
    required bool isCorrect,
  }) async {
    final answerId = await _client.rpc(
      'submit_question_answer',
      params: {
        'p_attempt_id': attemptId,
        'p_word_id': wordId,
        'p_entered_answer': enteredAnswer,
        'p_is_correct': isCorrect,
      },
    );

    return _readRpcId(answerId, 'question answer');
  }

  Future<void> updateAttemptEndedAt({
    required int attemptId,
    required DateTime endedAt,
  }) async {
    await _client
        .from('attempts')
        .update({'ended_at': _toSupabaseTimestamp(endedAt)})
        .eq('id', attemptId);
  }

  Future<void> completeTaskExecution({required int taskExecutionId}) async {
    await _client.rpc(
      'complete_task_execution',
      params: {'p_task_execution_id': taskExecutionId},
    );
  }
}

int _readRpcId(Object? value, String entityName) {
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

String _toSupabaseTimestamp(DateTime value) {
  return value.toUtc().toIso8601String();
}
