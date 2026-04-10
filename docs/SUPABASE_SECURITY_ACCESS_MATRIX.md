# Sprint D Security Access Matrix

This document summarizes the intended RLS posture after `20260410_000007_security_data_integrity_hardening.sql`.

## Roles

- `admin`: full operational access through RLS for managed domain data.
- `teacher`: can read and manage limited student data in the teacher's own `study_group_id`.
- `student`: can read and update only their own private profile data, and should use RPC for task lifecycle and achievement recalculation.

## Matrix

| Table | Admin | Teacher | Student |
| --- | --- | --- | --- |
| `users` | read/update all; insert profiles manually if needed | read own-group students; update non-sensitive own-group student profile fields | read/update self only |
| `study_groups` | full manage | read own group only | read own group only |
| `vocabulary_sets` | manage all | manage sets for self/managed users through existing ownership checks | read allowed sets only; no direct content mutation |
| `tasks` | manage all reachable sets | manage tasks for manageable vocabulary sets | read allowed tasks only; start/submit through RPC |
| `task_executions` | direct manage | direct manage own-group student executions | read allowed executions; direct writes denied; lifecycle RPC allowed |
| `attempts` | direct manage | direct manage own-group student attempts | read own/allowed attempts; direct writes denied; submit RPC allowed |
| `question_answers` | direct manage | direct manage own-group student answers | read own/allowed answers; direct writes denied; submit RPC allowed |
| `notifications` | direct manage | read own-group student notifications; create through `create_user_notification` RPC only | read own notifications only |
| `notification_users_link` | direct manage | read own-group student notification links | read own notification links only |
| `achievements` | direct manage | read catalog | read catalog |
| `user_achievements_link` | direct manage | read own-group student achievement links | read own achievement links only; awards through `recalculate_user_achievements` RPC |

## Hardening Notes

- New helper `can_read_private_user_data(uuid)` prevents same-group students from reading each other's private rows.
- New helper `can_manage_user_as_staff(uuid)` allows teachers to manage only students in their own group, not peers or other teachers.
- Direct student writes to lifecycle tables are denied; `start_task_execution`, `submit_attempt`, `submit_question_answer`, and `complete_task_execution` remain the intended path.
- Direct notification writes are admin-only; teachers use `create_user_notification`, which validates role and target user access.
- Direct achievement-link mutation is admin-only; normal award flow uses `recalculate_user_achievements`.
- `users` update trigger prevents non-admin role escalation and study group self-assignment.
- Added data-integrity checks for task dates, attempt time order, non-blank notification/achievement fields, and optional unique indexes for duplicate-prone links.
- Helper functions now explicitly revoke `PUBLIC` execution and grant only to `authenticated` where application policies/RPC need them.

## Validation

Use `supabase/validation/sprint_d_permission_matrix.sql` in a non-production Supabase project with real fixture ids. The script exercises positive and negative scenarios for admin, teacher, and student and reports mismatches.
