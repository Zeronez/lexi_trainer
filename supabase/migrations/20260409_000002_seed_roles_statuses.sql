BEGIN;

INSERT INTO public.roles (name)
VALUES
    ('admin'),
    ('teacher'),
    ('student')
ON CONFLICT (name) DO NOTHING;

INSERT INTO public.statuses (name)
VALUES
    ('assigned'),
    ('in_progress'),
    ('completed'),
    ('overdue')
ON CONFLICT (name) DO NOTHING;

COMMIT;
