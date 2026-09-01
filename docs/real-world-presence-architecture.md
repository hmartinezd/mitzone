# Real-world presence architecture

The first private beta should use explicit, foreground presence activation (“I’m here”) combined with the existing event check-in flow. This is the least invasive mode that can validate whether shared-context encounters are useful. Background/passive presence is designed but disabled.

OS location permission and Mitzone product consent are separate. Permission means the operating system may allow an observation; it never means Mitzone is recording presence. A session is collectible only when permission is `whileUsing`, product consent is true, and presence is explicitly active. The later UX states are not requested, denied, allowed while using, background (reserved), inactive, active, recorded, and unavailable.

The location adapter must resolve a raw observation into a coarse opaque place key (bounded cell or venue/context identifier) before creating `PresenceEvidence`. Coordinates, paths, history, and raw observations never enter the encounter domain or leave the trusted backend boundary. Coarser cells improve privacy but can create false overlaps; venue keys improve relevance but require a trusted resolver and can reveal venue context. The beta should prefer venue/context keys where available and bounded coarse cells only when necessary.

Evidence uses UTC `observedStart`/`observedEnd`, with a maximum session window and an expiry. The server must authoritatively assign the user, timestamps, expiry, source, and resolved context; clients cannot claim arbitrary long historical presence. Raw observations, if temporarily retained by a future resolver, have the shortest retention and should be deleted after resolution. Evidence is short-lived, and encounters are retained only as long as product policy requires.

Blocking, eligibility, encounter authorization, and public-profile boundaries remain unchanged. Presence evidence is owner/server-only and is never directly queryable by another user; encounters expose only derived social context. Resolver failure leaves presence absent and does not invalidate existing valid evidence.

iOS/Android background permission, battery impact, permission escalation, and App Store/Play privacy disclosures are deferred design work. The beta does not request background access or run continuous tracking.
