import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexi_trainer/core/auth/current_user_role_provider.dart';
import 'package:lexi_trainer/core/auth/sign_out_button.dart';
import 'package:lexi_trainer/core/auth/user_role.dart';
import 'package:lexi_trainer/features/achievements/presentation/achievements_screen.dart';
import 'package:lexi_trainer/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:lexi_trainer/features/home/presentation/monthly_assignments_card.dart';
import 'package:lexi_trainer/features/learning/presentation/learning_assignments_screen.dart';
import 'package:lexi_trainer/features/notifications/presentation/notifications_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final userRole = ref.watch(currentUserRoleProvider);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Align(
                          alignment: Alignment.centerRight,
                          child: SignOutButton(showLabel: true),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Lexi Trainer',
                          style: textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '\u0418\u0437\u0443\u0447\u0430\u0439\u0442\u0435 \u043b\u0435\u043a\u0441\u0438\u043a\u0443 \u0432 \u0441\u043f\u043e\u043a\u043e\u0439\u043d\u044b\u0445 \u0438 \u043a\u043e\u0440\u043e\u0442\u043a\u0438\u0445 \u0441\u0435\u0441\u0441\u0438\u044f\u0445.',
                          style: textTheme.titleMedium?.copyWith(height: 1.35),
                        ),
                        const SizedBox(height: 32),
                        const MonthlyAssignmentsCard(),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const LearningAssignmentsScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              '\u041d\u0430\u0447\u0430\u0442\u044c \u0442\u0440\u0435\u043d\u0438\u0440\u043e\u0432\u043a\u0443',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AchievementsScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              '\u041c\u043e\u0438 \u0434\u043e\u0441\u0442\u0438\u0436\u0435\u043d\u0438\u044f',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const NotificationsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.inbox_outlined),
                            label: const Text(
                              '\u0412\u0445\u043e\u0434\u044f\u0449\u0438\u0435',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        userRole.when(
                          data: (role) {
                            if (!role.canOpenAdminSection) {
                              return const SizedBox.shrink();
                            }
                            return SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const AdminDashboardScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.admin_panel_settings_outlined,
                                ),
                                label: const Text(
                                  '\u0410\u0434\u043c\u0438\u043d-\u0440\u0430\u0437\u0434\u0435\u043b',
                                ),
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
