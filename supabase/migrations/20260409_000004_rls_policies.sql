BEGIN;

CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT r.name
    FROM public.users u
    JOIN public.roles r ON r.id = u.role_id
    WHERE u.id = auth.uid()
    LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.current_user_group_id()
RETURNS BIGINT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT u.study_group_id
    FROM public.users u
    WHERE u.id = auth.uid()
    LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.is_current_user_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT COALESCE(public.current_user_role() = 'admin', false);
$$;

CREATE OR REPLACE FUNCTION public.can_read_user(target_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT COALESCE(
        public.is_current_user_admin()
        OR target_user_id = auth.uid()
        OR EXISTS (
            SELECT 1
            FROM public.users target_user
            WHERE target_user.id = target_user_id
              AND target_user.study_group_id IS NOT NULL
              AND target_user.study_group_id = public.current_user_group_id()
        ),
        false
    );
$$;

CREATE OR REPLACE FUNCTION public.can_manage_user(target_user_id UUID)
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

CREATE OR REPLACE FUNCTION public.can_read_vocabulary_set(target_set_id BIGINT)
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
            FROM public.vocabulary_sets vs
            WHERE vs.id = target_set_id
              AND public.can_read_user(vs.user_id)
        ),
        false
    );
$$;

CREATE OR REPLACE FUNCTION public.can_manage_vocabulary_set(target_set_id BIGINT)
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
            FROM public.vocabulary_sets vs
            WHERE vs.id = target_set_id
              AND public.can_manage_user(vs.user_id)
        ),
        false
    );
$$;

CREATE OR REPLACE FUNCTION public.can_read_task(target_task_id BIGINT)
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
            FROM public.tasks t
            WHERE t.id = target_task_id
              AND public.can_read_vocabulary_set(t.vocabulary_set_id)
        ),
        false
    );
$$;

CREATE OR REPLACE FUNCTION public.can_manage_task(target_task_id BIGINT)
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
            FROM public.tasks t
            WHERE t.id = target_task_id
              AND public.can_manage_vocabulary_set(t.vocabulary_set_id)
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
        public.is_current_user_admin()
        OR EXISTS (
            SELECT 1
            FROM public.task_executions te
            WHERE te.id = target_execution_id
              AND (public.can_read_user(te.user_id) OR public.can_read_task(te.task_id))
        ),
        false
    );
$$;

CREATE OR REPLACE FUNCTION public.can_manage_task_execution(target_execution_id BIGINT)
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
              AND (public.can_manage_user(te.user_id) OR public.can_manage_task(te.task_id))
        ),
        false
    );
$$;

CREATE OR REPLACE FUNCTION public.can_read_attempt(target_attempt_id BIGINT)
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
              AND public.can_read_task_execution(a.task_execution_id)
        ),
        false
    );
$$;

CREATE OR REPLACE FUNCTION public.can_manage_attempt(target_attempt_id BIGINT)
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
              AND public.can_manage_task_execution(a.task_execution_id)
        ),
        false
    );
$$;

ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.words ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vocabulary_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.set_words_link ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.statuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_executions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_users_link ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements_link ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS roles_read_authenticated ON public.roles;
CREATE POLICY roles_read_authenticated ON public.roles
FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS statuses_read_authenticated ON public.statuses;
CREATE POLICY statuses_read_authenticated ON public.statuses
FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS study_groups_select_own_or_admin ON public.study_groups;
CREATE POLICY study_groups_select_own_or_admin ON public.study_groups
FOR SELECT TO authenticated
USING (public.is_current_user_admin() OR id = public.current_user_group_id());

DROP POLICY IF EXISTS study_groups_manage_admin ON public.study_groups;
CREATE POLICY study_groups_manage_admin ON public.study_groups
FOR ALL TO authenticated
USING (public.is_current_user_admin())
WITH CHECK (public.is_current_user_admin());

