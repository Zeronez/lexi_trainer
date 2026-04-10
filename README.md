# Lexi Trainer

Lexi Trainer is a Flutter application backed by Supabase. It is being built as a structured language learning tool with a simple, scalable foundation for app logic, data, and CI automation.

![Flutter CI](https://github.com/Zeronez/lexi_trainer/actions/workflows/flutter_ci.yml/badge.svg)

## Project Status

The project is in an early foundation stage.

- Flutter app structure is still being prepared
- Supabase schema and initial backend foundation are in place
- CI/CD is set up in GitHub Actions

## Tech Stack

- Flutter
- Supabase
- GitHub Actions

## Repository Structure

- `.github/workflows/` - GitHub Actions workflows
- `supabase/` - database migrations and backend setup
- `docs/` - project notes and roadmap status
- `lib/` - Flutter application source code

## Branching Policy

- `main` is protected for stable integration.
- Feature work uses short-lived branches: `feature/<scope>`.
- Each logical milestone is merged/pushed to trigger CI in GitHub Actions.

## CI/CD

CI is handled only through GitHub Actions.

The workflow in `.github/workflows/flutter_ci.yml` runs on `push` and `pull_request` events for `main`. It installs Flutter, caches dependencies, then runs:

- `dart format --set-exit-if-changed --output=none .`
- `flutter analyze`
- `flutter test`

The pipeline now also includes a separate `security_regression` job. It reuses the same Flutter setup and runs a tighter suite for permission-matrix and critical-path regressions:

- `test/permissions/permission_matrix_test.dart`
- `test/home/home_screen_role_navigation_test.dart`
- `test/achievements/achievements_screen_test.dart`
- `test/notifications/notifications_screen_test.dart`
- `test/live/supabase_live_connectivity_test.dart`

## How CI Works

The pipeline is designed to catch formatting issues, static analysis warnings, permission regressions, and test failures before changes are merged. This keeps the main branch stable and gives fast feedback during development.
Widget tests initialize Supabase with real project credentials from GitHub Actions secrets, and the security/regression job verifies both role-based UI behavior and a live Supabase REST handshake.

For release readiness, use the manual `Release Readiness` workflow in `.github/workflows/release_pipeline.yml`. After it finishes, download the `lexi-trainer-web-release` artifact from the workflow run.

## Running With Supabase

Pass runtime configuration through `--dart-define` values:

`flutter run --dart-define=SUPABASE_URL=<your_project_url> --dart-define=SUPABASE_PUBLISHABLE_KEY=<your_publishable_key>`

## Быстрый ручной запуск

В корне проекта есть `run_lexi_trainer.bat`.

1. Дважды кликните файл или запустите его из `cmd`.
2. Скрипт проверит наличие Flutter в `PATH`.
3. Затем выполнит `flutter pub get`.
4. После этого выберите режим:
   - запуск в Chrome
   - запуск для Windows
   - запуск с `SUPABASE_URL` и `SUPABASE_PUBLISHABLE_KEY`
   - `flutter analyze`
   - `flutter test`

## Quick Manual Start (.bat)

Use `run_lexi_trainer.bat` from the project root to quickly run and test the app manually on Windows.

The script does:
- checks `flutter` in `PATH`
- runs `flutter pub get`
- offers menu options:
  - run in Chrome
  - run on Windows desktop
  - run with `SUPABASE_URL` + `SUPABASE_PUBLISHABLE_KEY`
  - `flutter analyze`
- `flutter test`

Alternative launcher (PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File .\run_lexi_trainer.ps1 -Mode web
```

Other modes:

```powershell
powershell -ExecutionPolicy Bypass -File .\run_lexi_trainer.ps1 -Mode windows
powershell -ExecutionPolicy Bypass -File .\run_lexi_trainer.ps1 -Mode analyze
powershell -ExecutionPolicy Bypass -File .\run_lexi_trainer.ps1 -Mode test
```

## Seed Data Pack

For manual testing with realistic data, use:
- `supabase/seeds/20260320_full_seed.sql`
- guide: `docs/SUPABASE_SEED_20260320.md`

Seed dataset uses baseline date `2026-03-20` and populates key tables with 6-24 records depending on context.
