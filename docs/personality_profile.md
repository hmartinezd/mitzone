# Optional personality profile

Mitzone uses a lightweight Big Five-inspired model for social discovery, not a psychological assessment or diagnosis. The user-facing terms are **Curious**, **Organized**, **Outgoing**, **Warm**, and **Calm under pressure**; the domain uses openness, conscientiousness, extraversion, agreeableness, and emotional stability.

The version 1 questionnaire has 15 friendly behavioral statements (three per trait) and a four-point scale from “Not like me” to “Very much like me”. Three reverse-keyed items reduce response-pattern gaming. Scores are derived locally and normalized to 0.0–1.0; raw answers are not persisted.

Profiles are optional, skippable, retakable, and stored with the schema version, completion timestamp, and visibility preference. The remote table is protected by RLS and ownership checks. Raw trait values are private by default and are not shown on another user’s public profile.

`private` means the profile is stored for its owner and excluded from cross-user matching. `matching` grants permission for a secured server-side compatibility calculation only; it never grants clients access to raw traits. Clients receive derived compatibility only.

Compatibility is a bounded, symmetric, deterministic secondary signal. It compares openness, conscientiousness, agreeableness, and emotional stability modestly; extraversion differences are neutral rather than treated as incompatibility. Missing data is `unknown` and contributes zero. Its ranking weight is 10%, so it cannot affect encounter eligibility, presence validity, blocking, or safety.

This is an optional social-discovery aid. It makes no clinical, mental-health, dating, or psychological-compatibility claims.
