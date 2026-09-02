# Supabase activation

## Local/demo mode

Run the app with no Supabase defines:

```bash
flutter run
```

This uses the local demo identity and local repositories.

## Supabase development mode

1. Create a new Supabase project.
2. In Supabase Authentication, enable Email and configure the development
   email confirmation behavior appropriate for the test users.
3. Copy `config/dev.example.json` to `config/dev.json`.
4. Set `APP_ENV` to `development`, and supply the project's client-safe
   `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` only.
5. Keep `config/dev.json` local; it is ignored by Git.
6. Link the repository with the Supabase CLI and apply the migrations in order:

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
flutter run --dart-define-from-file=config/dev.json
```

Do not put a service-role key, database password, JWT signing secret, or
management token in Flutter configuration.

## First smoke test

Create two temporary email/password users in the Supabase dashboard, then
verify for each user: sign in, create a minimum profile, edit it, restart the
app, and confirm the same session and profile return. Verify through the
dashboard or a separate authenticated client that one user cannot read or
update the other user's private profile fields. Public profile reads must use
the `get_public_profiles` RPC.
