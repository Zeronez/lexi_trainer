import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_trainer/core/theme/app_theme.dart';
import 'package:lexi_trainer/features/notifications/data/repositories/notifications_repository.dart';
import 'package:lexi_trainer/features/notifications/presentation/notifications_screen.dart';

void main() {
  testWidgets('shows loading, empty and data states', (tester) async {
    final completer = Completer<List<AppNotification>>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(
            FakeNotificationsRepository.loading(completer.future),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const NotificationsScreen(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(_fakeNotifications);
    await tester.pumpAndSettle();

    expect(
      find.text(
        '\u0423\u0432\u0435\u0434\u043e\u043c\u043b\u0435\u043d\u0438\u044f',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        '\u041d\u043e\u0432\u043e\u0435 \u0437\u0430\u0434\u0430\u043d\u0438\u0435',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        '\u0414\u0435\u0434\u043b\u0430\u0439\u043d \u043f\u0435\u0440\u0435\u043d\u0435\u0441\u0435\u043d',
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(
            FakeNotificationsRepository.empty(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const NotificationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        '\u041d\u0435\u0442 \u043d\u043e\u0432\u044b\u0445 \u0443\u0432\u0435\u0434\u043e\u043c\u043b\u0435\u043d\u0438\u0439',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows error state from provider override', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(
            FakeNotificationsRepository.error(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const NotificationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0437\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u044c \u0443\u0432\u0435\u0434\u043e\u043c\u043b\u0435\u043d\u0438\u044f',
      ),
      findsOneWidget,
    );
  });
}

class FakeNotificationsRepository implements NotificationsRepositoryBase {
  FakeNotificationsRepository.loading(this._future) : _mode = _FakeMode.loading;

  FakeNotificationsRepository.empty()
    : _mode = _FakeMode.empty,
      _future = Future.value(const <AppNotification>[]);

  FakeNotificationsRepository.error()
    : _mode = _FakeMode.error,
      _future = Future.value(const <AppNotification>[]);

  final _FakeMode _mode;
  final Future<List<AppNotification>> _future;

  @override
  Future<List<AppNotification>> fetchInbox() async {
    if (_mode == _FakeMode.error) {
      throw Exception('boom');
    }

    return _future;
  }
}

enum _FakeMode { loading, empty, error }

final _fakeNotifications = <AppNotification>[
  AppNotification(
    id: 1,
    title:
        '\u041d\u043e\u0432\u043e\u0435 \u0437\u0430\u0434\u0430\u043d\u0438\u0435',
    body:
        '\u0412\u0430\u043c \u043d\u0430\u0437\u043d\u0430\u0447\u0435\u043d \u043d\u043e\u0432\u044b\u0439 \u043d\u0430\u0431\u043e\u0440 \u0441\u043b\u043e\u0432.',
    createdAt: DateTime(2026, 4, 10),
    isRead: false,
  ),
  AppNotification(
    id: 2,
    title:
        '\u0414\u0435\u0434\u043b\u0430\u0439\u043d \u043f\u0435\u0440\u0435\u043d\u0435\u0441\u0435\u043d',
    body:
        '\u0421\u0440\u043e\u043a \u0441\u0434\u0430\u0447\u0438 \u0441\u0434\u0432\u0438\u043d\u0443\u0442 \u043d\u0430 \u0437\u0430\u0432\u0442\u0440\u0430.',
    createdAt: DateTime(2026, 4, 9),
    isRead: true,
  ),
];
