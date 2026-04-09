import 'package:flutter/material.dart';
import 'package:lexi_trainer/core/theme/app_colors.dart';

class VocabularyTrainingScreen extends StatefulWidget {
  const VocabularyTrainingScreen({super.key});

  @override
  State<VocabularyTrainingScreen> createState() =>
      _VocabularyTrainingScreenState();
}

class _VocabularyTrainingScreenState extends State<VocabularyTrainingScreen> {
  final _answerController = TextEditingController();

  final List<_TaskWord> _words = const [
    _TaskWord(russian: 'яблоко', english: 'apple'),
    _TaskWord(russian: 'книга', english: 'book'),
    _TaskWord(russian: 'вода', english: 'water'),
    _TaskWord(russian: 'солнце', english: 'sun'),
    _TaskWord(russian: 'школа', english: 'school'),
  ];

  int _index = 0;
  int _correctAnswers = 0;
  String? _feedback;
  bool _checked = false;

  bool get _isCompleted => _index >= _words.length;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    if (_checked || _isCompleted) {
      return;
    }
    final answer = _answerController.text.trim().toLowerCase();
    if (answer.isEmpty) {
      setState(() => _feedback = 'Введите перевод перед проверкой.');
      return;
    }

    final expected = _words[_index].english.toLowerCase();
    final isCorrect = answer == expected;
    setState(() {
      _checked = true;
      if (isCorrect) {
        _correctAnswers += 1;
        _feedback = 'Верно';
      } else {
        _feedback = 'Неверно. Правильный ответ: ${_words[_index].english}';
      }
    });
  }

  void _nextQuestion() {
    if (!_checked) {
      return;
    }
    setState(() {
      _index += 1;
      _checked = false;
      _feedback = null;
      _answerController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = _index / _words.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Тренировка слов')),
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
                      'Задание: переведите слово на английский',
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
                    Text('Слово ${_index + 1} из ${_words.length}'),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _words[_index].russian,
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _answerController,
                              enabled: !_checked,
                              decoration: const InputDecoration(
                                labelText: 'Ваш ответ',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            if (_feedback != null) ...[
                              const SizedBox(height: 16),
                              _FeedbackBadge(
                                text: _feedback!,
                                success: _feedback!.startsWith('Верно'),
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
                        onPressed: _checked ? _nextQuestion : _checkAnswer,
                        child: Text(_checked ? 'Следующее слово' : 'Проверить'),
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
                'Сессия завершена',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Правильных ответов: $correctAnswers из $total',
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

class _TaskWord {
  const _TaskWord({required this.russian, required this.english});

  final String russian;
  final String english;
}
