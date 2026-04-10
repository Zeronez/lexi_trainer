class AdminReportMetrics {
  const AdminReportMetrics({
    required this.vocabularySetCount,
    required this.taskCount,
    required this.completedTaskCount,
    required this.averageAnswerAccuracyPercent,
    required this.activeStudentCount,
  });

  final int vocabularySetCount;
  final int taskCount;
  final int completedTaskCount;
  final double averageAnswerAccuracyPercent;
  final int activeStudentCount;
}
