BEGIN;

CREATE OR REPLACE FUNCTION public.set_updated_at_if_present()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = TG_TABLE_SCHEMA
          AND table_name = TG_TABLE_NAME
          AND column_name = 'updated_at'
    ) THEN
        NEW.updated_at = now();
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    email_value TEXT;
    username_base TEXT;
    username_value TEXT;
BEGIN
    email_value := NULLIF(trim(NEW.email), '');

    IF email_value IS NULL THEN
        email_value := NEW.id::TEXT || '@auth.local';
    END IF;

    username_base := NULLIF(split_part(email_value, '@', 1), '');

    IF username_base IS NULL THEN
        username_base := 'user_' || substr(NEW.id::TEXT, 1, 8);
    END IF;

    username_value := username_base;

    IF EXISTS (
        SELECT 1
        FROM public.users
        WHERE username = username_value
          AND id <> NEW.id
    ) THEN
        username_value := username_base || '_' || substr(NEW.id::TEXT, 1, 8);
    END IF;

    INSERT INTO public.users (id, email, username, registered_at, role_id)
    VALUES (
        NEW.id,
        email_value,
        username_value,
        now(),
        (SELECT id FROM public.roles WHERE name = 'student' LIMIT 1)
    )
    ON CONFLICT (id) DO NOTHING;

    RETURN NEW;
END;
$$;

ALTER TABLE public.users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE public.study_groups ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE public.vocabulary_sets ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE public.task_executions ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE public.attempts ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE public.question_answers ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();
ALTER TABLE public.achievements ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

DROP TRIGGER IF EXISTS trg_users_updated_at ON public.users;
CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON public.users
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at_if_present();

DROP TRIGGER IF EXISTS trg_study_groups_updated_at ON public.study_groups;
CREATE TRIGGER trg_study_groups_updated_at
BEFORE UPDATE ON public.study_groups
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at_if_present();

DROP TRIGGER IF EXISTS trg_vocabulary_sets_updated_at ON public.vocabulary_sets;
CREATE TRIGGER trg_vocabulary_sets_updated_at
BEFORE UPDATE ON public.vocabulary_sets
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at_if_present();

DROP TRIGGER IF EXISTS trg_tasks_updated_at ON public.tasks;
CREATE TRIGGER trg_tasks_updated_at
BEFORE UPDATE ON public.tasks
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at_if_present();

DROP TRIGGER IF EXISTS trg_task_executions_updated_at ON public.task_executions;
CREATE TRIGGER trg_task_executions_updated_at
BEFORE UPDATE ON public.task_executions
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at_if_present();

DROP TRIGGER IF EXISTS trg_attempts_updated_at ON public.attempts;
CREATE TRIGGER trg_attempts_updated_at
BEFORE UPDATE ON public.attempts
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at_if_present();

DROP TRIGGER IF EXISTS trg_question_answers_updated_at ON public.question_answers;
CREATE TRIGGER trg_question_answers_updated_at
BEFORE UPDATE ON public.question_answers
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at_if_present();

DROP TRIGGER IF EXISTS trg_notifications_updated_at ON public.notifications;
CREATE TRIGGER trg_notifications_updated_at
BEFORE UPDATE ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at_if_present();

DROP TRIGGER IF EXISTS trg_achievements_updated_at ON public.achievements;
CREATE TRIGGER trg_achievements_updated_at
BEFORE UPDATE ON public.achievements
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at_if_present();

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_auth_user();

COMMIT;
