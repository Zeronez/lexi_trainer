import '../entities/training_word.dart';

class CheckAnswerUseCase {
  const CheckAnswerUseCase();

  bool call({required TrainingWord word, required String answer}) {
    return answer.trim().toLowerCase() == word.answer.trim().toLowerCase();
  }
}
