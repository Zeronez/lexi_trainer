# Supabase Achievements and Notifications RPC

Документ описывает backend-логику Sprint C для выдачи достижений и создания уведомлений. Все публичные RPC используют `auth.uid()` и доступны только роли `authenticated`.

## Миграция

Файл: `supabase/migrations/20260410_000006_achievements_notifications_rpc.sql`.

Миграция добавляет:

- seed-достижения с машинными правилами в `achievements.condition_text`, если таких правил еще нет;
- RPC `recalculate_user_achievements(p_user_id uuid default null)`;
- RPC `create_user_notification(p_user_id uuid, p_type text, p_text text)`;
- `REVOKE`/`GRANT EXECUTE` для безопасного вызова через Supabase RPC.

## Правила достижений

`recalculate_user_achievements` сейчас поддерживает эти значения `achievements.condition_text`:

- `completed_tasks>=1`: пользователь завершил минимум 1 задание;
- `completed_tasks>=5`: пользователь завершил минимум 5 заданий;
- `attempts>=10`: пользователь отправил минимум 10 попыток;
- `correct_answers>=10`: пользователь дал минимум 10 правильных ответов;
- `correct_answers>=50`: пользователь дал минимум 50 правильных ответов;
- `accuracy>=90_after_20_answers`: пользователь дал минимум 20 ответов и имеет точность не ниже 90%;
- `perfect_attempts>=1`: есть минимум одна попытка с ответами и без ошибок.

Метрики считаются по текущей схеме:

- `task_executions` + `statuses`: завершенные задания (`statuses.name = 'completed'`);
- `attempts`: количество отправленных попыток;
- `question_answers`: количество ответов, правильные ответы и идеальные попытки.

## `recalculate_user_achievements(p_user_id uuid default null)`

Пересчитывает достижения пользователя, выдает новые записи в `user_achievements_link` и создает уведомление для каждого нового достижения.

Возвращает таблицу:

- `achievement_id bigint`;
- `achievement_name text`;
- `received_at timestamptz`;
- `was_new boolean`.

Поведение:

- Если `p_user_id` не передан или передан `null`, пересчитывает достижения текущего пользователя `auth.uid()`.
- Пользователь может пересчитать свои достижения.
- Другого пользователя можно пересчитать только если `public.can_manage_user(p_user_id)` возвращает `true`.
- Функция идемпотентна: повторный вызов не дублирует достижения из-за PK `(user_id, achievement_id)`.
- На пользователя берется transaction-level advisory lock, чтобы параллельные вызовы не создали дублирующие уведомления для одной выдачи.
- Для каждого нового достижения создается уведомление с `notifications.type = 'achievement_awarded'` и связью в `notification_users_link`.

## `create_user_notification(p_user_id uuid, p_type text, p_text text)`

Создает уведомление и связывает его с пользователем.

Возвращает:

- `bigint`: `notifications.id`.

Ограничения безопасности:

- Вызывать может только авторизованный пользователь с ролью `admin` или `teacher`.
- Целевой пользователь должен существовать.
- Целевой пользователь должен быть управляемым для текущего пользователя через `public.can_manage_user(p_user_id)`.
- `p_type` и `p_text` триммятся и обязательны.
- `p_type` ограничен 64 символами, `p_text` ограничен 2000 символами.

## Примеры Flutter

Пересчитать достижения текущего пользователя:

```dart
final rows = await Supabase.instance.client.rpc(
  'recalculate_user_achievements',
);

final achievements = (rows as List<dynamic>)
    .cast<Map<String, dynamic>>();
```

Пересчитать достижения конкретного пользователя, например из админки или teacher-flow:

```dart
final rows = await Supabase.instance.client.rpc(
  'recalculate_user_achievements',
  params: {'p_user_id': userId},
);

final newlyAwarded = (rows as List<dynamic>)
    .cast<Map<String, dynamic>>()
    .where((row) => row['was_new'] == true)
    .toList();
```

Создать уведомление пользователю:

```dart
final notificationId = await Supabase.instance.client.rpc(
  'create_user_notification',
  params: {
    'p_user_id': userId,
    'p_type': 'teacher_message',
    'p_text': 'Проверьте новое задание в группе.',
  },
);
```

Обработку ошибок лучше делать через `try/catch` и показывать пользователю безопасный UI-текст:

```dart
try {
  await Supabase.instance.client.rpc('recalculate_user_achievements');
} on PostgrestException catch (error) {
  // Логируем error.message / error.code, а в UI показываем короткое сообщение.
}
```

## Ожидаемые ошибки

- `Authentication required`: вызов без авторизованного пользователя.
- `User id is required`: не передан целевой пользователь там, где он обязателен.
- `User <id> does not exist`: пользователя нет в `public.users`.
- `Current user cannot recalculate achievements for user <id>`: текущий пользователь не может пересчитать достижения указанного пользователя.
- `Only admin or teacher can create notifications`: роль не может создавать уведомления через публичный RPC.
- `Current user cannot create notifications for user <id>`: целевой пользователь не управляется текущим пользователем.
- `Notification type is required`, `Notification text is required`: пустые поля уведомления.
- `Notification type must be 64 characters or fewer`, `Notification text must be 2000 characters or fewer`: превышены лимиты длины.

## Заметки для развития

- Новые правила можно добавлять через новые значения `achievements.condition_text` и расширение SQL-условий в следующей миграции.
- Если понадобится локализация текстов уведомлений, лучше добавить отдельный `payload`/`metadata` JSONB или хранить message key вместо готового текста.