DROP POLICY IF EXISTS users_select_group_or_self ON public.users;
CREATE POLICY users_select_group_or_self ON public.users
FOR SELECT TO authenticated
USING (public.can_read_user(id));

DROP POLICY IF EXISTS users_insert_managed ON public.users;
CREATE POLICY users_insert_managed ON public.users
FOR INSERT TO authenticated
WITH CHECK (public.can_manage_user(id));

DROP POLICY IF EXISTS users_update_managed ON public.users;
CREATE POLICY users_update_managed ON public.users
FOR UPDATE TO authenticated
USING (public.can_manage_user(id))
WITH CHECK (public.can_manage_user(id));

DROP POLICY IF EXISTS vocabulary_sets_select_group ON public.vocabulary_sets;
CREATE POLICY vocabulary_sets_select_group ON public.vocabulary_sets
FOR SELECT TO authenticated
USING (public.can_read_user(user_id));

DROP POLICY IF EXISTS vocabulary_sets_insert_managed ON public.vocabulary_sets;
CREATE POLICY vocabulary_sets_insert_managed ON public.vocabulary_sets
FOR INSERT TO authenticated
WITH CHECK (public.can_manage_user(user_id));

DROP POLICY IF EXISTS vocabulary_sets_update_managed ON public.vocabulary_sets;
CREATE POLICY vocabulary_sets_update_managed ON public.vocabulary_sets
FOR UPDATE TO authenticated
USING (public.can_manage_user(user_id))
WITH CHECK (public.can_manage_user(user_id));

DROP POLICY IF EXISTS vocabulary_sets_delete_managed ON public.vocabulary_sets;
CREATE POLICY vocabulary_sets_delete_managed ON public.vocabulary_sets
FOR DELETE TO authenticated
USING (public.can_manage_user(user_id));

DROP POLICY IF EXISTS set_words_link_select_group ON public.set_words_link;
CREATE POLICY set_words_link_select_group ON public.set_words_link
FOR SELECT TO authenticated
USING (public.can_read_vocabulary_set(vocabulary_set_id));

DROP POLICY IF EXISTS set_words_link_insert_managed ON public.set_words_link;
CREATE POLICY set_words_link_insert_managed ON public.set_words_link
FOR INSERT TO authenticated
WITH CHECK (public.can_manage_vocabulary_set(vocabulary_set_id));

DROP POLICY IF EXISTS set_words_link_update_managed ON public.set_words_link;
CREATE POLICY set_words_link_update_managed ON public.set_words_link
FOR UPDATE TO authenticated
USING (public.can_manage_vocabulary_set(vocabulary_set_id))
WITH CHECK (public.can_manage_vocabulary_set(vocabulary_set_id));

DROP POLICY IF EXISTS set_words_link_delete_managed ON public.set_words_link;
CREATE POLICY set_words_link_delete_managed ON public.set_words_link
FOR DELETE TO authenticated
USING (public.can_manage_vocabulary_set(vocabulary_set_id));

DROP POLICY IF EXISTS words_select_group_sets ON public.words;
CREATE POLICY words_select_group_sets ON public.words
FOR SELECT TO authenticated
USING (
    public.is_current_user_admin()
    OR EXISTS (
        SELECT 1
        FROM public.set_words_link swl
        WHERE swl.word_id = id
          AND public.can_read_vocabulary_set(swl.vocabulary_set_id)
    )
);

DROP POLICY IF EXISTS words_manage_staff ON public.words;
CREATE POLICY words_manage_staff ON public.words
FOR ALL TO authenticated
USING (public.current_user_role() IN ('admin', 'teacher'))
WITH CHECK (public.current_user_role() IN ('admin', 'teacher'));

DROP POLICY IF EXISTS tasks_select_group ON public.tasks;
CREATE POLICY tasks_select_group ON public.tasks
FOR SELECT TO authenticated
USING (public.can_read_vocabulary_set(vocabulary_set_id));

