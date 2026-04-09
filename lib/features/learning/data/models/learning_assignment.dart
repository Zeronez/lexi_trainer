class LearningAssignment {
  const LearningAssignment({
    required this.id,
    required this.deadline,
    required this.startDate,
    required this.translateToRussian,
    required this.availableAfterEnd,
    required this.attemptsCount,
    required this.vocabularySetId,
    required this.vocabularySetName,
    required this.latestExecution,
  });

  final int id;
  final DateTime? deadline;
  final DateTime? startDate;
  final bool translateToRussian;
  final bool availableAfterEnd;
  final int attemptsCount;
  final int vocabularySetId;
  final String vocabularySetName;
  final LearningTaskExecutionSummary? latestExecution;

  factory LearningAssignment.fromJson(
    Map<String, dynamic> json, {
    required LearningTaskExecutionSummary? latestExecution,
  }) {
    final vocabularySet = json['vocabulary_sets'];

    return LearningAssignment(
      id: json['id'] as int,
      deadline: _parseNullableDate(json['deadline']),
      startDate: _parseNullableDate(json['start_date']),
      translateToRussian: json['translate_to_russian'] as bool,
      availableAfterEnd: json['available_after_end'] as bool,
      attemptsCount: json['attempts_count'] as int,
      vocabularySetId: json['vocabulary_set_id'] as int,
      vocabularySetName: vocabularySet is Map<String, dynamic>
          ? vocabularySet['theme_name'] as String? ?? 'Без названия'
          : 'Без названия',
      latestExecution: latestExecution,
    );
  }
}

class LearningTaskExecutionSummary {
  const LearningTaskExecutionSummary({
    required this.id,
    required this.statusName,
    required this.updatedAt,
  });

  final int id;
  final String statusName;
  final DateTime? updatedAt;

  factory LearningTaskExecutionSummary.fromJson(Map<String, dynamic> json) {
    final status = json['statuses'];

    return LearningTaskExecutionSummary(
      id: json['id'] as int,
      statusName: status is Map<String, dynamic>
          ? status['name'] as String? ?? 'assigned'
          : 'assigned',
      updatedAt: _parseNullableDate(json['updated_at']),
    );
  }
}

DateTime? _parseNullableDate(Object? value) {
  if (value == null) {
    return null;
  }

  return DateTime.parse(value as String).toLocal();
}
