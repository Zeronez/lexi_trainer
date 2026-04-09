import 'package:supabase_flutter/supabase_flutter.dart';

bool _initialized = false;

Future<void> initializeSupabaseForTests() async {
  if (_initialized) {
    return;
  }

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    throw StateError(
      'Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY for tests. '
      'Pass both via --dart-define in CI.',
    );
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabasePublishableKey);
  _initialized = true;
}

Future<void> clearSessionForTests() async {
  if (!_initialized) {
    return;
  }
  await Supabase.instance.client.auth.signOut();
}
