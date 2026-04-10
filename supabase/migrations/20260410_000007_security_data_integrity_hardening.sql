BEGIN;

CREATE OR REPLACE FUNCTION public.is_current_user_teacher()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT COALESCE(public.current_user_role() = 'teacher', false);
$$;

CREATE OR REPLACE FUNCTION public.can_read_private_user_data(target_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT COALESCE(
        public.is_current_user_admin()
        OR target_user_id = auth.uid()
        OR (
            public.current_user_role() = 'teacher'
            AND EXISTS (
                SELECT 1
                FROM public.users target_user
                WHERE target_user.id = target_user_id
                  AND target_user.study_group_id IS NOT NULL
                  AND target_user.study_group_id = public.current_user_group_id()
            )
        ),
        false
    );
$$;

CREATE OR REPLACE FUNCTION public.can_manage_user_as_staff(target_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT COALESCE(
        public.is_current_user_admin()
        OR (
            public.current_user_role() = 'teacher'
            AND EXISTS (
                SELECT 1
                FROM public.users target_user
                JOIN public.roles target_role ON target_role.id = target_user.role_id
                WHERE target_user.id = target_user_id
                  AND target_user.id <> auth.uid()
                  AND target_user.study_group_id IS NOT NULL
                  AND target_user.study_group_id = public.current_user_group_id()
                  AND target_role.name = 'student'
            )
        ),
        false
    );
$$;

CREATE OR REPLACE FUNCTION public.can_manage_task_execution_as_staff(target_execution_id BIGINT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT COALESCE(
        public.is_current_user_admin()
        OR EXISTS (
            SELECT 1
            FROM public.task_executions te
            WHERE te.id = target_execution_id
              AND public.can_manage_user_as_staff(te.user_id)
              AND public.can_read_task(te.task_id)
        ),
        false
    );
$$;

CREATE OR REPLACE FUNCTION public.can_manage_attempt_as_staff(target_attempt_id BIGINT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT COALESCE(
        public.is_current_user_admin()
        OR EXISTS (
            SELECT 1
            FROM public.attempts a
            WHERE a.id = target_attempt_id
              AND public.can_manage_task_execution_as_staff(a.task_execution_id)
        ),
        false
    );
$$;

CREATE OR REPLACE FUNCTION public.can_read_task_execution(target_execution_id BIGINT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT COALESCE(
        EXISTS (
            SELECT 1
            FROM public.task_executions te
            WHERE te.id = target_execution_id
              AND public.can_read_private_user_data(te.user_id)
        ),
        false
    );
$$;

CREATE OR REPLACE FUNCTION public.enforce_users_update_integrity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        IF current_user IN ('postgres', 'supabase_admin', 'service_role') THEN
            RETURN NEW;
        END IF;

        RAISE EXCEPTION 'Authentication required'
            USING ERRCODE = '28000';
    END IF;

    IF NEW.id <> OLD.id THEN
        RAISE EXCEPTION 'User id cannot be changed'
            USING ERRCODE = '42501';
    END IF;

    IF NEW.registered_at <> OLD.registered_at THEN
        RAISE EXCEPTION 'User registered_at cannot be changed'
            USING ERRCODE = '42501';
    END IF;

    IF public.is_current_user_admin() THEN
        RETURN NEW;
    END IF;

    IF NEW.role_id <> OLD.role_id THEN
        RAISE EXCEPTION 'Only admin can change user role'
            USING ERRCODE = '42501';
    END IF;

    IF NEW.study_group_id IS DISTINCT FROM OLD.study_group_id THEN
        RAISE EXCEPTION 'Only admin can change user study group'
            USING ERRCODE = '42501';
    END IF;

    IF auth.uid() = OLD.id THEN
        RETURN NEW;
    END IF;

    IF public.can_manage_user_as_staff(OLD.id) THEN
        RETURN NEW;
    END IF;

    RAISE EXCEPTION 'Current user cannot update user %', OLD.id
        USING ERRCODE = '42501';
END;
$$;

DROP TRIGGER IF EXISTS trg_users_update_integrity ON public.users;
CREATE TRIGGER trg_users_update_integrity
BEFORE UPDATE ON public.users
FOR EACH ROW
EXECUTE FUNCTION public.enforce_users_update_integrity();

DROP POLICY IF EXISTS users_select_group_or_self ON public.users;
DROP POLICY IF EXISTS users_select_private ON public.users;
CREATE POLICY users_select_private ON public.users
FOR SELECT TO authenticated
USING (public.can_read_private_user_data(id));

DROP POLICY IF EXISTS users_insert_managed ON public.users;
DROP POLICY IF EXISTS users_insert_admin ON public.users;
CREATE POLICY users_insert_admin ON public.users
FOR INSERT TO authenticated
WITH CHECK (public.is_current_user_admin());

DROP POLICY IF EXISTS users_update_managed ON public.users;
DROP POLICY IF EXISTS users_update_self_profile ON public.users;
DROP POLICY IF EXISTS users_update_staff ON public.users;
CREATE POLICY users_update_self_profile ON public.users
FOR UPDATE TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

CREATE POLICY users_update_staff ON public.users
FOR UPDATE TO authenticated
USING (public.can_manage_user_as_staff(id))
WITH CHECK (public.can_manage_user_as_staff(id));

DROP POLICY IF EXISTS vocabulary_sets_insert_managed ON public.vocabulary_sets;
DROP POLICY IF EXISTS vocabulary_sets_update_managed ON public.vocabulary_sets;
DROP POLICY IF EXISTS vocabulary_sets_delete_managed ON public.vocabulary_sets;
DROP POLICY IF EXISTS vocabulary_sets_insert_staff ON public.vocabulary_sets;
DROP POLICY IF EXISTS vocabulary_sets_update_staff ON public.vocabulary_sets;
DROP POLICY IF EXISTS vocabulary_sets_delete_staff ON public.vocabulary_sets;
CREATE POLICY vocabulary_sets_insert_staff ON public.vocabulary_sets
FOR INSERT TO authenticated
WITH CHECK (
    public.current_user_role() IN ('admin', 'teacher')
    AND public.can_manage_user(user_id)
);

CREATE POLICY vocabulary_sets_update_staff ON public.vocabulary_sets
FOR UPDATE TO authenticated
USING (
    public.current_user_role() IN ('admin', 'teacher')
    AND public.can_manage_user(user_id)
)
WITH CHECK (
    public.current_user_role() IN ('admin', 'teacher')
    AND public.can_manage_user(user_id)
);

CREATE POLICY vocabulary_sets_delete_staff ON public.vocabulary_sets
FOR DELETE TO authenticated
USING (
    public.current_user_role() IN ('admin', 'teacher')
    AND public.can_manage_user(user_id)
);

DROP POLICY IF EXISTS set_words_link_insert_managed ON public.set_words_link;
DROP POLICY IF EXISTS set_words_link_update_managed ON public.set_words_link;
DROP POLICY IF EXISTS set_words_link_delete_managed ON public.set_words_link;
DROP POLICY IF EXISTS set_words_link_insert_staff ON public.set_words_link;
DROP POLICY IF EXISTS set_words_link_update_staff ON public.set_words_link;
DROP POLICY IF EXISTS set_words_link_delete_staff ON public.set_words_link;
CREATE POLICY set_words_link_insert_staff ON public.set_words_link
FOR INSERT TO authenticated
WITH CHECK (
    public.current_user_role() IN ('admin', 'teacher')
    AND public.can_manage_vocabulary_set(vocabulary_set_id)
);

CREATE POLICY set_words_link_update_staff ON public.set_words_link
FOR UPDATE TO authenticated
USING (
    public.current_user_role() IN ('admin', 'teacher')
    AND public.can_manage_vocabulary_set(vocabulary_set_id)
)
WITH CHECK (
    public.current_user_role() IN ('admin', 'teacher')
    AND public.can_manage_vocabulary_set(vocabulary_set_id)
);

CREATE POLICY set_words_link_delete_staff ON public.set_words_link
FOR DELETE TO authenticated
USING (
    public.current_user_role() IN ('admin', 'teacher')
    AND public.can_manage_vocabulary_set(vocabulary_set_id)
);

DROP POLICY IF EXISTS tasks_insert_managed ON public.tasks;
DROP POLICY IF EXISTS tasks_update_managed ON public.tasks;
DROP POLICY IF EXISTS tasks_delete_managed ON public.tasks;
DROP POLICY IF EXISTS tasks_insert_staff ON public.tasks;
DROP POLICY IF EXISTS tasks_update_staff ON public.tasks;
DROP POLICY IF EXISTS tasks_delete_staff ON public.tasks;
CREATE POLICY tasks_insert_staff ON public.tasks
FOR INSERT TO authenticated
WITH CHECK (
    public.current_user_role() IN ('admin', 'teacher')
    AND public.can_manage_vocabulary_set(vocabulary_set_id)
);

CREATE POLICY tasks_update_staff ON public.tasks
FOR UPDATE TO authenticated
USING (
    public.current_user_role() IN ('admin', 'teacher')
    AND public.can_manage_vocabulary_set(vocabulary_set_id)
)
WITH CHECK (
    public.current_user_role() IN ('admin', 'teacher')
    AND public.can_manage_vocabulary_set(vocabulary_set_id)
);

CREATE POLICY tasks_delete_staff ON public.tasks
FOR DELETE TO authenticated
USING (
    public.current_user_role() IN ('admin', 'teacher')
    AND public.can_manage_vocabulary_set(vocabulary_set_id)
);

DROP POLICY IF EXISTS task_executions_insert_managed ON public.task_executions;
DROP POLICY IF EXISTS task_executions_update_managed ON public.task_executions;
DROP POLICY IF EXISTS task_executions_delete_managed ON public.task_executions;
DROP POLICY IF EXISTS task_executions_insert_staff ON public.task_executions;
DROP POLICY IF EXISTS task_executions_update_staff ON public.task_executions;
DROP POLICY IF EXISTS task_executions_delete_staff ON public.task_executions;
CREATE POLICY task_executions_insert_staff ON public.task_executions
FOR INSERT TO authenticated
WITH CHECK (
    public.current_user_role() IN ('admin', 'teacher')
    AND public.can_manage_user_as_staff(user_id)
    AND public.can_read_task(task_id)
);

CREATE POLICY task_executions_update_staff ON public.task_executions
FOR UPDATE TO authenticated
USING (public.can_manage_task_execution_as_staff(id))
WITH CHECK (
    public.current_user_role() IN ('admin', 'teacher')
    AND public.can_manage_user_as_staff(user_id)
    AND public.can_read_task(task_id)
);

CREATE POLICY task_executions_delete_staff ON public.task_executions
FOR DELETE TO authenticated
USING (public.can_manage_task_execution_as_staff(id));

DROP POLICY IF EXISTS attempts_insert_managed ON public.attempts;
DROP POLICY IF EXISTS attempts_update_managed ON public.attempts;
DROP POLICY IF EXISTS attempts_delete_managed ON public.attempts;
DROP POLICY IF EXISTS attempts_insert_staff ON public.attempts;
DROP POLICY IF EXISTS attempts_update_staff ON public.attempts;
DROP POLICY IF EXISTS attempts_delete_staff ON public.attempts;
CREATE POLICY attempts_insert_staff ON public.attempts
FOR INSERT TO authenticated
WITH CHECK (
    public.current_user_role() IN ('admin', 'teacher')
    AND public.can_manage_task_execution_as_staff(task_execution_id)
);

CREATE POLICY attempts_update_staff ON public.attempts
FOR UPDATE TO authenticated
USING (public.can_manage_attempt_as_staff(id))
WITH CHECK (
    public.current_user_role() IN ('admin', 'teacher')
    AND public.can_manage_task_execution_as_staff(task_execution_id)
);

CREATE POLICY attempts_delete_staff ON public.attempts
FOR DELETE TO authenticated
USING (public.can_manage_attempt_as_staff(id));

DROP POLICY IF EXISTS question_answers_insert_managed ON public.question_answers;
DROP POLICY IF EXISTS question_answers_update_managed ON public.question_answers;
DROP POLICY IF EXISTS question_answers_delete_managed ON public.question_answers;
DROP POLICY IF EXISTS question_answers_insert_staff ON public.question_answers;
DROP POLICY IF EXISTS question_answers_update_staff ON public.question_answers;
DROP POLICY IF EXISTS question_answers_delete_staff ON public.question_answers;
CREATE POLICY question_answers_insert_staff ON public.question_answers
FOR INSERT TO authenticated
WITH CHECK (
    public.current_user_role() IN ('admin', 'teacher')
    AND public.can_manage_attempt_as_staff(attempt_id)
);

CREATE POLICY question_answers_update_staff ON public.question_answers
FOR UPDATE TO authenticated
USING (public.can_manage_attempt_as_staff(attempt_id))
WITH CHECK (
    public.current_user_role() IN ('admin', 'teacher')
    AND public.can_manage_attempt_as_staff(attempt_id)
);

CREATE POLICY question_answers_delete_staff ON public.question_answers
FOR DELETE TO authenticated
USING (public.can_manage_attempt_as_staff(attempt_id));

DROP POLICY IF EXISTS notifications_select_linked ON public.notifications;
DROP POLICY IF EXISTS notifications_select_private ON public.notifications;
CREATE POLICY notifications_select_private ON public.notifications
FOR SELECT TO authenticated
USING (
    public.is_current_user_admin()
    OR
    EXISTS (
        SELECT 1
        FROM public.notification_users_link nul
        WHERE nul.notification_id = id
          AND public.can_read_private_user_data(nul.user_id)
    )
);

DROP POLICY IF EXISTS notifications_insert_staff ON public.notifications;
DROP POLICY IF EXISTS notifications_update_staff ON public.notifications;
DROP POLICY IF EXISTS notifications_delete_staff ON public.notifications;
DROP POLICY IF EXISTS notifications_insert_admin ON public.notifications;
DROP POLICY IF EXISTS notifications_update_admin ON public.notifications;
DROP POLICY IF EXISTS notifications_delete_admin ON public.notifications;
CREATE POLICY notifications_insert_admin ON public.notifications
FOR INSERT TO authenticated
WITH CHECK (public.is_current_user_admin());

CREATE POLICY notifications_update_admin ON public.notifications
FOR UPDATE TO authenticated
USING (public.is_current_user_admin())
WITH CHECK (public.is_current_user_admin());

CREATE POLICY notifications_delete_admin ON public.notifications
FOR DELETE TO authenticated
USING (public.is_current_user_admin());

DROP POLICY IF EXISTS notification_users_link_select_group ON public.notification_users_link;
DROP POLICY IF EXISTS notification_users_link_select_private ON public.notification_users_link;
CREATE POLICY notification_users_link_select_private ON public.notification_users_link
FOR SELECT TO authenticated
USING (public.can_read_private_user_data(user_id));

DROP POLICY IF EXISTS notification_users_link_insert_managed ON public.notification_users_link;
DROP POLICY IF EXISTS notification_users_link_update_managed ON public.notification_users_link;
DROP POLICY IF EXISTS notification_users_link_delete_managed ON public.notification_users_link;
DROP POLICY IF EXISTS notification_users_link_insert_admin ON public.notification_users_link;
DROP POLICY IF EXISTS notification_users_link_update_admin ON public.notification_users_link;
DROP POLICY IF EXISTS notification_users_link_delete_admin ON public.notification_users_link;
CREATE POLICY notification_users_link_insert_admin ON public.notification_users_link
FOR INSERT TO authenticated
WITH CHECK (public.is_current_user_admin());

CREATE POLICY notification_users_link_update_admin ON public.notification_users_link
FOR UPDATE TO authenticated
USING (public.is_current_user_admin())
WITH CHECK (public.is_current_user_admin());

CREATE POLICY notification_users_link_delete_admin ON public.notification_users_link
FOR DELETE TO authenticated
USING (public.is_current_user_admin());

DROP POLICY IF EXISTS achievements_manage_staff ON public.achievements;
DROP POLICY IF EXISTS achievements_manage_admin ON public.achievements;
CREATE POLICY achievements_manage_admin ON public.achievements
FOR ALL TO authenticated
USING (public.is_current_user_admin())
WITH CHECK (public.is_current_user_admin());

DROP POLICY IF EXISTS user_achievements_link_select_group ON public.user_achievements_link;
DROP POLICY IF EXISTS user_achievements_link_select_private ON public.user_achievements_link;
CREATE POLICY user_achievements_link_select_private ON public.user_achievements_link
FOR SELECT TO authenticated
USING (public.can_read_private_user_data(user_id));

DROP POLICY IF EXISTS user_achievements_link_insert_managed ON public.user_achievements_link;
DROP POLICY IF EXISTS user_achievements_link_update_managed ON public.user_achievements_link;
DROP POLICY IF EXISTS user_achievements_link_delete_managed ON public.user_achievements_link;
DROP POLICY IF EXISTS user_achievements_link_insert_admin ON public.user_achievements_link;
DROP POLICY IF EXISTS user_achievements_link_update_admin ON public.user_achievements_link;
DROP POLICY IF EXISTS user_achievements_link_delete_admin ON public.user_achievements_link;
CREATE POLICY user_achievements_link_insert_admin ON public.user_achievements_link
FOR INSERT TO authenticated
WITH CHECK (public.is_current_user_admin());

CREATE POLICY user_achievements_link_update_admin ON public.user_achievements_link
FOR UPDATE TO authenticated
USING (public.is_current_user_admin())
WITH CHECK (public.is_current_user_admin());

CREATE POLICY user_achievements_link_delete_admin ON public.user_achievements_link
FOR DELETE TO authenticated
USING (public.is_current_user_admin());

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'tasks_dates_order_chk'
          AND conrelid = 'public.tasks'::regclass
    ) THEN
        ALTER TABLE public.tasks
        ADD CONSTRAINT tasks_dates_order_chk
        CHECK (deadline IS NULL OR start_date IS NULL OR deadline >= start_date)
        NOT VALID;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'attempts_time_order_chk'
          AND conrelid = 'public.attempts'::regclass
    ) THEN
        ALTER TABLE public.attempts
        ADD CONSTRAINT attempts_time_order_chk
        CHECK (ended_at IS NULL OR ended_at >= started_at)
        NOT VALID;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'notifications_type_not_blank_chk'
          AND conrelid = 'public.notifications'::regclass
    ) THEN
        ALTER TABLE public.notifications
        ADD CONSTRAINT notifications_type_not_blank_chk
        CHECK (btrim(type) <> '' AND char_length(type) <= 64)
        NOT VALID;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'notifications_text_not_blank_chk'
          AND conrelid = 'public.notifications'::regclass
    ) THEN
        ALTER TABLE public.notifications
        ADD CONSTRAINT notifications_text_not_blank_chk
        CHECK (btrim(text) <> '' AND char_length(text) <= 2000)
        NOT VALID;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'achievements_name_not_blank_chk'
          AND conrelid = 'public.achievements'::regclass
    ) THEN
        ALTER TABLE public.achievements
        ADD CONSTRAINT achievements_name_not_blank_chk
        CHECK (btrim(name) <> '')
        NOT VALID;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'achievements_condition_not_blank_chk'
          AND conrelid = 'public.achievements'::regclass
    ) THEN
        ALTER TABLE public.achievements
        ADD CONSTRAINT achievements_condition_not_blank_chk
        CHECK (btrim(condition_text) <> '')
        NOT VALID;
    END IF;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'public'
          AND indexname = 'idx_task_executions_user_task_unique'
    ) THEN
        IF EXISTS (
            SELECT 1
            FROM public.task_executions
            GROUP BY user_id, task_id
            HAVING COUNT(*) > 1
        ) THEN
            RAISE WARNING 'Skipped unique index idx_task_executions_user_task_unique because duplicate task_executions exist.';
        ELSE
            CREATE UNIQUE INDEX idx_task_executions_user_task_unique
            ON public.task_executions (user_id, task_id);
        END IF;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'public'
          AND indexname = 'idx_question_answers_attempt_word_unique'
    ) THEN
        IF EXISTS (
            SELECT 1
            FROM public.question_answers
            GROUP BY attempt_id, word_id
            HAVING COUNT(*) > 1
        ) THEN
            RAISE WARNING 'Skipped unique index idx_question_answers_attempt_word_unique because duplicate question_answers exist.';
        ELSE
            CREATE UNIQUE INDEX idx_question_answers_attempt_word_unique
            ON public.question_answers (attempt_id, word_id);
        END IF;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'public'
          AND indexname = 'idx_achievements_condition_text_unique'
    ) THEN
        IF EXISTS (
            SELECT 1
            FROM public.achievements
            GROUP BY condition_text
            HAVING COUNT(*) > 1
        ) THEN
            RAISE WARNING 'Skipped unique index idx_achievements_condition_text_unique because duplicate achievement condition_text values exist.';
        ELSE
            CREATE UNIQUE INDEX idx_achievements_condition_text_unique
            ON public.achievements (condition_text);
        END IF;
    END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.current_user_role() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.current_user_group_id() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_current_user_admin() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_read_user(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_manage_user(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_read_vocabulary_set(BIGINT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_manage_vocabulary_set(BIGINT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_read_task(BIGINT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_manage_task(BIGINT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_manage_task_execution(BIGINT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_read_attempt(BIGINT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_manage_attempt(BIGINT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_current_user_teacher() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_read_private_user_data(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_manage_user_as_staff(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_manage_task_execution_as_staff(BIGINT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_manage_attempt_as_staff(BIGINT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_read_task_execution(BIGINT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.enforce_users_update_integrity() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.current_user_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.current_user_group_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_current_user_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_read_user(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_manage_user(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_read_vocabulary_set(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_manage_vocabulary_set(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_read_task(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_manage_task(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_manage_task_execution(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_read_attempt(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_manage_attempt(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_current_user_teacher() TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_read_private_user_data(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_manage_user_as_staff(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_manage_task_execution_as_staff(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_manage_attempt_as_staff(BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_read_task_execution(BIGINT) TO authenticated;

COMMIT;
