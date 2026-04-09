import '../entities/training_result.dart';

class TrainingProgress {
  const TrainingProgress({
    required this.completed,
    required this.total,
    required this.accuracy,
  });

  final int completed;
  final int total;
  final double accuracy;
}

class CalculateTrainingProgressUseCase {
  const CalculateTrainingProgressUseCase();

  TrainingProgress call(TrainingResult result) {
    final total = result.totalAnswers;
    final completed = result.correctAnswers.clamp(0, total);
    final accuracy = total == 0 ? 0.0 : completed / total;

    return TrainingProgress(
      completed: completed,
      total: total,
      accuracy: accuracy,
    );
  }
}
