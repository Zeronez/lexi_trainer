class TestWord {
  const TestWord({
    required this.id,
    required this.russian,
    required this.english,
  });

  final String id;
  final String russian;
  final String english;

  TestWord copyWith({String? id, String? russian, String? english}) {
    return TestWord(
      id: id ?? this.id,
      russian: russian ?? this.russian,
      english: english ?? this.english,
    );
  }
}

class WordFactory {
  const WordFactory._();

  static TestWord apple({
    String id = 'word-apple',
    String russian = 'яблоко',
    String english = 'apple',
  }) {
    return TestWord(id: id, russian: russian, english: english);
  }

  static TestWord book({
    String id = 'word-book',
    String russian = 'книга',
    String english = 'book',
  }) {
    return TestWord(id: id, russian: russian, english: english);
  }

  static TestWord water({
    String id = 'word-water',
    String russian = 'вода',
    String english = 'water',
  }) {
    return TestWord(id: id, russian: russian, english: english);
  }

  static TestWord custom({
    required String id,
    required String russian,
    required String english,
  }) {
    return TestWord(id: id, russian: russian, english: english);
  }

  static List<TestWord> defaultSet() {
    return [
      apple(),
      book(),
      water(),
      TestWord(id: 'word-sun', russian: 'солнце', english: 'sun'),
      TestWord(id: 'word-school', russian: 'школа', english: 'school'),
    ];
  }
}
