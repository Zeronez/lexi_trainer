# Release Freeze & Sign-off (Sprint E)

## Release Candidate
- Version tag: `rc-2026-04-10`
- Target branch: `main`
- CI workflows: `flutter_ci.yml`, `release_pipeline.yml`

## Freeze Criteria
- `main` has no failing GitHub Actions checks.
- All migrations up to latest are applied in Supabase project.
- Security/regression CI job is green.
- No open P0 defects.
- No open P1 defects without explicit waiver.

## Sign-off Roles
- Product owner: functional scope acceptance.
- QA owner: UAT checklist complete, no blocking defects.
- Backend owner: migration and RLS checks verified.
- DevOps owner: release artifact generated and retained.

## Go/No-Go Checklist
- [x] CI green on latest `main` commit.
- [ ] Release artifact created from `release_pipeline.yml`.
- [ ] Supabase migration order executed and verified.
- [ ] Security matrix validation executed successfully.
- [ ] UAT checklist marked complete.
- [x] Rollback runbook reviewed by on-duty engineer.

## Approval Log
- Product owner: [ ] Approved
- QA owner: [ ] Approved
- Backend owner: [ ] Approved
- DevOps owner: [ ] Approved
- Final decision: [ ] GO / [x] NO-GO

## Evidence
- Latest green CI: https://github.com/Zeronez/lexi_trainer/actions/runs/24222821162
- UAT report: `docs/UAT_EXECUTION_REPORT.md`
- RC log: `docs/RELEASE_CANDIDATE_LOG.md`

## Notes
Final GO is blocked until manual `Release Readiness` workflow is run and artifact is produced.
