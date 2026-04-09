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

    expect(find.text('Слово 1 из 5'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'apple');
    await tester.tap(find.text('Проверить'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Верно'), findsOneWidget);

    await tester.tap(find.text('Следующее слово'));
    await tester.pumpAndSettle();

    expect(find.text('Слово 2 из 5'), findsOneWidget);
  });

  testWidgets('shows completion card after last word', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const VocabularyTrainingScreen(),
      ),
    );

    const answers = ['apple', 'book', 'water', 'sun', 'school'];
    for (final answer in answers) {
      await tester.enterText(find.byType(TextField), answer);
      await tester.tap(find.text('Проверить'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Следующее слово'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Сессия завершена'), findsOneWidget);
    expect(find.textContaining('Правильных ответов'), findsOneWidget);
  });
}
