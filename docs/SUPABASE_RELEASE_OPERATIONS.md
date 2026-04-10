# Supabase Release Operations

Production release checklist for Lexi Trainer Supabase changes.

## Pre-Release DB Checks

Run against staging first, then production before applying new migrations:

```sql
-- Confirm expected migrations are already present in filename order.
select version, name, inserted_at
from supabase_migrations.schema_migrations
order by version;

-- Check duplicate-prone data before Sprint D hardening unique indexes.
select user_id, task_id, count(*)
from public.task_executions
group by user_id, task_id
having count(*) > 1;

select attempt_id, word_id, count(*)
from public.question_answers
group by attempt_id, word_id
having count(*) > 1;

select condition_text, count(*)
from public.achievements
group by condition_text
having count(*) > 1;

-- Check data that would violate new integrity constraints.
select id, start_date, deadline
from public.tasks
where deadline is not null
  and start_date is not null
  and deadline < start_date;

select id, started_at, ended_at
from public.attempts
where ended_at is not null
  and ended_at < started_at;

select id, type, text
from public.notifications
where btrim(type) = ''
   or char_length(type) > 64
   or btrim(text) = ''
   or char_length(text) > 2000;

select id, name, condition_text
from public.achievements
where btrim(name) = ''
   or btrim(condition_text) = '';
```

If any query returns rows, decide whether to clean data in a forward migration or accept `NOT VALID` constraints / skipped optional indexes until cleanup is complete.

## Migration Apply Order

Apply migrations strictly by filename order. Current expected sequence is documented in `docs/SUPABASE_MIGRATION_ORDER.md`.

Recommended release flow:

1. Apply to a disposable/staging Supabase project.
2. Run `supabase/validation/sprint_d_permission_matrix.sql` with fixture ids replaced.
3. Apply to production during a quiet window.
4. Capture migration logs and warnings, especially skipped optional unique indexes.
5. Run post-release smoke checks below.

## Rollback Strategy

Do not use destructive resets in production. Avoid `supabase db reset`, dropping schemas, or force-restoring over live data unless this is an approved disaster-recovery event.

Safe rollback approach:

1. Stop or pause the app rollout first if the issue is app-triggered.
2. Identify the exact migration that introduced the regression.
3. Prefer a new forward-fix migration that restores safe behavior instead of editing an already-applied migration.
4. For policy regressions, create a new migration that replaces the affected RLS policies/functions with the previous known-good definitions.
5. For constraint/index regressions, create a new migration that drops only the specific new constraint/index by name, after confirming the impact.
6. For data changes, write targeted compensating SQL with explicit `where` clauses and a dry-run `select` preview.
7. Record the rollback/fix migration in release notes and re-run smoke checks.

Examples of targeted rollback primitives:

```sql
-- Example only: drop one problematic optional index.
drop index if exists public.idx_question_answers_attempt_word_unique;

-- Example only: remove one specific constraint if it blocks valid production data.
alter table public.tasks drop constraint if exists tasks_dates_order_chk;

-- Example only: replace a policy in a forward migration.
drop policy if exists users_select_private on public.users;
create policy users_select_private on public.users
for select to authenticated
using (public.can_read_private_user_data(id));
```

## Post-Release Smoke SQL Checks

Run after production migration completes:

```sql
-- Confirm hardening functions exist.
select proname
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and proname in (
    'can_read_private_user_data',
    'can_manage_user_as_staff',
    'can_read_task_execution',
    'recalculate_user_achievements',
    'create_user_notification'
  )
order by proname;

-- Confirm critical policies are present.
select schemaname, tablename, policyname, cmd
from pg_policies
where schemaname = 'public'
  and tablename in (
    'users',
    'task_executions',
    'attempts',
    'question_answers',
    'notifications',
    'user_achievements_link'
  )
order by tablename, policyname;

-- Confirm constraints were created.
select conrelid::regclass as table_name, conname, convalidated
from pg_constraint
where conname in (
    'tasks_dates_order_chk',
    'attempts_time_order_chk',
    'notifications_type_not_blank_chk',
    'notifications_text_not_blank_chk',
    'achievements_name_not_blank_chk',
    'achievements_condition_not_blank_chk'
  )
order by table_name::text, conname;

-- Confirm optional unique indexes if source data allowed them.
select schemaname, tablename, indexname
from pg_indexes
where schemaname = 'public'
  and indexname in (
    'idx_task_executions_user_task_unique',
    'idx_question_answers_attempt_word_unique',
    'idx_achievements_condition_text_unique'
  )
order by tablename, indexname;

-- Basic RPC smoke with an authenticated test user in staging only.
-- In production, run only if a safe internal test account exists.
select * from public.recalculate_user_achievements(null::uuid);
```

## Operational Notes

- Never commit Supabase secrets. Use runtime environment variables and GitHub secrets only.
- Keep SQL Editor manual fixes as small forward migrations when possible, so staging and production remain reproducible.
- If a migration emits `WARNING` about skipped optional indexes, create a follow-up cleanup ticket before relying on uniqueness at the database level.
