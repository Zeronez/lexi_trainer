import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_trainer/core/auth/current_user_role_provider.dart';
import 'package:lexi_trainer/core/auth/user_role.dart';
import 'package:lexi_trainer/core/theme/app_theme.dart';
import 'package:lexi_trainer/features/admin/data/models/admin_list_items.dart';
import 'package:lexi_trainer/features/admin/data/models/admin_user_list_items.dart';
import 'package:lexi_trainer/features/admin/data/repositories/admin_repository.dart';
import 'package:lexi_trainer/features/admin/presentation/admin_dashboard_screen.dart';

void main() {
  testWidgets('renders admin tabs with overridden providers', (tester) async {
    await _pumpDashboardForRole(tester, UserRole.admin);

    await tester.pumpAndSettle();

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(Tab), findsNWidgets(4));
    expect(find.widgetWithText(Tab, 'Пользователи'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Группы'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Контент'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Задания'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'Контент'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Travel Basics'), findsOneWidget);
    expect(find.textContaining('Teacher One'), findsOneWidget);
  });

  testWidgets('renders teacher tabs without admin-only actions', (
    tester,
  ) async {
    await _pumpDashboardForRole(tester, UserRole.teacher);

    await tester.pumpAndSettle();

    expect(find.text('Панель преподавателя'), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(Tab), findsNWidgets(3));
    expect(find.widgetWithText(Tab, 'Пользователи'), findsNothing);
    expect(find.widgetWithText(Tab, 'Контент'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Задания'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Группы'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'Группы'));
    await tester.pumpAndSettle();

    expect(find.text('Создать группу'), findsNothing);
    expect(find.textContaining('ENG-101'), findsOneWidget);
  });
}

Future<void> _pumpDashboardForRole(WidgetTester tester, UserRole role) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserRoleProvider.overrideWith((ref) async => role),
        adminVocabularySetsProvider.overrideWith(
          (ref) async => [
            AdminVocabularySetListItem(
              id: 1,
              themeName: 'Travel Basics',
              cefrLevel: 'A2',
              createdAt: DateTime(2026, 4, 10),
              userId: 'user-1',
              authorName: 'Teacher One',
            ),
          ],
        ),
        adminUsersProvider.overrideWith(
          (ref) async => [
            AdminUserListItem(
              id: 'user-1',
              username: 'teacher_one',
              email: 'teacher@example.com',
              roleId: 2,
              roleName: 'teacher',
              studyGroupId: null,
              studyGroupName: null,
              registeredAt: DateTime(2026, 4, 10),
            ),
          ],
        ),
        adminRolesProvider.overrideWith(
          (ref) async => const [
            AdminRoleListItem(id: 1, name: 'admin'),
            AdminRoleListItem(id: 2, name: 'teacher'),
            AdminRoleListItem(id: 3, name: 'student'),
          ],
        ),
        adminStudyGroupsProvider.overrideWith(
          (ref) async => [
            AdminStudyGroupListItem(
              id: 1,
              name: 'ENG-101',
              createdAt: DateTime(2026, 4, 10),
            ),
          ],
        ),
        adminTasksProvider.overrideWith(
          (ref) async => [
            AdminTaskListItem(
              id: 1,
              deadline: null,
              startDate: null,
              translateToRussian: true,
              availableAfterEnd: false,
              attemptsCount: 2,
              vocabularySetId: 1,
              vocabularySetName: 'Travel Basics',
            ),
          ],
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const AdminDashboardScreen(),
      ),
    ),
  );
}
