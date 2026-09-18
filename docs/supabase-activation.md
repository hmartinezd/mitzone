# Supabase activation

## Nearby events status

Implemented and code-verified: the configured event flow uses foreground
location, the authenticated `nearby-events` Edge Function, normalized
Ticketmaster metadata, local event catalog details, and the existing
participation/upcoming surfaces. Provider failures remain errors and an
authentic empty provider response remains empty; demo events are limited to
local/test mode.

The production `nearby-events` Edge Function has been deployed and its
provider secret has been activated. This records configuration work only; it
does not claim end-to-end provider success.

Still requiring runtime/device validation:

- authenticated physical-device invocation;
- foreground location permission and real coordinates;
- actual regional Ticketmaster results;
- real provider image and source rendering;
- empty and error behavior on a device.

Owner verification is still needed for any current Ticketmaster attribution or
provider-policy requirements beyond the metadata/display behavior implemented
in the app. Mitzone does not provide ticket purchasing, resale, seat maps,
checkout, affiliate links, or embedded provider browsing.

## Normal development

Mitzone has one normal application runtime: Supabase-backed authenticated mode.
In VS Code, press **Run / F5** and launch the single **Mitzone** configuration.
It automatically supplies `--dart-define-from-file=config/dev.json`.

1. Create a new Supabase project.
2. In Supabase Authentication, enable Email, allow new users to sign up, and
   configure the development email confirmation behavior appropriate for the
   test users. The app supports both confirmation enabled and disabled.
3. Copy `config/dev.example.json` to the ignored local file `config/dev.json`.
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

The command above is the CLI equivalent of pressing F5. A plain `flutter run`
does not select a local/demo product mode; without required configuration it
fails clearly at startup.

Do not put a service-role key, database password, JWT signing secret, or
management token in Flutter configuration.

## Google Places discovery (optional)

The Home discovery source can use the authenticated `nearby-discovery` Edge
Function. In Google Cloud, create a billing-enabled project, enable Places API
(New), create a server-side API key restricted to Places API (New), and set it
as the Supabase secret `GOOGLE_PLACES_API_KEY`. Deploy with
`supabase functions deploy nearby-discovery` and verify it accepts only
authenticated Supabase requests. The function requests only
`places.id,places.displayName,places.primaryType,places.types,places.shortFormattedAddress,places.location`
from Nearby Search (New), which is in Google's Nearby Search Pro field tier;
check current regional pricing before enabling billing. No Google key belongs
in Flutter or `config/dev.json`.

Google-sourced content must retain Google Maps attribution and must not be
cached beyond policy exceptions; this first slice omits photos and displays
the provider's place data without a map, so add visible Google Maps text/logo
attribution before production launch. Place IDs may be retained as allowed by
Google policy. See Google's current [Places policies](https://developers.google.com/maps/documentation/places/web-service/policies).

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
the `get_public_profiles` RPC.

For password recovery, add `mitzone://auth/reset-password` to Supabase Auth
redirect URLs and register the `mitzone` custom URL scheme in the Android and
iOS app manifests. Deploy the `delete-account` Edge Function with
`SUPABASE_SERVICE_ROLE_KEY` configured only in the function environment. The
function resolves the caller from its bearer token and never accepts a target
user ID. Never put that secret in Flutter configuration.
