import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_trainer/core/auth/current_user_role_provider.dart';
import 'package:lexi_trainer/core/auth/user_role.dart';
import 'package:lexi_trainer/core/theme/app_theme.dart';
import 'package:lexi_trainer/features/home/presentation/home_screen.dart';

void main() {
  test('UserRole.fromValue maps admin teacher student matrix', () {
    expect(UserRole.fromValue('admin'), UserRole.admin);
    expect(UserRole.fromValue('teacher'), UserRole.teacher);
    expect(UserRole.fromValue('student'), UserRole.student);
    expect(UserRole.fromValue('unknown'), UserRole.unknown);
    expect(UserRole.fromValue(null), UserRole.unknown);
  });

  test(
    'permission matrix exposes admin section only for admin and teacher',
    () {
      expect(UserRole.admin.canOpenAdminSection, isTrue);
      expect(UserRole.teacher.canOpenAdminSection, isTrue);
      expect(UserRole.student.canOpenAdminSection, isFalse);
      expect(UserRole.unknown.canOpenAdminSection, isFalse);
    },
  );

  testWidgets('home navigation shows admin section for admin', (tester) async {
    await _pumpHomeForRole(tester, UserRole.admin);
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

  testWidgets('home navigation shows admin section for teacher', (
    tester,
  ) async {
    await _pumpHomeForRole(tester, UserRole.teacher);
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

  testWidgets('home navigation hides admin section for student', (
    tester,
  ) async {
    await _pumpHomeForRole(tester, UserRole.student);
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

Future<void> _pumpHomeForRole(WidgetTester tester, UserRole role) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [currentUserRoleProvider.overrideWith((ref) async => role)],
      child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}
