# RLS Validation Scenarios

Use this checklist to validate Row Level Security behavior after each policy update.

## File

- `supabase/tests/rls_validation_scenarios.sql`

## Preconditions

1. Migrations are applied up to `20260409_000004_rls_policies.sql`.
2. Roles/users/groups/tasks test fixtures already exist in your Supabase project.
3. You have IDs for:
   - `student_a_id` (group A)
   - `student_b_id` (group B)
   - `teacher_a_id` (group A)
   - `group_a_id`
   - `group_b_id`
   - `task_a_id`

## Run

1. Open Supabase SQL Editor.
2. Open `supabase/tests/rls_validation_scenarios.sql`.
3. Replace placeholder IDs with real values.
4. Execute script.

## Expected Result

- Script finishes without `RAISE EXCEPTION`.
- If an RLS rule is broken, script fails with explicit message:
  - student can/cannot read profile mismatch
  - teacher group isolation mismatch
  - task execution visibility mismatch

## Notes

- Script runs under `SET LOCAL ROLE authenticated` and changes `request.jwt.claim.sub` to emulate users.
- Transaction ends with `ROLLBACK`, so no persistent data changes are saved.
