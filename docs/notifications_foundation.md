# Production notifications foundation

Notifications are backend-neutral records owned by exactly one authenticated recipient. The supported types are the existing connection request, connection accepted, and new message activity. Records contain only identifiers, type, destination, timestamps, and read state; they do not contain presence evidence, personality traits, or authentication data.

Demo uses the existing local repository. Production uses Supabase, where clients can read and update only their own rows. Inserts are deliberately unavailable to normal clients: future secured social operations are the creation authority. Push delivery is out of scope.

Read state is stored in `read_at`, so unread counts survive restart, sign-in, and multiple devices. Opening a notification must still re-check the destination's current authorization and safety; a stale or blocked resource is handled as unavailable.

FCM HTTP v1 authentication is server-side. `dispatch-push` signs a short-lived
service-account JWT and exchanges it at Google's OAuth endpoint using the scope
`https://www.googleapis.com/auth/firebase.messaging`. It reuses a valid token
for warm invocations and refreshes it automatically. Configure Supabase secrets
`FCM_PROJECT_ID`, `FCM_CLIENT_EMAIL`, and `FCM_PRIVATE_KEY`, mapped from
`project_id`, `client_email`, and `private_key` in the downloaded service-account
JSON. Store the PEM key only as a secret; escaped `\\n` sequences are handled
by the function. `FCM_ACCESS_TOKEN` is not used.

Push foundation: Firebase Cloud Messaging (APNs-backed on iOS) registers private,
owner-scoped rows in `device_tokens`. A Supabase Database Webhook on notification
INSERT invokes `dispatch-push`, which re-reads the canonical row and sends only
safe text plus type/entity routing metadata. Invalid tokens are removed and
temporary failures preserve tokens. Configure Firebase files locally, APNs,
and Supabase secrets `FCM_PROJECT_ID`, `FCM_CLIENT_EMAIL`, `FCM_PRIVATE_KEY`, and service-role
credentials; never put these values in Flutter or source control. Push remains
best-effort, and denied permission leaves in-app notifications usable.

## Database Webhook activation

`dispatch-push` is explicitly configured with `verify_jwt = false` because the
Supabase Database Webhook is authenticated by its own header rather than a user
JWT. The function rejects every request without the dedicated
`x-mitzone-webhook-secret` header matching the Edge Function secret
`PUSH_WEBHOOK_SECRET`; it is not an anonymous push relay.

Manual activation (after committing):

1. Generate a random high-entropy value locally and set it only as an Edge
   Function secret: `supabase secrets set PUSH_WEBHOOK_SECRET=<value>`.
2. Deploy with `supabase functions deploy dispatch-push` (the checked-in
   `supabase/config.toml` explicitly disables platform JWT verification for this
   function). Do not put the secret in SQL or source control.
3. In Supabase Dashboard → Database → Webhooks, create an **INSERT** webhook
   for schema `public`, table `notifications`, calling the deployed
   `dispatch-push` function. Add header
   `x-mitzone-webhook-secret: <the same local value>` and use the function's
   authenticated webhook configuration. The payload must be the standard
   database webhook envelope; the function accepts only `type=INSERT`,
   `schema=public`, `table=notifications`, and resolves the row by `record.id`.
4. Verify with an intentionally invalid header (expect HTTP 401), then use a
   legitimate notification-producing social action and inspect only function
   status/log metadata. Do not log secrets, tokens, or notification bodies.
   Confirm the notification row exists even if push delivery fails.
