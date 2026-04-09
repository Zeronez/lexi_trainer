class AdminVocabularySetListItem {
  const AdminVocabularySetListItem({
    required this.id,
    required this.themeName,
    required this.cefrLevel,
    required this.createdAt,
    required this.userId,
  });

  final int id;
  final String themeName;
  final String cefrLevel;
  final DateTime createdAt;
  final String userId;

  factory AdminVocabularySetListItem.fromJson(Map<String, dynamic> json) {
    return AdminVocabularySetListItem(
      id: json['id'] as int,
      themeName: json['theme_name'] as String,
      cefrLevel: json['cefr_level'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String,
    );
  }
}

class AdminStudyGroupListItem {
  const AdminStudyGroupListItem({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final int id;
  final String name;
  final DateTime createdAt;

  factory AdminStudyGroupListItem.fromJson(Map<String, dynamic> json) {
    return AdminStudyGroupListItem(
      id: json['id'] as int,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class AdminTaskListItem {
  const AdminTaskListItem({
    required this.id,
    required this.deadline,
    required this.startDate,
    required this.translateToRussian,
    required this.availableAfterEnd,
    required this.attemptsCount,
    required this.vocabularySetId,
    required this.vocabularySetName,
  });

  final int id;
  final DateTime? deadline;
  final DateTime? startDate;
  final bool translateToRussian;
  final bool availableAfterEnd;
  final int attemptsCount;
  final int vocabularySetId;
  final String vocabularySetName;

  factory AdminTaskListItem.fromJson(Map<String, dynamic> json) {
    final vocabularySet = json['vocabulary_sets'];

    return AdminTaskListItem(
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
    );
  }

  static DateTime? _parseNullableDate(Object? value) {
    if (value == null) {
      return null;
    }

    return DateTime.parse(value as String);
  }
}
