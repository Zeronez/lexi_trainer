# Release Runbook

## Release Readiness Pipeline

Use the GitHub Actions workflow `Release Readiness` for release verification.

### How to run

1. Open the repository in GitHub.
2. Go to `Actions`.
3. Select `Release Readiness`.
4. Click `Run workflow`.
5. Choose the branch you want to verify, usually `main` or the release branch.
6. Start the workflow and wait for all jobs to finish.

### What it produces

- A production web build at `build/web`
- A downloadable artifact named `lexi-trainer-web-release`

### Where to check the artifact

1. Open the finished workflow run.
2. Open the job logs.
3. Download the artifact from the `Artifacts` section.

### Required release records

- [UAT Execution Report](./UAT_EXECUTION_REPORT.md)
- [Release Candidate Log](./RELEASE_CANDIDATE_LOG.md)

## UAT Checklist

### P0 gate

Release must not proceed if any P0 item fails.

- App launches without runtime errors.
- Authentication works for a valid user.
- Home screen loads for a signed-in user.
- Role matrix is correct:
  - admin can open admin section
  - teacher can open admin section
  - student cannot open admin section
- Training flow opens and completes one session.
- Achievements screen loads data.
- Notifications inbox loads data.
- Supabase live connectivity check passes.
- `flutter analyze` passes.
- `flutter test` passes.

### P1 gate

Release can proceed only if all P1 items are accepted or explicitly waived.

- Web build completes successfully.
- Artifact is uploaded.
- Russian UI strings are visible on critical screens.
- Empty states render correctly.
- Error states render correctly.
- Permission matrix regression tests pass.

## Rollback / Recovery

Follow these steps if a release needs to be rolled back or recovered.

### Rollback

1. Stop promoting the current release build.
2. Identify the last known good artifact or commit.
3. Re-deploy the previous artifact to the hosting target.
4. Verify authentication, home navigation, achievements, and notifications.
5. Confirm the production version matches the last known good release.

### Recovery

1. Inspect the failing workflow run and logs.
2. Verify whether the issue is build, test, data, or deployment related.
3. Fix the branch or revert the release candidate commit if needed.
4. Re-run `Release Readiness`.
5. Re-validate P0 and P1 gates before re-promoting.

### Recovery checklist

- Supabase secrets are present.
- Web build artifact is available.
- Release branch is in a clean state.
- Regression tests pass again before redeploy.

### Evidence to attach

- UAT result table from `UAT_EXECUTION_REPORT.md`
- RC decision entry from `RELEASE_CANDIDATE_LOG.md`
