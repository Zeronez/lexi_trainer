BEGIN;

-- RLS validation scenarios for Lexi Trainer
-- Run in Supabase SQL Editor with service-role privileges.
-- Before running:
-- 1) Replace placeholders below with real UUID/BIGINT values from your project.
-- 2) Ensure referenced users/groups/tasks already exist.

SELECT set_config('app.student_a_id', '00000000-0000-0000-0000-000000000001', false);
SELECT set_config('app.student_b_id', '00000000-0000-0000-0000-000000000002', false);
SELECT set_config('app.teacher_a_id', '00000000-0000-0000-0000-000000000003', false);
SELECT set_config('app.group_a_id', '1', false);
SELECT set_config('app.group_b_id', '2', false);
SELECT set_config('app.task_a_id', '1', false);

CREATE OR REPLACE FUNCTION public.assert_true(condition boolean, message text)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT condition THEN
    RAISE EXCEPTION '%', message;
  END IF;
END;
$$;

-- Scenario 1: student A can read own profile
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', current_setting('app.student_a_id'), true);
SELECT public.assert_true(
  EXISTS (
    SELECT 1 FROM public.users WHERE id = current_setting('app.student_a_id')::uuid
  ),
  'RLS failed: student A cannot read own profile'
);

-- Scenario 2: student A cannot read student B from another group
SELECT public.assert_true(
  NOT EXISTS (
    SELECT 1 FROM public.users WHERE id = current_setting('app.student_b_id')::uuid
  ),
  'RLS failed: student A can read student B from another group'
);

-- Scenario 3: teacher can read profiles from own group only
SELECT set_config('request.jwt.claim.sub', current_setting('app.teacher_a_id'), true);
SELECT public.assert_true(
  EXISTS (
    SELECT 1
    FROM public.users
    WHERE study_group_id = current_setting('app.group_a_id')::bigint
    LIMIT 1
  ),
  'RLS failed: teacher cannot read own group'
);

SELECT public.assert_true(
  NOT EXISTS (
    SELECT 1
    FROM public.users
    WHERE study_group_id = current_setting('app.group_b_id')::bigint
    LIMIT 1
  ),
  'RLS failed: teacher can read foreign group'
);

-- Scenario 4: student can read own task execution by task id
SELECT set_config('request.jwt.claim.sub', current_setting('app.student_a_id'), true);
SELECT public.assert_true(
  EXISTS (
    SELECT 1
    FROM public.task_executions
    WHERE user_id = current_setting('app.student_a_id')::uuid
      AND task_id = current_setting('app.task_a_id')::bigint
  ),
  'RLS failed: student cannot read own task execution'
);

RESET ROLE;
ROLLBACK;
