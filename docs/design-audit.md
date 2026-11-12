# Whole-app design audit — review package

Date: 2026-11-03. Owner-approved local setup and whole-app audit completed through
coordinator-led native delegation. Status: **awaiting owner review**. No visual
mockups or application behavior changes are approved by this package.

## Deliverables and ownership

| Document | Responsibility / contents |
| --- | --- |
| [Root agreement](../AGENTS.md) | Shared scope, source references, safeguards and validation expectations |
| [Specialist workflow](specialist-workflow.md) | Five responsibilities, actual native delegation, review gates and screenshot contract |
| [Screen/state inventory](design-audit-screen-inventory.md) | Designer-led exhaustive route/surface inventory, overlays, journeys and relevant state coverage |
| [Prioritized UX/UI audit](design-audit-ux.md) | Designer findings with source evidence, impact and proposed responses |
| [Data/privacy audit](design-audit-data-privacy.md) | Separate Supabase and privacy reviews, runtime/local data matrix, contract gaps and retained safeguards |
| [Flutter/QA audit](design-audit-flutter-qa.md) | Separate implementation-feasibility and QA/accessibility reviews, system gaps, test/tool evidence and real-device capture protocol |
| [System/IA/visual proposal plan](design-system-and-ia-proposal.md) | Proposed design direction, navigation alternatives and concrete visual mockup deliverables |

## What this evidence establishes

Source inspection covers routed screens, startup/error surfaces, overlays,
providers, shared design infrastructure, relevant tests and backend contracts.
The inventory maps all **25 registered GoRoute destinations**, plus startup
failure and unknown-route surfaces, embedded Home/navigation states and modal/
system interactions. These are route/surface counts, not counts of unique
visual states; the state matrix records the variants within each destination.
Three native worker contexts produced the specialist documents, with five
responsibilities explicitly separated. The coordinator synthesized the system,
IA and workflow and reviewed the reports against source evidence.

The implementation already includes significantly more Supabase/social/safety
functionality than some early README and architecture statements describe.
Checked-in code establishes intended runtime paths, not deployed availability.
Historical Home screenshots/tests are not current whole-app acceptance.
No app, emulator, tests, builds, external services, secrets, or production data
were accessed/executed for this audit. Existing local Home imagery was inspected
by the Flutter/QA worker. Fresh screenshots, effective database grants, service
health, device permissions and screen-reader behavior remain unverified.

## Highest-priority review decisions

1. **Truthful safety and consent.** Specify observable Stop/pending/failure/
   reactivation states, discovery versus presence explanations, account-scoped
   consent expectations, report versus optional-block outcomes, and accurate
   deletion scope. Preserve server authority and fail-closed restrictions.
2. **Reliable journey completion.** Resolve dead-end/misleading recovery actions,
   asynchronous action feedback, profile/personality persistence, social identity
   context, conversation errors and stale notification destinations in designs.
   These are design findings, not authorization to fix code in this phase.
3. **Product truth.** Reconcile QR/onboarding and deferred-feature language with
   actual capabilities; align privacy/provider disclosure with Google/Ticketmaster
   function paths. Verify reporting grants on an isolated backend in a later
   authorized phase before representing reports as operational.
4. **One visual system.** Reconcile Home-specific navy surfaces, type and shapes
   with shared theme/components; specify complete component states, imagery,
   content tone, page chrome, responsive rules and accessibility acceptance.
5. **Explicit IA selection.** Keep current navigation as implementation baseline.
   Compare consolidated Explore/Connections IA in visual proposals. Treat the
   documented Nearby/Groups vision as separately scoped future functionality.

The detailed UX and specialist reports distinguish observed source behavior,
risks requiring runtime verification, and missing proposed experiences. Their
priorities are design/review priorities, not a claim of confirmed production
incidents or a security certification.

## Proposed next authorization

Approve a **visual-design-only phase**: actual editable screen/component boards,
PNG exports, linked flows, state/responsive variants and a whole-app contact
sheet, starting with system and IA alternatives. No Flutter/backend code changes,
navigation changes, new integrations or production writes. Existing implemented
screens receive full design coverage; future concepts remain clearly separate.

Review foundations first, then journey batches, then the complete product.
Track every inventory item to a board/revision or explicit exclusion. Owner
approval of concrete visual revisions precedes implementation authorization.
No commit, push, deployment or production write is permitted by any design gate.
