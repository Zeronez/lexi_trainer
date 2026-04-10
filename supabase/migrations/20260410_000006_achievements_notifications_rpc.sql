BEGIN;

INSERT INTO public.achievements (name, description, condition_text)
SELECT seed.name, seed.description, seed.condition_text
FROM (
    VALUES
        ('Первое задание', 'Завершите первое учебное задание.', 'completed_tasks>=1'),
        ('Пять заданий', 'Завершите пять учебных заданий.', 'completed_tasks>=5'),
        ('Десять попыток', 'Отправьте десять попыток по заданиям.', 'attempts>=10'),
        ('Первые 10 правильных ответов', 'Дайте 10 правильных ответов.', 'correct_answers>=10'),
        ('50 правильных ответов', 'Дайте 50 правильных ответов.', 'correct_answers>=50'),
        ('Точность 90%', 'Достигните точности 90% минимум после 20 ответов.', 'accuracy>=90_after_20_answers'),
        ('Идеальная попытка', 'Завершите попытку без ошибок.', 'perfect_attempts>=1')
) AS seed(name, description, condition_text)
WHERE NOT EXISTS (
    SELECT 1
    FROM public.achievements a
    WHERE a.condition_text = seed.condition_text
);

CREATE OR REPLACE FUNCTION public.recalculate_user_achievements(p_user_id UUID DEFAULT NULL)
RETURNS TABLE (
    achievement_id BIGINT,
    achievement_name TEXT,
    received_at TIMESTAMPTZ,
    was_new BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_actor_id UUID;
    v_target_user_id UUID;
    v_new_achievement_ids BIGINT[] := ARRAY[]::BIGINT[];
    v_achievement RECORD;
    v_notification_id BIGINT;
BEGIN
    v_actor_id := auth.uid();
    v_target_user_id := COALESCE(p_user_id, v_actor_id);

    IF v_actor_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required'
            USING ERRCODE = '28000';
    END IF;

    IF v_target_user_id IS NULL THEN
        RAISE EXCEPTION 'User id is required'
            USING ERRCODE = '22004';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id = v_target_user_id) THEN
        RAISE EXCEPTION 'User % does not exist', v_target_user_id
            USING ERRCODE = 'P0002';
    END IF;

    IF v_target_user_id <> v_actor_id
       AND NOT public.can_manage_user(v_target_user_id) THEN
        RAISE EXCEPTION 'Current user cannot recalculate achievements for user %', v_target_user_id
            USING ERRCODE = '42501';
    END IF;

    PERFORM pg_advisory_xact_lock(
        hashtextextended('achievements:recalculate:' || v_target_user_id::TEXT, 0)
    );

    WITH progress AS (
        SELECT
            COUNT(DISTINCT te.id) FILTER (WHERE s.name = 'completed')::INTEGER AS completed_tasks,
            COUNT(DISTINCT a.id)::INTEGER AS attempts_count,
            COUNT(qa.id)::INTEGER AS answers_count,
            COUNT(qa.id) FILTER (WHERE qa.is_correct)::INTEGER AS correct_answers,
            COUNT(DISTINCT a.id) FILTER (
                WHERE EXISTS (
                    SELECT 1
                    FROM public.question_answers qa_any
                    WHERE qa_any.attempt_id = a.id
                )
                AND NOT EXISTS (
                    SELECT 1
                    FROM public.question_answers qa_wrong
                    WHERE qa_wrong.attempt_id = a.id
                      AND qa_wrong.is_correct = false
                )
            )::INTEGER AS perfect_attempts
        FROM public.task_executions te
        JOIN public.statuses s ON s.id = te.status_id
        LEFT JOIN public.attempts a ON a.task_execution_id = te.id
        LEFT JOIN public.question_answers qa ON qa.attempt_id = a.id
        WHERE te.user_id = v_target_user_id
    ),
    eligible AS (
        SELECT ach.id
        FROM public.achievements ach
        CROSS JOIN progress p
        WHERE (ach.condition_text = 'completed_tasks>=1' AND p.completed_tasks >= 1)
           OR (ach.condition_text = 'completed_tasks>=5' AND p.completed_tasks >= 5)
           OR (ach.condition_text = 'attempts>=10' AND p.attempts_count >= 10)
           OR (ach.condition_text = 'correct_answers>=10' AND p.correct_answers >= 10)
           OR (ach.condition_text = 'correct_answers>=50' AND p.correct_answers >= 50)
           OR (
               ach.condition_text = 'accuracy>=90_after_20_answers'
               AND p.answers_count >= 20
               AND (p.correct_answers::NUMERIC / NULLIF(p.answers_count, 0)) >= 0.9
           )
           OR (ach.condition_text = 'perfect_attempts>=1' AND p.perfect_attempts >= 1)
    ),
    inserted AS (
        INSERT INTO public.user_achievements_link (user_id, achievement_id, received_at)
        SELECT v_target_user_id, eligible.id, now()
        FROM eligible
        ON CONFLICT (user_id, achievement_id) DO NOTHING
        RETURNING user_achievements_link.achievement_id
    )
    SELECT COALESCE(array_agg(inserted.achievement_id), ARRAY[]::BIGINT[])
    INTO v_new_achievement_ids
    FROM inserted;

    FOR v_achievement IN
        SELECT a.id, a.name
        FROM public.achievements a
        WHERE a.id = ANY(v_new_achievement_ids)
        ORDER BY a.id
    LOOP
        INSERT INTO public.notifications (type, text)
        VALUES ('achievement_awarded', 'Получено достижение: ' || v_achievement.name)
        RETURNING id INTO v_notification_id;

        INSERT INTO public.notification_users_link (notification_id, user_id)
        VALUES (v_notification_id, v_target_user_id)
        ON CONFLICT (notification_id, user_id) DO NOTHING;
    END LOOP;

    RETURN QUERY
    WITH progress AS (
        SELECT
            COUNT(DISTINCT te.id) FILTER (WHERE s.name = 'completed')::INTEGER AS completed_tasks,
            COUNT(DISTINCT a.id)::INTEGER AS attempts_count,
            COUNT(qa.id)::INTEGER AS answers_count,
            COUNT(qa.id) FILTER (WHERE qa.is_correct)::INTEGER AS correct_answers,
            COUNT(DISTINCT a.id) FILTER (
                WHERE EXISTS (
                    SELECT 1
                    FROM public.question_answers qa_any
                    WHERE qa_any.attempt_id = a.id
                )
                AND NOT EXISTS (
                    SELECT 1
                    FROM public.question_answers qa_wrong
                    WHERE qa_wrong.attempt_id = a.id
                      AND qa_wrong.is_correct = false
                )
            )::INTEGER AS perfect_attempts
        FROM public.task_executions te
        JOIN public.statuses s ON s.id = te.status_id
        LEFT JOIN public.attempts a ON a.task_execution_id = te.id
        LEFT JOIN public.question_answers qa ON qa.attempt_id = a.id
        WHERE te.user_id = v_target_user_id
    ),
    eligible AS (
        SELECT ach.id
        FROM public.achievements ach
        CROSS JOIN progress p
        WHERE (ach.condition_text = 'completed_tasks>=1' AND p.completed_tasks >= 1)
           OR (ach.condition_text = 'completed_tasks>=5' AND p.completed_tasks >= 5)
           OR (ach.condition_text = 'attempts>=10' AND p.attempts_count >= 10)
           OR (ach.condition_text = 'correct_answers>=10' AND p.correct_answers >= 10)
           OR (ach.condition_text = 'correct_answers>=50' AND p.correct_answers >= 50)
           OR (
               ach.condition_text = 'accuracy>=90_after_20_answers'
               AND p.answers_count >= 20
               AND (p.correct_answers::NUMERIC / NULLIF(p.answers_count, 0)) >= 0.9
           )
           OR (ach.condition_text = 'perfect_attempts>=1' AND p.perfect_attempts >= 1)
    )
    SELECT
        a.id AS achievement_id,
        a.name AS achievement_name,
        ual.received_at,
        a.id = ANY(v_new_achievement_ids) AS was_new
    FROM eligible e
    JOIN public.achievements a ON a.id = e.id
    JOIN public.user_achievements_link ual
      ON ual.achievement_id = a.id
     AND ual.user_id = v_target_user_id
    ORDER BY ual.received_at, a.id;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_user_notification(
    p_user_id UUID,
    p_type TEXT,
    p_text TEXT
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_actor_id UUID;
    v_notification_id BIGINT;
    v_type TEXT;
    v_text TEXT;
BEGIN
    v_actor_id := auth.uid();
    v_type := NULLIF(btrim(p_type), '');
    v_text := NULLIF(btrim(p_text), '');

    IF v_actor_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required'
            USING ERRCODE = '28000';
    END IF;

    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'User id is required'
            USING ERRCODE = '22004';
    END IF;

    IF v_type IS NULL THEN
        RAISE EXCEPTION 'Notification type is required'
            USING ERRCODE = '22004';
    END IF;

    IF v_text IS NULL THEN
        RAISE EXCEPTION 'Notification text is required'
            USING ERRCODE = '22004';
    END IF;

    IF char_length(v_type) > 64 THEN
        RAISE EXCEPTION 'Notification type must be 64 characters or fewer'
            USING ERRCODE = '22001';
    END IF;

    IF char_length(v_text) > 2000 THEN
        RAISE EXCEPTION 'Notification text must be 2000 characters or fewer'
            USING ERRCODE = '22001';
    END IF;

    IF COALESCE(public.current_user_role() NOT IN ('admin', 'teacher'), true) THEN
        RAISE EXCEPTION 'Only admin or teacher can create notifications'
            USING ERRCODE = '42501';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id = p_user_id) THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id
            USING ERRCODE = 'P0002';
    END IF;

    IF NOT public.can_manage_user(p_user_id) THEN
        RAISE EXCEPTION 'Current user cannot create notifications for user %', p_user_id
            USING ERRCODE = '42501';
    END IF;

    INSERT INTO public.notifications (type, text)
    VALUES (v_type, v_text)
    RETURNING id INTO v_notification_id;

    INSERT INTO public.notification_users_link (notification_id, user_id)
    VALUES (v_notification_id, p_user_id)
    ON CONFLICT (notification_id, user_id) DO NOTHING;

    RETURN v_notification_id;
END;
$$;

REVOKE ALL ON FUNCTION public.recalculate_user_achievements(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_user_notification(UUID, TEXT, TEXT) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.recalculate_user_achievements(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_user_notification(UUID, TEXT, TEXT) TO authenticated;

COMMIT;

