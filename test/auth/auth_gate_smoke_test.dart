import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_trainer/features/auth/presentation/auth_gate.dart';

void main() {
  testWidgets('AuthGate renders unauthenticated child without session', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AuthGate(
          useSupabaseClient: false,
          unauthenticatedChild: Text('guest_mode'),
        ),
      ),
    );

    expect(find.text('guest_mode'), findsOneWidget);
  });
}
