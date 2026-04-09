class TestAnswer {
  const TestAnswer({
    required this.wordId,
    required this.value,
    this.isCorrect = true,
  });

  final String wordId;
  final String value;
  final bool isCorrect;

  TestAnswer copyWith({String? wordId, String? value, bool? isCorrect}) {
    return TestAnswer(
      wordId: wordId ?? this.wordId,
      value: value ?? this.value,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}

class AnswerFactory {
  const AnswerFactory._();

  static TestAnswer correct({
    String wordId = 'word-apple',
    String value = 'apple',
  }) {
    return TestAnswer(wordId: wordId, value: value, isCorrect: true);
  }

  static TestAnswer incorrect({
    String wordId = 'word-apple',
    String value = 'apples',
  }) {
    return TestAnswer(wordId: wordId, value: value, isCorrect: false);
  }

  static TestAnswer custom({
    required String wordId,
    required String value,
    bool isCorrect = true,
  }) {
    return TestAnswer(wordId: wordId, value: value, isCorrect: isCorrect);
  }
}
