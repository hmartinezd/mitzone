# Supabase activation

## Local/demo mode

Run the app with no Supabase defines:

```bash
flutter run
```

This uses the local demo identity and local repositories.

## Supabase development mode

1. Create a new Supabase project.
2. In Supabase Authentication, enable Email, allow new users to sign up, and
   configure the development email confirmation behavior appropriate for the
   test users. The app supports both confirmation enabled and disabled.
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

Use the app's Create Account mode to register a disposable email/password
account. If confirmation is enabled, verify that the app shows Check your
email and does not enter authenticated screens; confirm the email, then sign
in. If confirmation is disabled, verify that signup enters the minimum-profile
flow. In either case, save a minimum profile, restart the app, confirm the
same session and profile return, sign out, and sign back in.

The profile row must use the same UUID as `auth.users.id`. Verify through the
dashboard or a separate authenticated client that one user cannot read or
update another user's private profile fields. Public profile reads must use
the `get_public_profiles` RPC. Password recovery, confirmation deep-link
return, and account deletion are follow-up work.
