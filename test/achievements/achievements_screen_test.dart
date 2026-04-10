import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_trainer/core/theme/app_theme.dart';
import 'package:lexi_trainer/features/achievements/data/repositories/achievements_repository.dart';
import 'package:lexi_trainer/features/achievements/presentation/achievements_screen.dart';

void main() {
  testWidgets('shows loading, empty and data states', (tester) async {
    final completer = Completer<List<AchievementItem>>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          achievementsRepositoryProvider.overrideWithValue(
            FakeAchievementsRepository.loading(completer.future),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AchievementsScreen(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(_fakeAchievements);
    await tester.pumpAndSettle();

    expect(
      find.text('\u0414\u043e\u0441\u0442\u0438\u0436\u0435\u043d\u0438\u044f'),
      findsOneWidget,
    );
    expect(
      find.text(
        '\u041f\u0435\u0440\u0432\u044b\u0435 10 \u0441\u043b\u043e\u0432',
      ),
      findsOneWidget,
    );
    expect(
      find.text('\u0421\u0435\u0440\u0438\u044f 7 \u0434\u043d\u0435\u0439'),
      findsOneWidget,
    );
    expect(
      find.text('\u0422\u043e\u0447\u043d\u043e\u0441\u0442\u044c 90%'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          achievementsRepositoryProvider.overrideWithValue(
            FakeAchievementsRepository.empty(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AchievementsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        '\u041f\u043e\u043a\u0430 \u043d\u0435\u0442 \u0434\u043e\u0441\u0442\u0438\u0436\u0435\u043d\u0438\u0439',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows error state from provider override', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          achievementsRepositoryProvider.overrideWithValue(
            FakeAchievementsRepository.error(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AchievementsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        '\u041d\u0435 \u0443\u0434\u0430\u043b\u043e\u0441\u044c \u0437\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u044c \u0434\u043e\u0441\u0442\u0438\u0436\u0435\u043d\u0438\u044f',
      ),
      findsOneWidget,
    );
  });
}

class FakeAchievementsRepository implements AchievementsRepositoryBase {
  FakeAchievementsRepository.loading(this._future) : _mode = _FakeMode.loading;

  FakeAchievementsRepository.empty()
    : _mode = _FakeMode.empty,
      _future = Future.value(const <AchievementItem>[]);

  FakeAchievementsRepository.error()
    : _mode = _FakeMode.error,
      _future = Future.value(const <AchievementItem>[]);

  final _FakeMode _mode;
  final Future<List<AchievementItem>> _future;

  @override
  Future<List<AchievementItem>> fetchAchievements() async {
    if (_mode == _FakeMode.error) {
      throw Exception('boom');
    }

    return _future;
  }
}

enum _FakeMode { loading, empty, error }

final _fakeAchievements = <AchievementItem>[
  const AchievementItem(
    id: 1,
    title: '\u041f\u0435\u0440\u0432\u044b\u0435 10 \u0441\u043b\u043e\u0432',
    description:
        '\u0412\u044b\u0443\u0447\u0438\u0442\u0435 \u043f\u0435\u0440\u0432\u044b\u0435 10 \u0441\u043b\u043e\u0432.',
    progress: 1,
    isUnlocked: true,
    earnedAt: null,
  ),
  const AchievementItem(
    id: 2,
    title: '\u0421\u0435\u0440\u0438\u044f 7 \u0434\u043d\u0435\u0439',
    description:
        '\u0417\u0430\u043d\u0438\u043c\u0430\u0439\u0442\u0435\u0441\u044c \u0431\u0435\u0437 \u043f\u0435\u0440\u0435\u0440\u044b\u0432\u043e\u0432 7 \u0434\u043d\u0435\u0439.',
    progress: 0.57,
    isUnlocked: false,
    earnedAt: null,
  ),
  const AchievementItem(
    id: 3,
    title: '\u0422\u043e\u0447\u043d\u043e\u0441\u0442\u044c 90%',
    description:
        '\u0414\u0435\u0440\u0436\u0438\u0442\u0435 \u0442\u043e\u0447\u043d\u043e\u0441\u0442\u044c 90% \u043d\u0430 5 \u0441\u0435\u0441\u0441\u0438\u044f\u0445 \u043f\u043e\u0434\u0440\u044f\u0434.',
    progress: 0.4,
    isUnlocked: false,
    earnedAt: null,
  ),
];
