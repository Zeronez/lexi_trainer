# GitHub Secrets Setup (Supabase)

Do not commit any Supabase keys to the repository.

Add these secrets in GitHub:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`
- `SUPABASE_ANON_KEY` (if your project uses anon key separately)
- `SUPABASE_SERVICE_ROLE_KEY` (backend/server only)
- `SUPABASE_JWT_SECRET` (if needed by backend tasks)

Where to add:

1. GitHub repository -> Settings -> Secrets and variables -> Actions.
2. Create each secret with the exact name above.

Security notes:

- `SERVICE_ROLE` and any secret key must never be shipped in the mobile app.
- Use publishable/anon key only on the client.
- If any key was exposed in chat, logs, screenshots, or commits, rotate it in Supabase immediately and update GitHub Secrets.

Recommended next step:

- Add Flutter runtime configuration via `--dart-define` using values sourced from GitHub Secrets in CI (without hardcoding).
- The CI test job already uses:
  - `--dart-define=SUPABASE_URL=...`
  - `--dart-define=SUPABASE_PUBLISHABLE_KEY=...`
