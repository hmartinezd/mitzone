# Existing provider reuse and local discovery hardening

Verified 2026-11-11. No deployment, production writes or secret-value retrieval.

## Read-only original-project evidence

Original project identity: Mitzone, `bqlerixwfusmfesfhupz`.
`nearby-discovery` and `nearby-events` are ACTIVE, version2, with verify_jwt=true. The secret-name inventory contains GOOGLE_PLACES_API_KEY and TICKETMASTER_API_KEY. Only identity/function metadata and secret-name metadata were inspected. Presence does not establish current key validity, restrictions, billing or successful upstream requests. No original function invocation was performed.

Staging remains `arnikuoruzadqydhqfoj`. Prior live checks confirmed the two functions and provider secrets are absent; authenticated requests returned404. Existing provider accounts/integration source can be reused; replacement accounts or providers are unnecessary.

## Credential decision

Supabase metadata cannot establish Google Cloud Places API(New) enablement, key API/application restrictions, billing, quota, or Ticketmaster developer-application status/approved use. These require owner/provider-console metadata review; no connected provider-console access was available. Never relax or rotate production keys merely to make staging work.

Preferred isolation: use staging-specific credentials under the existing Google Cloud and Ticketmaster accounts/app configuration where supported, leaving production credentials unchanged. A separate Google key in the same Cloud project still shares that project's billing/quota; it is not complete financial isolation. Review server-side restrictions against the actual staging egress configuration. Browser-referrer or Android-package restrictions are not server-side authorization. Do not remove existing IP restrictions to accommodate staging.

Reusing exactly the same keys is conditional on the account's allowed Mitzone testing use, valid server-side restrictions, enabled APIs/billing and accepted shared quota/cost impact. We cannot certify those conditions from Supabase metadata. It requires explicit owner authorization to handle/copy those existing production credentials. Supabase secret listings do not expose plaintext values; obtain them only through an owner-authorized original provider source/password manager or have the owner configure staging directly. Do not scrape deployed production code/runtime to recover secrets.

Owner action/authorization needed next:
1. Review existing provider-console metadata without revealing keys: Google API restrictions/application restrictions, Places API(New), billing/quota; Ticketmaster app status, permitted use and quota.
2. Choose isolated staging keys under existing accounts (recommended) or explicitly authorize reuse/copy of exactly the two named existing credentials into staging, with no production key changes. Configure through staging secrets or a securely permissioned ignored local env file, never chat/source/Flutter.
3. After credentials are ready, separately authorize staging secret writes and deployment of only nearby-discovery and nearby-events with the reviewed local fixes. Current instruction explicitly prohibits deployment.
No new accounts, paid services, billing activation or production changes are authorized.

Sources: [Google API security guidance](https://developers.google.com/maps/api-security-best-practices), [Google Places setup](https://developers.google.com/maps/documentation/places/web-service/get-api-key), [Ticketmaster getting started/quota](https://developer.ticketmaster.com/products-and-docs/apis/getting-started/), [Ticketmaster API terms](https://developer.ticketmaster.com/support/terms-of-use/).

## Local changes and actual validation

- Both actual entrypoints now share strict coordinate validation: finite JSON numbers only, latitude[-90,90], longitude[-180,180]. Nulls, blank/numeric strings, booleans, arrays/objects, missing coordinates and non-finite numbers are rejected without a provider call. Numeric zero and boundaries remain valid.
- Both provider fetches have a10-second AbortSignal timeout covering response headers and response-body consumption, inside Flutter's20-second client timeout. Existing sanitized error contracts and authentication are preserved. No coordinate persistence, presence writes, raw credential logging or provider substitution added.
- Offline Deno2.5.6 tests:3tests/88steps PASS, exercising both real deployment entrypoints with explicitly mocked auth/provider boundaries. Includes interrupted headers and body, accelerated deadline while asserting the production10000ms setting, strict coordinate/boundary tests, authentication, response normalization/attribution and existing Ticketmaster error/privacy contracts. No external provider call or real key required.
- Offline TypeScript check of both entrypoints PASS using the test import-map dependency replacement. This does not verify a deployed runtime or the live remote SDK import.
- Flutter discovery/event client contract regression:19PASS.
- Production/staging integrations were not deployed or functionally retested against providers. Local-only patches remain uncommitted; recovery checkpoint dd014cc is intact.

Reproduce offline function tests:
```sh
DENO_DIR="$PWD/.recovery/deno-cache" .recovery/tools/deno test --no-config --no-lock --cached-only --allow-read=supabase/functions --import-map=supabase/tests/nearby-events/import_map.json supabase/tests/nearby-events/index_test.ts supabase/tests/nearby-functions/index_test.ts
```
