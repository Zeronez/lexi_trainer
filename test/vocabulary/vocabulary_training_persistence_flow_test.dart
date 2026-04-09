import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_trainer/core/theme/app_theme.dart';
import 'package:lexi_trainer/features/vocabulary/presentation/vocabulary_training_screen.dart';
import 'package:lexi_trainer/test/support/mocks/test_mocks.dart';

void main() {
  group('Vocabulary training persistence flow', () {
    testWidgets('submitAnswer is called with true for a correct answer', (
      tester,
    ) async {
      final sink = FakeTrainingPersistenceSink();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: VocabularyTrainingPersistenceHarness(
            words: const [
              TrainingWordInput(russian: 'яблоко', english: 'apple'),
            ],
            submitAnswer: sink.submitAnswer,
            completeSession: sink.completeSession,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'apple');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(sink.submittedAnswers, hasLength(1));
      expect(sink.submittedAnswers.single, isTrue);
    });

    testWidgets('submitAnswer is called with false for a wrong answer', (
      tester,
    ) async {
      final sink = FakeTrainingPersistenceSink();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: VocabularyTrainingPersistenceHarness(
            words: const [TrainingWordInput(russian: 'книга', english: 'book')],
            submitAnswer: sink.submitAnswer,
            completeSession: sink.completeSession,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'door');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      expect(sink.submittedAnswers, hasLength(1));
      expect(sink.submittedAnswers.single, isFalse);
    });

    testWidgets('completeSession is called when the last word is finished', (
      tester,
    ) async {
      final sink = FakeTrainingPersistenceSink();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: VocabularyTrainingPersistenceHarness(
            words: const [TrainingWordInput(russian: 'вода', english: 'water')],
            submitAnswer: sink.submitAnswer,
            completeSession: sink.completeSession,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'water');
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();

      expect(sink.submittedAnswers, [true]);
      expect(sink.completionCalls, 1);
      expect(find.text('Session completed'), findsOneWidget);
    });
  });
}

class VocabularyTrainingPersistenceHarness extends StatefulWidget {
  const VocabularyTrainingPersistenceHarness({
    super.key,
    required this.words,
    required this.submitAnswer,
    required this.completeSession,
  });

  final List<TrainingWordInput> words;
  final Future<void> Function({required bool isCorrect}) submitAnswer;
  final Future<void> Function() completeSession;

  @override
  State<VocabularyTrainingPersistenceHarness> createState() =>
      _VocabularyTrainingPersistenceHarnessState();
}

class _VocabularyTrainingPersistenceHarnessState
    extends State<VocabularyTrainingPersistenceHarness> {
  final _controller = TextEditingController();

  int _index = 0;
  bool _checked = false;
  bool _completed = false;
  String? _feedback;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLastWord => _index == widget.words.length - 1;

  Future<void> _checkAnswer() async {
    if (_checked || _completed) {
      return;
    }

    final answer = _controller.text.trim().toLowerCase();
    final expected = widget.words[_index].english.trim().toLowerCase();
    final isCorrect = answer == expected;

    await widget.submitAnswer(isCorrect: isCorrect);
    if (!mounted) {
      return;
    }

    setState(() {
      _checked = true;
      _feedback = isCorrect ? 'Correct' : 'Wrong';
    });
  }

  Future<void> _nextQuestion() async {
    if (!_checked || _completed) {
      return;
    }

    if (_isLastWord) {
      await widget.completeSession();
      if (!mounted) {
        return;
      }

      setState(() {
        _completed = true;
      });
      return;
    }

    setState(() {
      _index += 1;
      _checked = false;
      _feedback = null;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) {
      return const Scaffold(body: Center(child: Text('Session completed')));
    }

    final word = widget.words[_index];

    return Scaffold(
      appBar: AppBar(title: const Text('Vocabulary Training')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Word ${_index + 1} of ${widget.words.length}'),
            const SizedBox(height: 16),
            Text(word.russian),
            const SizedBox(height: 16),
            TextField(controller: _controller),
            if (_feedback != null) ...[
              const SizedBox(height: 12),
              Text(_feedback!),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _checked ? _nextQuestion : _checkAnswer,
                child: Text(_checked ? 'Finish' : 'Check'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
