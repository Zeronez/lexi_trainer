import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_trainer/features/vocabulary/domain/entities/training_result.dart';
import 'package:lexi_trainer/features/vocabulary/domain/use_cases/calculate_training_progress_use_case.dart';

void main() {
  group('CalculateTrainingProgressUseCase', () {
    const useCase = CalculateTrainingProgressUseCase();

    test('calculates completed answers and accuracy', () {
      final progress = useCase(
        const TrainingResult(correctAnswers: 3, totalAnswers: 4),
      );

      expect(progress.completed, 3);
      expect(progress.total, 4);
      expect(progress.accuracy, 0.75);
    });

    test('returns zero accuracy when there are no answers', () {
      final progress = useCase(
        const TrainingResult(correctAnswers: 0, totalAnswers: 0),
      );

      expect(progress.completed, 0);
      expect(progress.total, 0);
      expect(progress.accuracy, 0);
    });

    test('does not report more completed answers than total answers', () {
      final progress = useCase(
        const TrainingResult(correctAnswers: 5, totalAnswers: 3),
      );

      expect(progress.completed, 3);
      expect(progress.total, 3);
      expect(progress.accuracy, 1);
    });
  });
}
