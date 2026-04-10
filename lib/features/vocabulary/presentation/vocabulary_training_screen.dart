import 'package:flutter/material.dart';
import 'package:lexi_trainer/core/theme/app_colors.dart';
import 'package:lexi_trainer/features/learning/data/repositories/learning_repository.dart';

class VocabularyTrainingScreen extends StatefulWidget {
  const VocabularyTrainingScreen({
    super.key,
    this.words = const [],
    this.translateToRussian = false,
    this.taskId,
    this.taskExecutionId,
    this.learningRepository,
  });

  final List<TrainingWordInput> words;
  final bool translateToRussian;
  final int? taskId;
  final int? taskExecutionId;
  final LearningRepository? learningRepository;

  @override
  State<VocabularyTrainingScreen> createState() =>
      _VocabularyTrainingScreenState();
}

class TrainingWordInput {
  const TrainingWordInput({
    this.id,
    required this.russian,
    required this.english,
  });

  final int? id;
  final String russian;
  final String english;
}

class _VocabularyTrainingScreenState extends State<VocabularyTrainingScreen> {
  final _answerController = TextEditingController();

  static const List<TrainingWordInput> _devFallbackWords = [
    TrainingWordInput(
      russian: '\u044f\u0431\u043b\u043e\u043a\u043e',
      english: 'apple',
    ),
    TrainingWordInput(
      russian: '\u043a\u043d\u0438\u0433\u0430',
      english: 'book',
    ),
    TrainingWordInput(russian: '\u0432\u043e\u0434\u0430', english: 'water'),
    TrainingWordInput(
      russian: '\u0441\u043e\u043b\u043d\u0446\u0435',
      english: 'sun',
    ),
    TrainingWordInput(
      russian: '\u0448\u043a\u043e\u043b\u0430',
      english: 'school',
    ),
  ];

  late final List<TrainingWordInput> _words;

  int _index = 0;
  int _correctAnswers = 0;
  int? _attemptId;
  Future<int?>? _attemptFuture;
  DateTime? _attemptStartedAt;
  String? _feedback;
  bool _checked = false;
  bool _isSavingAnswer = false;
  bool _isCompletingSession = false;
  bool _completionRequested = false;

  bool get _isCompleted => _index >= _words.length;
  bool get _hasPersistenceContext =>
      widget.learningRepository != null &&
      widget.taskId != null &&
      widget.taskExecutionId != null;
  String get _targetLanguage => widget.translateToRussian
      ? '\u0440\u0443\u0441\u0441\u043a\u0438\u0439'
      : '\u0430\u043d\u0433\u043b\u0438\u0439\u0441\u043a\u0438\u0439';

