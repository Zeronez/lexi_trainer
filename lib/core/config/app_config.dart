abstract final class EnvKeys {
  static const supabaseUrl = 'SUPABASE_URL';
  static const supabasePublishableKey = 'SUPABASE_PUBLISHABLE_KEY';
}

class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  final String supabaseUrl;
  final String supabasePublishableKey;

  static const _supabaseUrl = String.fromEnvironment(EnvKeys.supabaseUrl);
  static const _supabasePublishableKey = String.fromEnvironment(
    EnvKeys.supabasePublishableKey,
  );

  factory AppConfig.fromEnvironment() {
    final missingKeys = <String>[
      if (_supabaseUrl.isEmpty) EnvKeys.supabaseUrl,
      if (_supabasePublishableKey.isEmpty) EnvKeys.supabasePublishableKey,
    ];

    if (missingKeys.isNotEmpty) {
      throw StateError(
        'Missing required dart-define value(s): ${missingKeys.join(', ')}. '
        'Run with --dart-define=${EnvKeys.supabaseUrl}=... '
        '--dart-define=${EnvKeys.supabasePublishableKey}=...',
      );
    }

    return const AppConfig(
      supabaseUrl: _supabaseUrl,
      supabasePublishableKey: _supabasePublishableKey,
    );
  }
}
