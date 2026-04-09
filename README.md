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

- `flutter format --set-exit-if-changed --dry-run .`
- `flutter analyze`
- `flutter test`

## How CI Works

The pipeline is designed to catch formatting issues, static analysis warnings, and test failures before changes are merged. This keeps the main branch stable and gives fast feedback during development.
Widget tests initialize Supabase with real project credentials from GitHub Actions secrets.

## Running With Supabase

Pass runtime configuration through `--dart-define` values:

`flutter run --dart-define=SUPABASE_URL=<your_project_url> --dart-define=SUPABASE_PUBLISHABLE_KEY=<your_publishable_key>`