  @override
  void initState() {
    super.initState();
    _words = widget.words.isEmpty
        ? _devFallbackWords
        : List<TrainingWordInput>.unmodifiable(widget.words);
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _checkAnswer() async {
    if (_checked || _isCompleted) {
      return;
    }
    final answer = _answerController.text.trim();
    if (answer.isEmpty) {
      setState(() {
        _feedback =
            '\u0412\u0432\u0435\u0434\u0438\u0442\u0435 \u043f\u0435\u0440\u0435\u0432\u043e\u0434 \u043f\u0435\u0440\u0435\u0434 \u043f\u0440\u043e\u0432\u0435\u0440\u043a\u043e\u0439.';
      });
      return;
    }

    final word = _words[_index];
    final expected = _expectedAnswer(word).toLowerCase();
    final isCorrect = answer.toLowerCase() == expected;
    setState(() {
      _checked = true;
      if (isCorrect) {
        _correctAnswers += 1;
        _feedback = '\u0412\u0435\u0440\u043d\u043e';
      } else {
        _feedback =
            '\u041d\u0435\u0432\u0435\u0440\u043d\u043e. \u041f\u0440\u0430\u0432\u0438\u043b\u044c\u043d\u044b\u0439 \u043e\u0442\u0432\u0435\u0442: ${_expectedAnswer(_words[_index])}';
      }
    });

    if (!_hasPersistenceContext) {
      return;
    }

    setState(() => _isSavingAnswer = true);
    await _persistAnswer(
      word: word,
      enteredAnswer: answer,
      isCorrect: isCorrect,
    );
    if (mounted) {
      setState(() => _isSavingAnswer = false);
    }
  }

  Future<void> _nextQuestion() async {
    if (!_checked || _isCompletingSession) {
      return;
    }
    final shouldCompleteSession = _index == _words.length - 1;

    setState(() {
      _index += 1;
      _checked = false;
      _feedback = null;
      _answerController.clear();
    });

    if (shouldCompleteSession) {
      await _completeSession();
    }
  }

  Future<void> _persistAnswer({
    required TrainingWordInput word,
    required String enteredAnswer,
    required bool isCorrect,
  }) async {
    final repository = widget.learningRepository;
    final wordId = word.id;
    if (repository == null || widget.taskExecutionId == null) {
      return;
    }

    if (wordId == null) {
      _showPersistenceError(
        '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0441\u043e\u0445\u0440\u0430\u043d\u0438\u0442\u044c \u043e\u0442\u0432\u0435\u0442: \u0443 \u0441\u043b\u043e\u0432\u0430 \u043d\u0435\u0442 id.',
      );
      return;
    }

    final answeredAt = DateTime.now();
    try {
      final attemptId = await _ensureAttempt(answeredAt);
      if (attemptId == null) {
        return;
      }

      await repository.submitQuestionAnswer(
        attemptId: attemptId,
        wordId: wordId,
        enteredAnswer: enteredAnswer,
        isCorrect: isCorrect,
      );
      await repository.updateAttemptEndedAt(
        attemptId: attemptId,
        endedAt: answeredAt,
      );
    } catch (error) {
      _showPersistenceError(
        '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0441\u043e\u0445\u0440\u0430\u043d\u0438\u0442\u044c \u043e\u0442\u0432\u0435\u0442: $error',
      );
    }
  }

  Future<int?> _ensureAttempt(DateTime answeredAt) {
    if (_attemptId != null) {
      return Future.value(_attemptId);
    }

    if (_attemptFuture != null) {
      return _attemptFuture!;
    }

    final repository = widget.learningRepository;
    final taskExecutionId = widget.taskExecutionId;
    if (repository == null || taskExecutionId == null) {
      return Future.value(null);
    }

    final startedAt = _attemptStartedAt ?? answeredAt;
    _attemptStartedAt = startedAt;
    _attemptFuture = repository
        .submitAttempt(
          taskExecutionId: taskExecutionId,
          startedAt: startedAt,
          endedAt: answeredAt,
        )
        .then((attemptId) {
          _attemptId = attemptId;
          return attemptId;
        })
        .whenComplete(() => _attemptFuture = null);

    return _attemptFuture!;
  }

  Future<void> _completeSession() async {
    final repository = widget.learningRepository;
    final taskExecutionId = widget.taskExecutionId;
    if (!_hasPersistenceContext ||
        repository == null ||
        taskExecutionId == null ||
        _completionRequested) {
      return;
    }

    _completionRequested = true;
    if (mounted) {
      setState(() => _isCompletingSession = true);
    }

    try {
      await repository.completeTaskExecution(taskExecutionId: taskExecutionId);
    } catch (error) {
      _showPersistenceError(
        '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0437\u0430\u0432\u0435\u0440\u0448\u0438\u0442\u044c \u0437\u0430\u0434\u0430\u043d\u0438\u0435: $error',
      );
    } finally {
      if (mounted) {
        setState(() => _isCompletingSession = false);
      }
    }
  }

  void _showPersistenceError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _promptWord(TrainingWordInput word) {
    return widget.translateToRussian ? word.english : word.russian;
  }

  String _expectedAnswer(TrainingWordInput word) {
    return widget.translateToRussian ? word.russian : word.english;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = _index / _words.length;
    final nextButtonLabel = _index == _words.length - 1
        ? '\u0417\u0430\u0432\u0435\u0440\u0448\u0438\u0442\u044c'
        : '\u0421\u043b\u0435\u0434\u0443\u044e\u0449\u0435\u0435 \u0441\u043b\u043e\u0432\u043e';
    final isBusy = _isSavingAnswer || _isCompletingSession;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '\u0422\u0440\u0435\u043d\u0438\u0440\u043e\u0432\u043a\u0430 \u0441\u043b\u043e\u0432',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isCompleted
              ? _CompletedView(
                  correctAnswers: _correctAnswers,
                  total: _words.length,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\u0417\u0430\u0434\u0430\u043d\u0438\u0435: \u043f\u0435\u0440\u0435\u0432\u0435\u0434\u0438\u0442\u0435 \u0441\u043b\u043e\u0432\u043e \u043d\u0430 $_targetLanguage',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: progress,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\u0421\u043b\u043e\u0432\u043e ${_index + 1} \u0438\u0437 ${_words.length}',
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _promptWord(_words[_index]),
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _answerController,
                              enabled: !_checked,
                              decoration: const InputDecoration(
                                labelText:
                                    '\u0412\u0430\u0448 \u043e\u0442\u0432\u0435\u0442',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            if (_feedback != null) ...[
                              const SizedBox(height: 16),
                              _FeedbackBadge(
                                text: _feedback!,
                                success: _feedback!.startsWith(
                                  '\u0412\u0435\u0440\u043d\u043e',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isBusy
                            ? null
                            : (_checked ? _nextQuestion : _checkAnswer),
                        child: isBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _checked
                                    ? nextButtonLabel
                                    : '\u041f\u0440\u043e\u0432\u0435\u0440\u0438\u0442\u044c',
                              ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CompletedView extends StatelessWidget {
  const _CompletedView({required this.correctAnswers, required this.total});

  final int correctAnswers;
  final int total;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events,
                size: 56,
                color: AppColors.success,
              ),
              const SizedBox(height: 16),
              Text(
                '\u0421\u0435\u0441\u0441\u0438\u044f \u0437\u0430\u0432\u0435\u0440\u0448\u0435\u043d\u0430',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '\u041f\u0440\u0430\u0432\u0438\u043b\u044c\u043d\u044b\u0445 \u043e\u0442\u0432\u0435\u0442\u043e\u0432: $correctAnswers \u0438\u0437 $total',
                style: textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackBadge extends StatelessWidget {
  const _FeedbackBadge({required this.text, required this.success});

  final String text;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final color = success ? AppColors.success : AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_outline : Icons.error_outline,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
