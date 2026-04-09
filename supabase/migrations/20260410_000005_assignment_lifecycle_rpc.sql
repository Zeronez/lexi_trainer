BEGIN;

CREATE OR REPLACE FUNCTION public.start_task_execution(p_task_id BIGINT)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_in_progress_status_id BIGINT;
    v_execution_id BIGINT;
    v_status_name TEXT;
BEGIN
    v_user_id := auth.uid();

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required'
            USING ERRCODE = '28000';
    END IF;

    IF p_task_id IS NULL THEN
        RAISE EXCEPTION 'Task id is required'
            USING ERRCODE = '22004';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id = v_user_id) THEN
        RAISE EXCEPTION 'Current user profile does not exist'
            USING ERRCODE = 'P0001';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.tasks t WHERE t.id = p_task_id) THEN
        RAISE EXCEPTION 'Task % does not exist', p_task_id
            USING ERRCODE = 'P0002';
    END IF;

    IF NOT public.can_read_task(p_task_id) THEN
        RAISE EXCEPTION 'Task % is not available for current user', p_task_id
            USING ERRCODE = '42501';
    END IF;

    SELECT s.id
    INTO v_in_progress_status_id
    FROM public.statuses s
    WHERE s.name = 'in_progress';

    IF v_in_progress_status_id IS NULL THEN
        RAISE EXCEPTION 'Status in_progress does not exist'
            USING ERRCODE = 'P0001';
    END IF;

    PERFORM pg_advisory_xact_lock(
        hashtextextended('assignment_lifecycle:start:' || p_task_id::TEXT || ':' || v_user_id::TEXT, 0)
    );

    SELECT te.id, s.name
    INTO v_execution_id, v_status_name
    FROM public.task_executions te
    JOIN public.statuses s ON s.id = te.status_id
    WHERE te.task_id = p_task_id
      AND te.user_id = v_user_id
    ORDER BY
        CASE
            WHEN s.name IN ('assigned', 'in_progress') THEN 0
            WHEN s.name = 'completed' THEN 2
            ELSE 1
        END,
        te.id
    LIMIT 1
    FOR UPDATE OF te;

    IF v_execution_id IS NOT NULL THEN
        IF v_status_name = 'completed' THEN
            RAISE EXCEPTION 'Task execution % is already completed', v_execution_id
                USING ERRCODE = 'P0001';
        END IF;

        IF v_status_name <> 'in_progress' THEN
            UPDATE public.task_executions
            SET status_id = v_in_progress_status_id
            WHERE id = v_execution_id;
        END IF;

        RETURN v_execution_id;
    END IF;

    INSERT INTO public.task_executions (status_id, user_id, task_id)
    VALUES (v_in_progress_status_id, v_user_id, p_task_id)
    RETURNING id INTO v_execution_id;

    RETURN v_execution_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.submit_attempt(
    p_task_execution_id BIGINT,
    p_started_at TIMESTAMPTZ,
    p_ended_at TIMESTAMPTZ
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_task_id BIGINT;
    v_attempts_limit INTEGER;
    v_attempts_used INTEGER;
    v_status_name TEXT;
    v_attempt_id BIGINT;
BEGIN
    v_user_id := auth.uid();

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required'
            USING ERRCODE = '28000';
    END IF;

    IF p_task_execution_id IS NULL THEN
        RAISE EXCEPTION 'Task execution id is required'
            USING ERRCODE = '22004';
    END IF;

    IF p_started_at IS NULL THEN
        RAISE EXCEPTION 'Attempt started_at is required'
            USING ERRCODE = '22004';
    END IF;

    IF p_ended_at IS NULL THEN
        RAISE EXCEPTION 'Attempt ended_at is required'
            USING ERRCODE = '22004';
    END IF;

    IF p_ended_at < p_started_at THEN
        RAISE EXCEPTION 'Attempt ended_at must be greater than or equal to started_at'
            USING ERRCODE = '22007';
    END IF;

    SELECT te.task_id, t.attempts_count, s.name
    INTO v_task_id, v_attempts_limit, v_status_name
    FROM public.task_executions te
    JOIN public.tasks t ON t.id = te.task_id
    JOIN public.statuses s ON s.id = te.status_id
    WHERE te.id = p_task_execution_id
    FOR UPDATE OF te;

    IF v_task_id IS NULL THEN
        RAISE EXCEPTION 'Task execution % does not exist', p_task_execution_id
            USING ERRCODE = 'P0002';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.task_executions te
        WHERE te.id = p_task_execution_id
          AND te.user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'Task execution % does not belong to current user', p_task_execution_id
            USING ERRCODE = '42501';
    END IF;

    IF v_status_name <> 'in_progress' THEN
        RAISE EXCEPTION 'Task execution % must be in_progress to submit an attempt', p_task_execution_id
            USING ERRCODE = 'P0001';
    END IF;

    SELECT COUNT(*)::INTEGER
    INTO v_attempts_used
    FROM public.attempts a
    WHERE a.task_execution_id = p_task_execution_id;

    IF v_attempts_used >= v_attempts_limit THEN
        RAISE EXCEPTION 'Attempts limit exceeded for task execution %', p_task_execution_id
            USING ERRCODE = 'P0001';
    END IF;

    INSERT INTO public.attempts (started_at, ended_at, task_execution_id)
    VALUES (p_started_at, p_ended_at, p_task_execution_id)
    RETURNING id INTO v_attempt_id;

    RETURN v_attempt_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.submit_question_answer(
    p_attempt_id BIGINT,
    p_word_id BIGINT,
    p_entered_answer TEXT,
    p_is_correct BOOLEAN
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_task_execution_id BIGINT;
    v_task_id BIGINT;
    v_vocabulary_set_id BIGINT;
    v_status_name TEXT;
    v_answer_id BIGINT;
BEGIN
    v_user_id := auth.uid();

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required'
            USING ERRCODE = '28000';
    END IF;

    IF p_attempt_id IS NULL THEN
        RAISE EXCEPTION 'Attempt id is required'
            USING ERRCODE = '22004';
    END IF;

    IF p_word_id IS NULL THEN
        RAISE EXCEPTION 'Word id is required'
            USING ERRCODE = '22004';
    END IF;

    IF p_entered_answer IS NULL THEN
        RAISE EXCEPTION 'Entered answer is required'
            USING ERRCODE = '22004';
    END IF;

    IF p_is_correct IS NULL THEN
        RAISE EXCEPTION 'Answer correctness flag is required'
            USING ERRCODE = '22004';
    END IF;

    SELECT a.task_execution_id, te.task_id, t.vocabulary_set_id, s.name
    INTO v_task_execution_id, v_task_id, v_vocabulary_set_id, v_status_name
    FROM public.attempts a
    JOIN public.task_executions te ON te.id = a.task_execution_id
    JOIN public.tasks t ON t.id = te.task_id
    JOIN public.statuses s ON s.id = te.status_id
    WHERE a.id = p_attempt_id
    FOR UPDATE OF a, te;

    IF v_task_execution_id IS NULL THEN
        RAISE EXCEPTION 'Attempt % does not exist', p_attempt_id
            USING ERRCODE = 'P0002';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.task_executions te
        WHERE te.id = v_task_execution_id
          AND te.user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'Attempt % does not belong to current user', p_attempt_id
            USING ERRCODE = '42501';
    END IF;

    IF v_status_name <> 'in_progress' THEN
        RAISE EXCEPTION 'Task execution % must be in_progress to submit answers', v_task_execution_id
            USING ERRCODE = 'P0001';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.set_words_link swl
        WHERE swl.vocabulary_set_id = v_vocabulary_set_id
          AND swl.word_id = p_word_id
    ) THEN
        RAISE EXCEPTION 'Word % is not part of task % vocabulary set', p_word_id, v_task_id
            USING ERRCODE = 'P0002';
    END IF;

    SELECT qa.id
    INTO v_answer_id
    FROM public.question_answers qa
    WHERE qa.attempt_id = p_attempt_id
      AND qa.word_id = p_word_id
    ORDER BY qa.id
    LIMIT 1
    FOR UPDATE;

    IF v_answer_id IS NOT NULL THEN
        UPDATE public.question_answers
        SET entered_answer = p_entered_answer,
            is_correct = p_is_correct
        WHERE id = v_answer_id;

        RETURN v_answer_id;
    END IF;

    INSERT INTO public.question_answers (entered_answer, is_correct, attempt_id, word_id)
    VALUES (p_entered_answer, p_is_correct, p_attempt_id, p_word_id)
    RETURNING id INTO v_answer_id;

    RETURN v_answer_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.complete_task_execution(p_task_execution_id BIGINT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_task_id BIGINT;
    v_status_name TEXT;
    v_completed_status_id BIGINT;
BEGIN
    v_user_id := auth.uid();

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required'
            USING ERRCODE = '28000';
    END IF;

    IF p_task_execution_id IS NULL THEN
        RAISE EXCEPTION 'Task execution id is required'
            USING ERRCODE = '22004';
    END IF;

    SELECT te.task_id, s.name
    INTO v_task_id, v_status_name
    FROM public.task_executions te
    JOIN public.statuses s ON s.id = te.status_id
    WHERE te.id = p_task_execution_id
      AND te.user_id = v_user_id
    FOR UPDATE OF te;

    IF v_task_id IS NULL THEN
        IF EXISTS (SELECT 1 FROM public.task_executions te WHERE te.id = p_task_execution_id) THEN
            RAISE EXCEPTION 'Task execution % does not belong to current user', p_task_execution_id
                USING ERRCODE = '42501';
        END IF;

        RAISE EXCEPTION 'Task execution % does not exist', p_task_execution_id
            USING ERRCODE = 'P0002';
    END IF;

    IF v_status_name = 'completed' THEN
        RETURN;
    END IF;

    IF v_status_name <> 'in_progress' THEN
        RAISE EXCEPTION 'Task execution % must be in_progress to complete', p_task_execution_id
            USING ERRCODE = 'P0001';
    END IF;

    SELECT s.id
    INTO v_completed_status_id
    FROM public.statuses s
    WHERE s.name = 'completed';

    IF v_completed_status_id IS NULL THEN
        RAISE EXCEPTION 'Status completed does not exist'
            USING ERRCODE = 'P0001';
    END IF;

    UPDATE public.task_executions
    SET status_id = v_completed_status_id
    WHERE id = p_task_execution_id;
END;
$$;

REVOKE ALL ON FUNCTION public.start_task_execution(BIGINT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.submit_attempt(BIGINT, TIMESTAMPTZ, TIMESTAMPTZ) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.submit_question_answer(BIGINT, BIGINT, TEXT, BOOLEAN) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.complete_task_execution(BIGINT) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.start_task_execution(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_attempt(BIGINT, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_question_answer(BIGINT, BIGINT, TEXT, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION public.complete_task_execution(BIGINT) TO authenticated;

COMMIT;
