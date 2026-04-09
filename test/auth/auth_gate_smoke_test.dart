import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_trainer/features/auth/presentation/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('AuthGate renders unauthenticated child without session', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AuthGate(
          initialSession: null,
          authStateChanges: Stream<AuthState>.empty(),
          unauthenticatedChild: _AuthGateSmoke(),
          authenticatedChild: SizedBox.shrink(),
        ),
      ),
    );

    expect(find.byType(_AuthGateSmoke), findsOneWidget);
    expect(find.text('Auth gate smoke'), findsOneWidget);
  });
}

class _AuthGateSmoke extends StatelessWidget {
  const _AuthGateSmoke();

  @override
  Widget build(BuildContext context) {
    return const Text('Auth gate smoke');
  }
}
