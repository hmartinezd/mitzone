# Sprint 3 Production Encounter Architecture

Status: planning only. This document defines boundaries; it does not activate a backend, authentication, GPS, QR, push notifications, or production matching.

## Sprint 2 audit

The supported local flow is:

`event discovery → participation → demo presence → encounter → other-user profile → Say Hi → request → connection → conversation → messages → notifications → disconnect/block`

The event catalog, mock attendee windows, and mock profiles are deterministic fixtures. Participation, check-ins, profiles, requests, connections, conversations, messages, blocks, and in-app notifications use identity-scoped local persistence where applicable. Repository/domain interfaces are suitable replacement boundaries for remote implementations. UI assumptions include mock identity switching and local route state. Production-incompatible assumptions include no permanent authentication, remote authorization, multi-device consistency, presence verification, moderation, retention policy, or abuse prevention. Report User/moderation remain deferred.

## Production pipeline

`event/place context → presence evidence → candidate overlap → eligibility/safety → encounter → relevance/ranking → user interaction`

**Presence** is evidence that two users occupied compatible place/time context. **Eligibility** is whether those users are allowed to interact, including consent, privacy, blocks, account state, and policy. **Relevance** is whether an eligible encounter is meaningful enough to surface prominently. These concepts remain separate.

## Presence architecture

Define a source-neutral `PresenceEvidence` contract containing subject identity, event/venue context, bounded start/end observation interval, source type, confidence/verification metadata, consent scope, and retention policy. A `PresenceSource` abstraction can later support event participation, QR check-in, geolocation, venue/event verification, and future signals. Sources must not require continuous tracking. Explicit opt-in, minimization, visibility, revocation, retention limits, and platform permission boundaries are mandatory constraints. Participation intent must not be treated as verified presence.

## Eligibility and relevance

Eligibility consumes consent, privacy, blocks, account state, and connection state before an encounter becomes actionable. The future relevance layer may use shared context, overlap duration, shared interests, languages, connection goals, profile completeness, and optionally personality compatibility. No final scoring formula is defined. Relevance ranks eligible encounters; it does not determine presence or safety. Personality is an optional relevance signal, never a prerequisite for encounter creation, and never part of presence verification.

## Backend migration boundary

Remote implementations will eventually replace the local repositories for identity/profile, events, participation/presence, encounters, connection requests/connections, blocking, conversations/messages, and notifications. Keep contracts storage-neutral. Add authenticated remote implementations behind current providers only after ownership, conflict handling, privacy rules, and authorization semantics are specified; do not activate Supabase yet.

## Recommended implementation order

1. Finalize production contracts, ownership, IDs, timestamps, retention, and authorization errors.
2. Add backend/auth foundation behind identity/profile and repository interfaces.
3. Add source-neutral presence evidence, consent, retention, and event participation migration.
4. Implement remote bounded-overlap encounter generation.
5. Apply centralized eligibility/safety policy, including blocks and connection lifecycle.
6. Add independent, explainable relevance/ranking without personality dependency.
7. Migrate production notifications with authorization-aware destinations and delivery semantics.
8. Add privacy, migration, observability, rollout, and operational testing.

GPS, QR, production matching, personality questionnaires/scoring, Report User, moderation, and push delivery remain deferred to dedicated future blocks.

## Initial contract decisions

The first contract block adds a source-neutral `PresenceEvidence` value with an opaque evidence ID, subject user, context ID, bounded UTC interval, extensible source enum, optional confidence, consent scope, and expiration. `Encounter` remains a derived pair result and now rejects self-pairs and reversed intervals. A small `DomainError` vocabulary is available for not-found, unauthorized, interaction-unavailable, invalid-state, and validation failures; existing local adapters may continue translating their current errors until each contract is migrated.

Existing local IDs remain valid. New IDs must be opaque and independent of display names, list order, and timestamps alone. Domain timestamps are UTC; lifecycle timestamps retain their meaning instead of being overloaded. No local persistence schema migration is required by these contracts.
