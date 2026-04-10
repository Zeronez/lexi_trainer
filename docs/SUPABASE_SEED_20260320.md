# Supabase Seed Pack (2026-03-20)

Файл: `supabase/seeds/20260320_full_seed.sql`

Назначение: быстро наполнить проект тестовыми данными для ручной проверки MVP/production flow.

## Что заполняется

Скрипт добавляет/обновляет данные в диапазоне 6-24 записей по ключевым таблицам:

- `study_groups`: 6
- `words`: 24
- `vocabulary_sets`: 8
- `set_words_link`: 24
- `tasks`: 12
- `task_executions`: 12
- `attempts`: 18
- `question_answers`: 24
- `notifications`: 10
- `notification_users_link`: 10
- `achievements`: 8
- `user_achievements_link`: 12

Дополнительно скрипт нормализует первые 8 записей в `public.users` (роль/группа/registered_at) для стабильных тестовых сценариев.

## Важные условия

1. В `public.users` должно быть минимум 6 пользователей (уже связанных с `auth.users`).
2. Базовые миграции и сид ролей/статусов должны быть применены.
3. Все даты создания/отправки в сиде выставлены на `2026-03-20` (UTC).

## Как применить

В Supabase SQL Editor:

1. Откройте файл `supabase/seeds/20260320_full_seed.sql`.
2. Выполните целиком.

Через `psql`:

```bash
psql "$SUPABASE_DB_URL" -f supabase/seeds/20260320_full_seed.sql
```

## Проверка после применения

```sql
select count(*) from public.study_groups where id between 18001 and 18006;
select count(*) from public.words where id between 19001 and 19024;
select count(*) from public.tasks where id between 21001 and 21012;
select count(*) from public.notifications where id between 26001 and 26010;
```

## Примечания

- Сид идемпотентен в пределах выделенных диапазонов id: старые сид-данные в этих диапазонах удаляются и пересоздаются.
- Скрипт не модифицирует `auth.users` напрямую.
