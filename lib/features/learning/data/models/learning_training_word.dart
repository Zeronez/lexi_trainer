class LearningTrainingWord {
  const LearningTrainingWord({
    required this.id,
    required this.russianWord,
    required this.englishTranslation,
  });

  final int id;
  final String russianWord;
  final String englishTranslation;

  factory LearningTrainingWord.fromSetWordLinkJson(Map<String, dynamic> json) {
    final word = json['words'];
    if (word is! Map<String, dynamic>) {
      throw const FormatException('Не удалось прочитать слово из набора.');
    }

    return LearningTrainingWord(
      id: word['id'] as int,
      russianWord: word['russian_word'] as String,
      englishTranslation: word['english_translation'] as String,
    );
  }
}
