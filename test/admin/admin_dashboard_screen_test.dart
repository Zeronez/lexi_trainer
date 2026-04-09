import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_trainer/core/theme/app_theme.dart';
import 'package:lexi_trainer/features/admin/data/models/admin_list_items.dart';
import 'package:lexi_trainer/features/admin/data/repositories/admin_repository.dart';
import 'package:lexi_trainer/features/admin/presentation/admin_dashboard_screen.dart';

void main() {
  testWidgets('renders admin tabs with overridden providers', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminVocabularySetsProvider.overrideWith(
            (ref) async => const [
              AdminVocabularySetListItem(
                id: 1,
                themeName: 'Travel Basics',
                cefrLevel: 'A2',
                createdAt: DateTime(2026, 4, 10),
                userId: 'user-1',
              ),
            ],
          ),
          adminStudyGroupsProvider.overrideWith(
            (ref) async => const [
              AdminStudyGroupListItem(
                id: 1,
                name: 'ENG-101',
                createdAt: DateTime(2026, 4, 10),
              ),
            ],
          ),
          adminTasksProvider.overrideWith(
            (ref) async => const [
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

    await tester.pumpAndSettle();

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(Tab), findsNWidgets(3));
    expect(find.textContaining('Travel Basics'), findsOneWidget);
  });
}
