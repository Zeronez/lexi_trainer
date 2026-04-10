-- Sprint E post-release smoke checks for Supabase.
-- Safe read-only script: no DDL, DML, RPC calls with writes, or destructive statements.
-- Run after migrations are applied. Expected result: review all result sets for missing rows or non-zero issue counts.

-- 1) Applied migration inventory.
select version, name, inserted_at
from supabase_migrations.schema_migrations
order by version;

-- 2) Required RPC/helper functions exist.
with expected(function_name, argument_types) as (
    values
        ('start_task_execution', 'bigint'),
        ('submit_attempt', 'bigint, timestamp with time zone, timestamp with time zone'),
        ('submit_question_answer', 'bigint, bigint, text, boolean'),
        ('complete_task_execution', 'bigint'),
        ('recalculate_user_achievements', 'uuid'),
        ('create_user_notification', 'uuid, text, text'),
        ('can_read_private_user_data', 'uuid'),
        ('can_manage_user_as_staff', 'uuid'),
        ('can_read_task_execution', 'bigint')
)
select
    e.function_name,
    e.argument_types,
    p.oid is not null as exists
from expected e
left join (
    select p.proname, oidvectortypes(p.proargtypes) as argument_types, p.oid
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
) p
  on p.proname = e.function_name
 and p.argument_types = e.argument_types
order by e.function_name;

-- 3) Critical policies exist.
with expected(tablename, policyname) as (
    values
        ('users', 'users_select_private'),
        ('users', 'users_insert_admin'),
        ('users', 'users_update_self_profile'),
        ('users', 'users_update_staff'),
        ('study_groups', 'study_groups_select_own_or_admin'),
        ('study_groups', 'study_groups_manage_admin'),
        ('vocabulary_sets', 'vocabulary_sets_select_group'),
        ('vocabulary_sets', 'vocabulary_sets_insert_staff'),
        ('vocabulary_sets', 'vocabulary_sets_update_staff'),
        ('vocabulary_sets', 'vocabulary_sets_delete_staff'),
        ('tasks', 'tasks_select_group'),
        ('tasks', 'tasks_insert_staff'),
        ('tasks', 'tasks_update_staff'),
        ('tasks', 'tasks_delete_staff'),
        ('task_executions', 'task_executions_select_group'),
        ('task_executions', 'task_executions_insert_staff'),
        ('task_executions', 'task_executions_update_staff'),
        ('task_executions', 'task_executions_delete_staff'),
        ('attempts', 'attempts_select_group'),
        ('attempts', 'attempts_insert_staff'),
        ('attempts', 'attempts_update_staff'),
        ('attempts', 'attempts_delete_staff'),
        ('question_answers', 'question_answers_select_group'),
        ('question_answers', 'question_answers_insert_staff'),
        ('question_answers', 'question_answers_update_staff'),
        ('question_answers', 'question_answers_delete_staff'),
        ('notifications', 'notifications_select_private'),
        ('notifications', 'notifications_insert_admin'),
        ('notification_users_link', 'notification_users_link_select_private'),
        ('notification_users_link', 'notification_users_link_insert_admin'),
        ('achievements', 'achievements_read_authenticated'),
        ('achievements', 'achievements_manage_admin'),
        ('user_achievements_link', 'user_achievements_link_select_private'),
        ('user_achievements_link', 'user_achievements_link_insert_admin')
)
select
    e.tablename,
    e.policyname,
    p.policyname is not null as exists
from expected e
left join pg_policies p
  on p.schemaname = 'public'
 and p.tablename = e.tablename
 and p.policyname = e.policyname
order by e.tablename, e.policyname;

-- 4) Critical tables have RLS enabled.
select
    c.relname as table_name,
    c.relrowsecurity as rls_enabled,
    c.relforcerowsecurity as force_rls_enabled
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in (
    'users',
    'study_groups',
    'vocabulary_sets',
    'tasks',
    'task_executions',
    'attempts',
    'question_answers',
    'notifications',
    'notification_users_link',
    'achievements',
    'user_achievements_link'
  )
order by c.relname;

-- 5) Integrity constraints exist. Some may be NOT VALID by design until old data is cleaned.
with expected(conname) as (
    values
        ('tasks_dates_order_chk'),
        ('attempts_time_order_chk'),
        ('notifications_type_not_blank_chk'),
        ('notifications_text_not_blank_chk'),
        ('achievements_name_not_blank_chk'),
        ('achievements_condition_not_blank_chk')
)
select
    e.conname,
    c.conrelid::regclass as table_name,
    c.convalidated,
    c.oid is not null as exists
from expected e
left join pg_constraint c on c.conname = e.conname
order by e.conname;

-- 6) Optional duplicate-prevention indexes. Missing rows mean existing duplicate data blocked creation.
with expected(indexname) as (
    values
        ('idx_task_executions_user_task_unique'),
        ('idx_question_answers_attempt_word_unique'),
        ('idx_achievements_condition_text_unique')
)
select
    e.indexname,
    i.tablename,
    i.indexname is not null as exists
from expected e
left join pg_indexes i
  on i.schemaname = 'public'
 and i.indexname = e.indexname
order by e.indexname;

-- 7) Basic table counts for release sanity.
select 'users' as table_name, count(*) as row_count from public.users
union all select 'study_groups', count(*) from public.study_groups
union all select 'vocabulary_sets', count(*) from public.vocabulary_sets
union all select 'tasks', count(*) from public.tasks
union all select 'task_executions', count(*) from public.task_executions
union all select 'attempts', count(*) from public.attempts
union all select 'question_answers', count(*) from public.question_answers
union all select 'notifications', count(*) from public.notifications
union all select 'notification_users_link', count(*) from public.notification_users_link
union all select 'achievements', count(*) from public.achievements
union all select 'user_achievements_link', count(*) from public.user_achievements_link
order by table_name;

-- 8) Data issue counts. Expected value is 0 for each row.
select 'duplicate_task_executions_user_task' as check_name, count(*) as issue_count
from (
    select user_id, task_id
    from public.task_executions
    group by user_id, task_id
    having count(*) > 1
) issues
union all
select 'duplicate_question_answers_attempt_word', count(*)
from (
    select attempt_id, word_id
    from public.question_answers
    group by attempt_id, word_id
    having count(*) > 1
) issues
union all
select 'duplicate_achievements_condition_text', count(*)
from (
    select condition_text
    from public.achievements
    group by condition_text
    having count(*) > 1
) issues
union all
select 'invalid_task_date_order', count(*)
from public.tasks
where deadline is not null
  and start_date is not null
  and deadline < start_date
union all
select 'invalid_attempt_time_order', count(*)
from public.attempts
where ended_at is not null
  and ended_at < started_at
union all
select 'invalid_notifications', count(*)
from public.notifications
where btrim(type) = ''
   or char_length(type) > 64
   or btrim(text) = ''
   or char_length(text) > 2000
union all
select 'invalid_achievements', count(*)
from public.achievements
where btrim(name) = ''
   or btrim(condition_text) = ''
order by check_name;
