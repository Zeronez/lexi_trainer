BEGIN;

DROP POLICY IF EXISTS users_delete_admin ON public.users;

CREATE POLICY users_delete_admin ON public.users
FOR DELETE TO authenticated
USING (
    public.is_current_user_admin()
    AND id <> auth.uid()
);

COMMIT;
