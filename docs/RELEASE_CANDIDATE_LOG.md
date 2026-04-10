# Release Candidate Log

Use this file to record each release candidate and final promotion decision.

| RC | Workflow run id | Artifact link | Build commit | GO/NO-GO | Decision owner | Decision date | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| rc-2026-04-10 | 24225438547 | https://api.github.com/repos/Zeronez/lexi_trainer/actions/artifacts/6363943155/zip | 64493938014dcf1c24ce957f04cf30d60b12c6fa | GO | Conductor | 2026-04-10 | `Flutter CI` run 24225438551 = success, `Release Readiness` run 24225438547 = success, artifact `lexi-trainer-web-release` uploaded. |

## Guidance

- Record exact GitHub Actions run id for `Release Readiness`.
- Add direct artifact link from workflow run.
- Set `GO` only after UAT report is complete and required checks are passed or formally waived.
