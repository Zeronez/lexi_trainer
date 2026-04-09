import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_trainer/core/theme/app_theme.dart';
import 'package:lexi_trainer/features/achievements/presentation/achievements_screen.dart';

void main() {
  testWidgets('renders achievements list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AchievementsScreen()),
    );

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(3));
    expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
  });
}
