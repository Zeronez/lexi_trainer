import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_trainer/core/theme/app_theme.dart';
import 'package:lexi_trainer/features/vocabulary/presentation/vocabulary_training_screen.dart';

void main() {
  testWidgets('checks answer and moves to next word', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const VocabularyTrainingScreen(),
      ),
    );

    expect(
      find.text('\u0421\u043b\u043e\u0432\u043e 1 \u0438\u0437 5'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'apple');
    await tester.tap(
      find.text('\u041f\u0440\u043e\u0432\u0435\u0440\u0438\u0442\u044c'),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('\u0412\u0435\u0440\u043d\u043e'),
      findsOneWidget,
    );

    await tester.tap(
      find.text(
        '\u0421\u043b\u0435\u0434\u0443\u044e\u0449\u0435\u0435 \u0441\u043b\u043e\u0432\u043e',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('\u0421\u043b\u043e\u0432\u043e 2 \u0438\u0437 5'),
      findsOneWidget,
    );
  });

  testWidgets('shows completion card after last word', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const VocabularyTrainingScreen(),
      ),
    );

    const answers = ['apple', 'book', 'water', 'sun', 'school'];
    for (var i = 0; i < answers.length; i++) {
      await tester.enterText(find.byType(TextField), answers[i]);
      await tester.tap(
        find.text('\u041f\u0440\u043e\u0432\u0435\u0440\u0438\u0442\u044c'),
      );
      await tester.pumpAndSettle();

      final isLast = i == answers.length - 1;
      await tester.tap(
        find.text(
          isLast
              ? '\u0417\u0430\u0432\u0435\u0440\u0448\u0438\u0442\u044c'
              : '\u0421\u043b\u0435\u0434\u0443\u044e\u0449\u0435\u0435 \u0441\u043b\u043e\u0432\u043e',
        ),
      );
      await tester.pumpAndSettle();
    }

    expect(
      find.text(
        '\u0421\u0435\u0441\u0441\u0438\u044f \u0437\u0430\u0432\u0435\u0440\u0448\u0435\u043d\u0430',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        '\u041f\u0440\u0430\u0432\u0438\u043b\u044c\u043d\u044b\u0445 \u043e\u0442\u0432\u0435\u0442\u043e\u0432',
      ),
      findsOneWidget,
    );
  });
}
