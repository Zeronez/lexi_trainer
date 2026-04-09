import '../factories/word_factory.dart';

abstract class TrainingWordProvider {
  List<TestWord> words();
}

class FakeTrainingWordProvider implements TrainingWordProvider {
  FakeTrainingWordProvider([List<TestWord>? words])
    : _words = List<TestWord>.of(words ?? WordFactory.defaultSet());

  final List<TestWord> _words;

  @override
  List<TestWord> words() => List<TestWord>.unmodifiable(_words);

  void setWords(List<TestWord> words) {
    _words
      ..clear()
      ..addAll(words);
  }

  void addWord(TestWord word) {
    _words.add(word);
  }
}
