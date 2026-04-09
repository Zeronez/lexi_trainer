import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_trainer/core/theme/app_theme.dart';
import 'package:lexi_trainer/features/auth/presentation/auth_screen.dart';

import 'support/supabase_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await initializeSupabaseForTests();
  });

  testWidgets('renders auth placeholder', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AuthScreen()),
    );

    expect(find.text('Lexi Trainer'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
