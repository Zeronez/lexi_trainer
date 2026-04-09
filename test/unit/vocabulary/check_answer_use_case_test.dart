import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_trainer/features/vocabulary/domain/entities/training_word.dart';
import 'package:lexi_trainer/features/vocabulary/domain/use_cases/check_answer_use_case.dart';

void main() {
  group('CheckAnswerUseCase', () {
    const useCase = CheckAnswerUseCase();
    const word = TrainingWord(prompt: 'яблоко', answer: 'Apple');

    test('returns true for exact answer', () {
      expect(useCase(word: word, answer: 'Apple'), isTrue);
    });

    test('ignores letter case and surrounding spaces', () {
      expect(useCase(word: word, answer: '  apple  '), isTrue);
    });

    test('returns false for wrong answer', () {
      expect(useCase(word: word, answer: 'book'), isFalse);
    });
  });
}
