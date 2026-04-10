# Supabase Migration Order

Apply migrations in filename order:

1. `20260409_000001_init_schema.sql` - creates the initial Lexi Trainer schema: roles, users, study groups, words, vocabulary sets, tasks, statuses, executions, attempts, answers, notifications, achievements, links, and indexes.
2. `20260409_000002_seed_roles_statuses.sql` - seeds baseline roles (`admin`, `teacher`, `student`) and task statuses (`assigned`, `in_progress`, `completed`, `overdue`) with conflict-safe inserts.
3. `20260409_000003_helpers_triggers.sql` - adds `updated_at` columns and update triggers for mutable domain tables, plus the `auth.users` bootstrap trigger that creates matching `public.users` rows with the default `student` role.
4. `20260409_000004_rls_policies.sql` - enables row-level security, adds current-user helper functions, and creates policies for user, vocabulary, task, attempt, notification, and achievement access.
5. `20260410_000005_assignment_lifecycle_rpc.sql` - adds task lifecycle RPC for starting executions, submitting attempts, submitting answers, and completing executions.
6. `20260410_000006_achievements_notifications_rpc.sql` - adds achievement awarding/recalculation RPC, notification creation RPC, and baseline achievement rules.

The seed migration must run before the auth bootstrap trigger because new profiles use the seeded `student` role. The helper/trigger migration must run before the RLS migration so policies can rely on the same profile model and helper functions.
