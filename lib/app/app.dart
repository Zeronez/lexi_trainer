import 'package:flutter/material.dart';
import 'package:lexi_trainer/core/theme/app_colors.dart';
import 'package:lexi_trainer/core/theme/app_theme.dart';
import 'package:lexi_trainer/features/auth/presentation/auth_gate.dart';

class App extends StatelessWidget {
  const App({super.key, this.initializationError});

  final Object? initializationError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lexi Trainer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: initializationError == null
          ? const AuthGate()
          : _InitializationErrorScreen(error: initializationError!),
    );
  }
}

class _InitializationErrorScreen extends StatelessWidget {
  const _InitializationErrorScreen({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Не удалось запустить приложение',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Проверьте SUPABASE_URL и SUPABASE_PUBLISHABLE_KEY, а также доступ к сети.',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Техническая причина: $error',
                      style: const TextStyle(color: AppColors.text),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