DROP POLICY IF EXISTS tasks_insert_managed ON public.tasks;
CREATE POLICY tasks_insert_managed ON public.tasks
FOR INSERT TO authenticated
WITH CHECK (public.can_manage_vocabulary_set(vocabulary_set_id));

DROP POLICY IF EXISTS tasks_update_managed ON public.tasks;
CREATE POLICY tasks_update_managed ON public.tasks
FOR UPDATE TO authenticated
USING (public.can_manage_vocabulary_set(vocabulary_set_id))
WITH CHECK (public.can_manage_vocabulary_set(vocabulary_set_id));

DROP POLICY IF EXISTS tasks_delete_managed ON public.tasks;
CREATE POLICY tasks_delete_managed ON public.tasks
FOR DELETE TO authenticated
USING (public.can_manage_vocabulary_set(vocabulary_set_id));

DROP POLICY IF EXISTS task_executions_select_group ON public.task_executions;
CREATE POLICY task_executions_select_group ON public.task_executions
FOR SELECT TO authenticated
USING (public.can_read_user(user_id) OR public.can_read_task(task_id));

DROP POLICY IF EXISTS task_executions_insert_managed ON public.task_executions;
CREATE POLICY task_executions_insert_managed ON public.task_executions
FOR INSERT TO authenticated
WITH CHECK (public.can_manage_user(user_id) AND public.can_read_task(task_id));

DROP POLICY IF EXISTS task_executions_update_managed ON public.task_executions;
CREATE POLICY task_executions_update_managed ON public.task_executions
FOR UPDATE TO authenticated
USING (public.can_manage_user(user_id) OR public.can_manage_task(task_id))
WITH CHECK (public.can_manage_user(user_id) AND public.can_read_task(task_id));

DROP POLICY IF EXISTS task_executions_delete_managed ON public.task_executions;
CREATE POLICY task_executions_delete_managed ON public.task_executions
FOR DELETE TO authenticated
USING (public.can_manage_user(user_id) OR public.can_manage_task(task_id));

DROP POLICY IF EXISTS attempts_select_group ON public.attempts;
CREATE POLICY attempts_select_group ON public.attempts
FOR SELECT TO authenticated
USING (public.can_read_task_execution(task_execution_id));

DROP POLICY IF EXISTS attempts_insert_managed ON public.attempts;
CREATE POLICY attempts_insert_managed ON public.attempts
FOR INSERT TO authenticated
WITH CHECK (public.can_manage_task_execution(task_execution_id));

DROP POLICY IF EXISTS attempts_update_managed ON public.attempts;
CREATE POLICY attempts_update_managed ON public.attempts
FOR UPDATE TO authenticated
USING (public.can_manage_task_execution(task_execution_id))
WITH CHECK (public.can_manage_task_execution(task_execution_id));

DROP POLICY IF EXISTS attempts_delete_managed ON public.attempts;
CREATE POLICY attempts_delete_managed ON public.attempts
FOR DELETE TO authenticated
USING (public.can_manage_task_execution(task_execution_id));

DROP POLICY IF EXISTS question_answers_select_group ON public.question_answers;
CREATE POLICY question_answers_select_group ON public.question_answers
FOR SELECT TO authenticated
USING (public.can_read_attempt(attempt_id));

DROP POLICY IF EXISTS question_answers_insert_managed ON public.question_answers;
CREATE POLICY question_answers_insert_managed ON public.question_answers
FOR INSERT TO authenticated
WITH CHECK (public.can_manage_attempt(attempt_id));

DROP POLICY IF EXISTS question_answers_update_managed ON public.question_answers;
CREATE POLICY question_answers_update_managed ON public.question_answers
FOR UPDATE TO authenticated
USING (public.can_manage_attempt(attempt_id))
WITH CHECK (public.can_manage_attempt(attempt_id));

DROP POLICY IF EXISTS question_answers_delete_managed ON public.question_answers;
CREATE POLICY question_answers_delete_managed ON public.question_answers
FOR DELETE TO authenticated
USING (public.can_manage_attempt(attempt_id));

