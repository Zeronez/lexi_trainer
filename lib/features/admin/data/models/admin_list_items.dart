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
      id: _readInt(json['id']),
      themeName: json['theme_name'] as String,
      cefrLevel: json['cefr_level'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String,
    );
  }
}

class AdminVocabularySetDetails {
  const AdminVocabularySetDetails({
    required this.id,
    required this.themeName,
    required this.cefrLevel,
    required this.createdAt,
    required this.userId,
    required this.words,
  });

  final int id;
  final String themeName;
  final String cefrLevel;
  final DateTime createdAt;
  final String userId;
  final List<AdminVocabularyWordListItem> words;

  factory AdminVocabularySetDetails.fromJson(Map<String, dynamic> json) {
    final links = json['set_words_link'];

    return AdminVocabularySetDetails(
      id: _readInt(json['id']),
      themeName: json['theme_name'] as String,
      cefrLevel: json['cefr_level'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String,
      words: links is List
          ? links
                .map((link) {
                  final linkJson = Map<String, dynamic>.from(link as Map);
                  final word = linkJson['words'];
                  if (word is! Map) {
                    return null;
                  }
                  return AdminVocabularyWordListItem.fromJson(
                    Map<String, dynamic>.from(word),
                  );
                })
                .whereType<AdminVocabularyWordListItem>()
                .toList(growable: false)
          : const <AdminVocabularyWordListItem>[],
    );
  }
}

class AdminVocabularyWordListItem {
  const AdminVocabularyWordListItem({
    required this.id,
    required this.russianWord,
    required this.englishTranslation,
    required this.transcription,
    required this.exampleSentence,
  });

  final int id;
  final String russianWord;
  final String englishTranslation;
  final String? transcription;
  final String? exampleSentence;

  factory AdminVocabularyWordListItem.fromJson(Map<String, dynamic> json) {
    return AdminVocabularyWordListItem(
      id: _readInt(json['id']),
      russianWord: json['russian_word'] as String,
      englishTranslation: json['english_translation'] as String,
      transcription: json['transcription'] as String?,
      exampleSentence: json['example_sentence'] as String?,
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
      id: _readInt(json['id']),
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class AdminStudyGroupDetails {
  const AdminStudyGroupDetails({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.members,
  });

  final int id;
  final String name;
  final DateTime createdAt;
  final List<AdminStudyGroupMemberItem> members;

  factory AdminStudyGroupDetails.fromJson({
    required Map<String, dynamic> groupJson,
    required List<Map<String, dynamic>> memberRows,
  }) {
    return AdminStudyGroupDetails(
      id: _readInt(groupJson['id']),
      name: groupJson['name'] as String,
      createdAt: DateTime.parse(groupJson['created_at'] as String),
      members: memberRows
          .map(AdminStudyGroupMemberItem.fromJson)
          .toList(growable: false),
    );
  }
}

class AdminStudyGroupMemberItem {
  const AdminStudyGroupMemberItem({
    required this.id,
    required this.username,
    required this.email,
  });

  final String id;
  final String username;
  final String email;

  factory AdminStudyGroupMemberItem.fromJson(Map<String, dynamic> json) {
    return AdminStudyGroupMemberItem(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
    );
  }

  String get displayName => username.isNotEmpty ? username : email;
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
      id: _readInt(json['id']),
      deadline: _parseNullableDate(json['deadline']),
      startDate: _parseNullableDate(json['start_date']),
      translateToRussian: json['translate_to_russian'] as bool,
      availableAfterEnd: json['available_after_end'] as bool,
      attemptsCount: _readInt(json['attempts_count']),
      vocabularySetId: _readInt(json['vocabulary_set_id']),
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

  throw FormatException('Не удалось прочитать числовое значение.');
}
