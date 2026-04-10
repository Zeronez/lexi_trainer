import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_trainer/core/auth/current_user_role_provider.dart';
import 'package:lexi_trainer/core/auth/user_role.dart';
import 'package:lexi_trainer/core/theme/app_theme.dart';
import 'package:lexi_trainer/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('shows admin section button for admin role', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserRoleProvider.overrideWith((ref) async => UserRole.admin),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(
      find.text(
        '\u0410\u0434\u043c\u0438\u043d-\u0440\u0430\u0437\u0434\u0435\u043b',
      ),
      findsOneWidget,
    );
    expect(
      find.text('\u0412\u0445\u043e\u0434\u044f\u0449\u0438\u0435'),
      findsOneWidget,
    );
  });

  testWidgets('hides admin section button for student role', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserRoleProvider.overrideWith((ref) async => UserRole.student),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();
    expect(
      find.text(
        '\u0410\u0434\u043c\u0438\u043d-\u0440\u0430\u0437\u0434\u0435\u043b',
      ),
      findsNothing,
    );
    expect(
      find.text('\u0412\u0445\u043e\u0434\u044f\u0449\u0438\u0435'),
      findsOneWidget,
    );
  });
}