DROP POLICY IF EXISTS notifications_select_linked ON public.notifications;
CREATE POLICY notifications_select_linked ON public.notifications
FOR SELECT TO authenticated
USING (
    public.is_current_user_admin()
    OR EXISTS (
        SELECT 1
        FROM public.notification_users_link nul
        WHERE nul.notification_id = id
          AND public.can_read_user(nul.user_id)
    )
);

DROP POLICY IF EXISTS notifications_insert_staff ON public.notifications;
CREATE POLICY notifications_insert_staff ON public.notifications
FOR INSERT TO authenticated
WITH CHECK (public.current_user_role() IN ('admin', 'teacher'));

DROP POLICY IF EXISTS notifications_update_staff ON public.notifications;
CREATE POLICY notifications_update_staff ON public.notifications
FOR UPDATE TO authenticated
USING (public.current_user_role() IN ('admin', 'teacher'))
WITH CHECK (public.current_user_role() IN ('admin', 'teacher'));

DROP POLICY IF EXISTS notifications_delete_staff ON public.notifications;
CREATE POLICY notifications_delete_staff ON public.notifications
FOR DELETE TO authenticated
USING (public.current_user_role() IN ('admin', 'teacher'));

DROP POLICY IF EXISTS notification_users_link_select_group ON public.notification_users_link;
CREATE POLICY notification_users_link_select_group ON public.notification_users_link
FOR SELECT TO authenticated
USING (public.can_read_user(user_id));

DROP POLICY IF EXISTS notification_users_link_insert_managed ON public.notification_users_link;
CREATE POLICY notification_users_link_insert_managed ON public.notification_users_link
FOR INSERT TO authenticated
WITH CHECK (public.can_manage_user(user_id));

DROP POLICY IF EXISTS notification_users_link_update_managed ON public.notification_users_link;
CREATE POLICY notification_users_link_update_managed ON public.notification_users_link
FOR UPDATE TO authenticated
USING (public.can_manage_user(user_id))
WITH CHECK (public.can_manage_user(user_id));

DROP POLICY IF EXISTS notification_users_link_delete_managed ON public.notification_users_link;
CREATE POLICY notification_users_link_delete_managed ON public.notification_users_link
FOR DELETE TO authenticated
USING (public.can_manage_user(user_id));

DROP POLICY IF EXISTS achievements_read_authenticated ON public.achievements;
CREATE POLICY achievements_read_authenticated ON public.achievements
FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS achievements_manage_staff ON public.achievements;
CREATE POLICY achievements_manage_staff ON public.achievements
FOR ALL TO authenticated
USING (public.current_user_role() IN ('admin', 'teacher'))
WITH CHECK (public.current_user_role() IN ('admin', 'teacher'));

DROP POLICY IF EXISTS user_achievements_link_select_group ON public.user_achievements_link;
CREATE POLICY user_achievements_link_select_group ON public.user_achievements_link
FOR SELECT TO authenticated
USING (public.can_read_user(user_id));

DROP POLICY IF EXISTS user_achievements_link_insert_managed ON public.user_achievements_link;
CREATE POLICY user_achievements_link_insert_managed ON public.user_achievements_link
FOR INSERT TO authenticated
WITH CHECK (public.can_manage_user(user_id));

DROP POLICY IF EXISTS user_achievements_link_update_managed ON public.user_achievements_link;
CREATE POLICY user_achievements_link_update_managed ON public.user_achievements_link
FOR UPDATE TO authenticated
USING (public.can_manage_user(user_id))
WITH CHECK (public.can_manage_user(user_id));

DROP POLICY IF EXISTS user_achievements_link_delete_managed ON public.user_achievements_link;
CREATE POLICY user_achievements_link_delete_managed ON public.user_achievements_link
FOR DELETE TO authenticated
USING (public.can_manage_user(user_id));

COMMIT;
