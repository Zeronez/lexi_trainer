BEGIN;

DROP POLICY IF EXISTS study_groups_select_own_or_admin ON public.study_groups;
DROP POLICY IF EXISTS study_groups_select_staff_read ON public.study_groups;

CREATE POLICY study_groups_select_staff_read ON public.study_groups
FOR SELECT TO authenticated
USING (
    public.is_current_user_admin()
    OR public.current_user_role() = 'teacher'
    OR id = public.current_user_group_id()
);

COMMIT;
