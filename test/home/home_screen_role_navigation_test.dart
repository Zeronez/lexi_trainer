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
    expect(find.text('Админ-раздел'), findsOneWidget);
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
    expect(find.text('Админ-раздел'), findsNothing);
  });
}
