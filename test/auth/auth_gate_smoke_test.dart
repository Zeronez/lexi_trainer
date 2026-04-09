import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_trainer/features/auth/presentation/auth_gate.dart';
import 'package:lexi_trainer/features/auth/presentation/auth_screen.dart';
import '../support/supabase_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await initializeSupabaseForTests();
  });

  setUp(() async {
    await clearSessionForTests();
  });

  testWidgets('AuthGate renders unauthenticated child without session', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuthGate()));

    expect(find.byType(AuthScreen), findsOneWidget);
  });
}
