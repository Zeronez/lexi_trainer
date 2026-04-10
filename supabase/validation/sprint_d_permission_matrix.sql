-- Sprint D permission matrix validation for Supabase RLS hardening.
-- Run this in a non-production Supabase project after applying migrations.
-- Replace all placeholder IDs in the SETTINGS section with real fixture IDs.

BEGIN;

CREATE TEMP TABLE rls_validation_results (
    scenario TEXT PRIMARY KEY,
    expected_allowed BOOLEAN NOT NULL,
    actual_allowed BOOLEAN NOT NULL,
    detail TEXT
) ON COMMIT DROP;

CREATE OR REPLACE FUNCTION pg_temp.expect_statement_allowed(
    p_scenario TEXT,
    p_expected_allowed BOOLEAN,
    p_sql TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    BEGIN
        EXECUTE p_sql;
        INSERT INTO rls_validation_results (scenario, expected_allowed, actual_allowed, detail)
        VALUES (p_scenario, p_expected_allowed, true, 'statement succeeded');
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO rls_validation_results (scenario, expected_allowed, actual_allowed, detail)
        VALUES (p_scenario, p_expected_allowed, false, SQLSTATE || ': ' || SQLERRM);
    END;
END;
$$;

CREATE OR REPLACE FUNCTION pg_temp.expect_visible(
    p_scenario TEXT,
    p_expected_visible BOOLEAN,
    p_sql TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_visible BOOLEAN;
BEGIN
    BEGIN
        EXECUTE p_sql INTO v_visible;
        INSERT INTO rls_validation_results (scenario, expected_allowed, actual_allowed, detail)
        VALUES (p_scenario, p_expected_visible, COALESCE(v_visible, false), 'visibility=' || COALESCE(v_visible, false)::TEXT);
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO rls_validation_results (scenario, expected_allowed, actual_allowed, detail)
        VALUES (p_scenario, p_expected_visible, false, SQLSTATE || ': ' || SQLERRM);
    END;
END;
$$;

-- SETTINGS: replace values before running.
SELECT set_config('app.admin_user_id', '00000000-0000-0000-0000-000000000001', false);
SELECT set_config('app.teacher_user_id', '00000000-0000-0000-0000-000000000002', false);
SELECT set_config('app.student_a_user_id', '00000000-0000-0000-0000-000000000003', false);
SELECT set_config('app.student_b_user_id', '00000000-0000-0000-0000-000000000004', false);
SELECT set_config('app.student_a_task_id', '2001', false);
SELECT set_config('app.student_a_execution_id', '3001', false);
SELECT set_config('app.student_a_attempt_id', '4001', false);
SELECT set_config('app.student_a_notification_id', '6001', false);
SELECT set_config('app.achievement_id', '7001', false);

SET LOCAL ROLE authenticated;

-- Admin positives.
SELECT set_config('request.jwt.claim.sub', current_setting('app.admin_user_id'), true);
SELECT pg_temp.expect_visible(
    'admin can read any user',
    true,
    'SELECT EXISTS (SELECT 1 FROM public.users WHERE id = ' || quote_literal(current_setting('app.student_b_user_id')) || '::uuid)'
);
SELECT pg_temp.expect_statement_allowed(
    'admin can update any user profile',
    true,
    'UPDATE public.users SET username = username WHERE id = ' || quote_literal(current_setting('app.student_a_user_id')) || '::uuid'
);
SELECT pg_temp.expect_visible(
    'admin can read notifications linked to any user',
    true,
    'SELECT EXISTS (SELECT 1 FROM public.notifications WHERE id = ' || current_setting('app.student_a_notification_id') || ')'
);
SELECT pg_temp.expect_statement_allowed(
    'admin can manually award achievement link',
    true,
    'INSERT INTO public.user_achievements_link (user_id, achievement_id) VALUES ('
      || quote_literal(current_setting('app.student_a_user_id')) || '::uuid, '
      || current_setting('app.achievement_id') || ') ON CONFLICT DO NOTHING'
);

-- Teacher positives for own group student.
SELECT set_config('request.jwt.claim.sub', current_setting('app.teacher_user_id'), true);
SELECT pg_temp.expect_visible(
    'teacher can read own group student profile',
    true,
    'SELECT EXISTS (SELECT 1 FROM public.users WHERE id = ' || quote_literal(current_setting('app.student_a_user_id')) || '::uuid)'
);
SELECT pg_temp.expect_visible(
    'teacher can read own group student notification',
    true,
    'SELECT EXISTS (SELECT 1 FROM public.notifications WHERE id = ' || current_setting('app.student_a_notification_id') || ')'
);
SELECT pg_temp.expect_statement_allowed(
    'teacher can update non-sensitive own group student profile fields',
    true,
    'UPDATE public.users SET username = username WHERE id = ' || quote_literal(current_setting('app.student_a_user_id')) || '::uuid'
);
SELECT pg_temp.expect_statement_allowed(
    'teacher can create notification via RPC for own group student',
    true,
    'SELECT public.create_user_notification('
      || quote_literal(current_setting('app.student_a_user_id')) || '::uuid, ''validation'', ''Validation message'')'
);

-- Teacher negatives outside group or sensitive mutations.
SELECT pg_temp.expect_visible(
    'teacher cannot read other group student profile',
    false,
    'SELECT EXISTS (SELECT 1 FROM public.users WHERE id = ' || quote_literal(current_setting('app.student_b_user_id')) || '::uuid)'
);
SELECT pg_temp.expect_statement_allowed(
    'teacher cannot create notification for other group student',
    false,
    'SELECT public.create_user_notification('
      || quote_literal(current_setting('app.student_b_user_id')) || '::uuid, ''validation'', ''Validation message'')'
);
SELECT pg_temp.expect_statement_allowed(
    'teacher cannot manually insert achievement link',
    false,
    'INSERT INTO public.user_achievements_link (user_id, achievement_id) VALUES ('
      || quote_literal(current_setting('app.student_a_user_id')) || '::uuid, '
      || current_setting('app.achievement_id') || ') ON CONFLICT DO NOTHING'
);
SELECT pg_temp.expect_statement_allowed(
    'teacher cannot directly insert notification row',
    false,
    'INSERT INTO public.notifications (type, text) VALUES (''validation'', ''Direct notification insert'')'
);

-- Student positives for own data and RPC-driven progress.
SELECT set_config('request.jwt.claim.sub', current_setting('app.student_a_user_id'), true);
SELECT pg_temp.expect_visible(
    'student can read self profile',
    true,
    'SELECT EXISTS (SELECT 1 FROM public.users WHERE id = ' || quote_literal(current_setting('app.student_a_user_id')) || '::uuid)'
);
SELECT pg_temp.expect_visible(
    'student can read own notification',
    true,
    'SELECT EXISTS (SELECT 1 FROM public.notifications WHERE id = ' || current_setting('app.student_a_notification_id') || ')'
);
SELECT pg_temp.expect_statement_allowed(
    'student can recalculate own achievements via RPC',
    true,
    'SELECT * FROM public.recalculate_user_achievements(NULL::uuid)'
);
SELECT pg_temp.expect_statement_allowed(
    'student can start readable task via RPC',
    true,
    'SELECT public.start_task_execution(' || current_setting('app.student_a_task_id') || ')'
);

-- Student negatives for peer/private data and direct writes.
SELECT pg_temp.expect_visible(
    'student cannot read peer profile',
    false,
    'SELECT EXISTS (SELECT 1 FROM public.users WHERE id = ' || quote_literal(current_setting('app.student_b_user_id')) || '::uuid)'
);
SELECT pg_temp.expect_statement_allowed(
    'student cannot change own role',
    false,
    'UPDATE public.users SET role_id = role_id + 1 WHERE id = ' || quote_literal(current_setting('app.student_a_user_id')) || '::uuid'
);
SELECT pg_temp.expect_statement_allowed(
    'student cannot change own study group',
    false,
    'UPDATE public.users SET study_group_id = NULL WHERE id = ' || quote_literal(current_setting('app.student_a_user_id')) || '::uuid'
);
SELECT pg_temp.expect_statement_allowed(
    'student cannot directly insert attempt',
    false,
    'INSERT INTO public.attempts (started_at, ended_at, task_execution_id) VALUES (now(), now(), '
      || current_setting('app.student_a_execution_id') || ')'
);
SELECT pg_temp.expect_statement_allowed(
    'student cannot directly insert question answer',
    false,
    'INSERT INTO public.question_answers (entered_answer, is_correct, attempt_id, word_id) VALUES (''x'', false, '
      || current_setting('app.student_a_attempt_id') || ', 1)'
);
SELECT pg_temp.expect_statement_allowed(
    'student cannot create notification via RPC',
    false,
    'SELECT public.create_user_notification('
      || quote_literal(current_setting('app.student_a_user_id')) || '::uuid, ''validation'', ''Validation message'')'
);
SELECT pg_temp.expect_statement_allowed(
    'student cannot manually award achievement link',
    false,
    'INSERT INTO public.user_achievements_link (user_id, achievement_id) VALUES ('
      || quote_literal(current_setting('app.student_a_user_id')) || '::uuid, '
      || current_setting('app.achievement_id') || ') ON CONFLICT DO NOTHING'
);

SELECT *
FROM rls_validation_results
ORDER BY scenario;

SELECT CASE
    WHEN EXISTS (
        SELECT 1
        FROM rls_validation_results
        WHERE expected_allowed <> actual_allowed
    ) THEN 'FAIL: at least one RLS scenario did not match expectation'
    ELSE 'PASS: all RLS scenarios matched expectations'
END AS sprint_d_permission_matrix_result;

ROLLBACK;
