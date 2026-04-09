# Test Support

Reusable helpers for tests live here.

## Factories

Use factories when a test needs readable, repeatable data:

```dart
import 'package:lexi_trainer/test/support/factories/test_data_factories.dart';

final word = WordFactory.apple();
final answer = AnswerFactory.correct(wordId: word.id);
final role = RoleFactory.admin();
```

You can also build custom variants:

```dart
final customWord = WordFactory.custom(
  id: 'word-1',
  russian: 'стол',
  english: 'table',
);
```

## Mocks

Use the fake sources when a widget or service needs a simple in-memory dependency:

```dart
import 'package:lexi_trainer/test/support/mocks/test_mocks.dart';

final roles = FakeAuthRoleSource();
roles.setRole(RoleFactory.teacher());

final words = FakeTrainingWordProvider();
words.addWord(WordFactory.book());
```

## Notes

- Keep helpers small and dependency-free.
- Prefer these helpers over repeating raw literals in tests.
