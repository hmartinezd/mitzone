# Production architecture

The authenticated flow is: Supabase session → profile → owned presence evidence → server-derived encounters → symmetric block eligibility → server-filtered relevance/personality → RPC-owned connection request/connection → participant-only chat → recipient-only notifications.

The client is untrusted. RLS limits reads to owners or participants; SECURITY DEFINER RPCs validate `auth.uid()`, relationship ownership, current blocking, and state transitions. RPCs use an explicit `search_path`, and direct client writes to relationship tables are revoked.

Raw presence evidence, personality traits, private profile fields, and message bodies stay within their owning/consuming boundary. Compatibility is returned as a derived value; notifications contain type, actor, entity, and destination only.

Blocking is symmetric and fail-closed across encounters, requests, connections, personality compatibility, chat, and notification destinations. Unblocking does not recreate deleted connections or previously completed requests.

Secondary notification and ranking failures must not roll back a successful primary action. Deferred capabilities: GPS/geolocation, QR, push delivery, moderation/reporting, attachments, typing/online presence, and new recommendation features.
