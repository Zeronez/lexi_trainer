# Release Candidate Log

Use this file to record each release candidate and final promotion decision.

| RC | Workflow run id | Artifact link | Build commit | GO/NO-GO | Decision owner | Decision date | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| rc-2026-04-10 | N/A (manual workflow not run yet) | N/A | 17c085324e35bc8004f9f12a129595945bfa8f80 | NO-GO | Conductor | 2026-04-10 | Automatic Flutter CI is green: https://github.com/Zeronez/lexi_trainer/actions/runs/24222821162. Need manual `Release Readiness` run and artifact before GO. |

## Guidance

- Record exact GitHub Actions run id for `Release Readiness`.
- Add direct artifact link from workflow run.
- Set `GO` only after UAT report is complete and required checks are passed or formally waived.
