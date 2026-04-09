import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_trainer/core/theme/app_theme.dart';
import 'package:lexi_trainer/features/achievements/presentation/achievements_screen.dart';

import '../support/supabase_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await initializeSupabaseForTests();
  });

  testWidgets('renders achievements list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AchievementsScreen()),
    );

    expect(find.text('Достижения'), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(3));
    expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
  });
}
