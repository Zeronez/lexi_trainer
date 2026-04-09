class FakeTrainingPersistenceSink {
  final List<bool> submittedAnswers = <bool>[];
  int completionCalls = 0;

  Future<void> submitAnswer({required bool isCorrect}) async {
    submittedAnswers.add(isCorrect);
  }

  Future<void> completeSession() async {
    completionCalls += 1;
  }
}
