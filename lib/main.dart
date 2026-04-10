import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lexi_trainer/app/app.dart';
import 'package:lexi_trainer/core/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? initializationError;
  try {
    final config = AppConfig.fromEnvironment();
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabasePublishableKey,
    ).timeout(const Duration(seconds: 15));
  } catch (error) {
    initializationError = error;
  }

  runApp(ProviderScope(child: App(initializationError: initializationError)));
}
