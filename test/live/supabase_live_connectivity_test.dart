import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('supabase rest endpoint is reachable with provided config', () async {
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabasePublishableKey = String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    );

    expect(supabaseUrl, isNotEmpty);
    expect(supabasePublishableKey, isNotEmpty);

    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('$supabaseUrl/rest/v1/'));
      request.headers.set('apikey', supabasePublishableKey);
      request.headers.set('Authorization', 'Bearer $supabasePublishableKey');

      final response = await request.close();
      // Any non-5xx response means host is reachable and key is processed.
      expect(response.statusCode, inInclusiveRange(200, 499));
    } finally {
      client.close(force: true);
    }
  });
}
