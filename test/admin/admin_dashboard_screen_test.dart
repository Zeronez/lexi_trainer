import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_trainer/core/theme/app_theme.dart';
import 'package:lexi_trainer/features/admin/presentation/admin_dashboard_screen.dart';

void main() {
  testWidgets('renders admin dashboard tabs', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AdminDashboardScreen()),
    );

    expect(find.text('Панель администратора'), findsOneWidget);
    expect(find.text('Контент'), findsOneWidget);
    expect(find.text('Группы'), findsOneWidget);
    expect(find.text('Задания'), findsOneWidget);
  });
}
