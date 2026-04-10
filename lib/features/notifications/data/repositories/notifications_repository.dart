import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepositoryBase>((
  ref,
) {
  return SupabaseNotificationsRepository(Supabase.instance.client);
});

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) {
  return ref.watch(notificationsRepositoryProvider).fetchInbox();
});

abstract class NotificationsRepositoryBase {
  Future<List<AppNotification>> fetchInbox();
}

class SupabaseNotificationsRepository implements NotificationsRepositoryBase {
  const SupabaseNotificationsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AppNotification>> fetchInbox() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User is not authenticated.');
    }

    final linkRows = await _client
        .from('notification_users_link')
        .select('notification_id')
        .eq('user_id', userId);

    final notificationIds = linkRows
        .map((row) => row['notification_id'])
        .whereType<int>()
        .toList();

    if (notificationIds.isEmpty) {
      return const <AppNotification>[];
    }

    final rows = await _client
        .from('notifications')
        .select('id, type, text, sent_at')
        .inFilter('id', notificationIds)
        .order('sent_at', ascending: false);

    return rows
        .map((row) => AppNotification.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
  });

  final int id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'notification';
    return AppNotification(
      id: json['id'] as int,
      title: _buildTitle(type),
      body: json['text'] as String,
      createdAt: DateTime.parse(json['sent_at'] as String),
      isRead: false,
    );
  }

  static String _buildTitle(String type) {
    return switch (type) {
      'achievement_awarded' =>
        '\u041d\u043e\u0432\u043e\u0435 \u0434\u043e\u0441\u0442\u0438\u0436\u0435\u043d\u0438\u0435',
      'teacher_message' =>
        '\u0421\u043e\u043e\u0431\u0449\u0435\u043d\u0438\u0435 \u043f\u0440\u0435\u043f\u043e\u0434\u0430\u0432\u0430\u0442\u0435\u043b\u044f',
      'deadline' =>
        '\u0421\u0440\u043e\u043a \u0437\u0430\u0434\u0430\u043d\u0438\u044f',
      _ => '\u0423\u0432\u0435\u0434\u043e\u043c\u043b\u0435\u043d\u0438\u0435',
    };
  }
}
