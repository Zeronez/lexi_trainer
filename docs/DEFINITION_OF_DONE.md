# Definition of Done (Lexi Trainer)

## Phase 1: Backend Foundation

- All planned tables, FK/PK, indexes, and constraints are in migrations.
- Seed and RLS migrations are present and documented.
- RLS validation scenarios are documented and executable.
- Changes are pushed to `main` and CI passes.

## Phase 2: DevOps / CI

- Workflow runs `dart format`, `flutter analyze`, `flutter test`.
- CI reads runtime config only from GitHub Secrets/Variables.
- README includes CI status and usage notes.
- Changes are pushed to `main` and CI passes.

## Phase 3: Frontend Core

- Target screens implemented and navigable.
- Theme and design palette are applied consistently.
- Role-based access rules are applied in UI.
- Widget tests cover critical screens/flows.
- Changes are pushed to `main` and CI passes.

## Phase 4: QA

- Regression tests exist for critical user paths.
- Failures are reproducible and traceable from CI logs.
- No required tests are skipped in CI.
- Changes are pushed to `main` and CI passes.

## Phase 5: Integration & Security

- Supabase auth + DB integration works with runtime config.
- RLS access checks are validated with scenario scripts.
- Secrets are not hardcoded or committed.
- Changes are pushed to `main` and CI passes.

## Phase 6: Release Operations

- Release checklist documented (env vars, rollback, smoke checks).
- Deployment process (if enabled) is reproducible in GitHub Actions.
- Changes are pushed to `main` and CI passes.
