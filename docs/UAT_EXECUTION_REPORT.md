# UAT Execution Report

Filled for release-candidate gating before GO/NO-GO decision.

## Report Metadata

- Release candidate: rc-2026-04-10
- Date: 2026-04-10
- Owner: QA + Conductor
- Environment: GitHub Actions (`main`)

## P0 / P1 Results

| Gate | Check | Status | Evidence link | Owner | Date |
| --- | --- | --- | --- | --- | --- |
| P0 | App launches without runtime errors | PASS | https://github.com/Zeronez/lexi_trainer/actions/runs/24225438547 | QA | 2026-04-10 |
| P0 | Authentication works for a valid user | PASS | https://github.com/Zeronez/lexi_trainer/actions/runs/24225438551 | QA | 2026-04-10 |
| P0 | Home screen loads for a signed-in user | PASS | https://github.com/Zeronez/lexi_trainer/actions/runs/24225438551 | QA | 2026-04-10 |
| P0 | Role matrix is correct | PASS | https://github.com/Zeronez/lexi_trainer/actions/runs/24225438551 | QA | 2026-04-10 |
| P0 | Training flow opens and completes one session | PASS | https://github.com/Zeronez/lexi_trainer/actions/runs/24225438551 | QA | 2026-04-10 |
| P0 | Achievements screen loads data | PASS | https://github.com/Zeronez/lexi_trainer/actions/runs/24225438551 | QA | 2026-04-10 |
| P0 | Notifications inbox loads data | PASS | https://github.com/Zeronez/lexi_trainer/actions/runs/24225438551 | QA | 2026-04-10 |
| P0 | Supabase live connectivity check passes | PASS | https://github.com/Zeronez/lexi_trainer/actions/runs/24225438551 | QA | 2026-04-10 |
| P0 | `flutter analyze` passes | PASS | https://github.com/Zeronez/lexi_trainer/actions/runs/24225438551 | QA | 2026-04-10 |
| P0 | `flutter test` passes | PASS | https://github.com/Zeronez/lexi_trainer/actions/runs/24225438551 | QA | 2026-04-10 |
| P1 | Web build completes successfully | PASS | https://github.com/Zeronez/lexi_trainer/actions/runs/24225438547 | DevOps | 2026-04-10 |
| P1 | Artifact is uploaded | PASS | https://api.github.com/repos/Zeronez/lexi_trainer/actions/artifacts/6363943155/zip | DevOps | 2026-04-10 |
| P1 | Russian UI strings are visible on critical screens | PASS | https://github.com/Zeronez/lexi_trainer/actions/runs/24225438551 | QA | 2026-04-10 |
| P1 | Empty states render correctly | PASS | https://github.com/Zeronez/lexi_trainer/actions/runs/24225438551 | QA | 2026-04-10 |
| P1 | Error states render correctly | PASS | https://github.com/Zeronez/lexi_trainer/actions/runs/24225438551 | QA | 2026-04-10 |
| P1 | Permission matrix regression tests pass | PASS | https://github.com/Zeronez/lexi_trainer/actions/runs/24225438551 | QA | 2026-04-10 |

## Notes

- All P0/P1 checks are marked PASS for this release candidate.
- Build commit: `64493938014dcf1c24ce957f04cf30d60b12c6fa`.
