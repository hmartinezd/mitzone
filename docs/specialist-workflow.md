# Coordinator-led product design workflow

Status: approved setup and static whole-app audit, 2026-11-03. No application
implementation, navigation changes, backend changes, or production writes.
Owner approval of the next phase is required before visual proposal creation.

Update: the owner subsequently approved the first visual-design-only package.
See [visual review V1](../design/visual-review-v1/README.md). This authorizes two
directions and representative screens, not all-screen expansion or implementation.

## Responsibilities

| Specialist | Owns | Deliverable / boundary |
| --- | --- | --- |
| Senior Mobile Product Designer | Whole-app UX/UI, journeys, IA, content hierarchy, design system and visual acceptance | Leads inventory/audit, then approved visual phase; cannot invent working product capabilities |
| Flutter Developer | Architecture, component reuse, responsive implementation feasibility | Maps design to existing widgets/contracts; implements only approved design batches |
| Supabase Backend Engineer | Runtime data sources, RLS/RPC contracts, migrations and integration feasibility | Reviews data-dependent states; no deployments or production changes without separate approval |
| Privacy & Security Reviewer | Consent, location, authorization, safety, deletion and sensitive information | Reviews flows and artifacts; records concrete risks and retained safeguards |
| QA & Accessibility Engineer | Coverage, regression, accessibility and device evidence | Independently validates actual app against approved design; records blockers and untested states |

The coordinator owns scope, assignments, synthesis, conflicts, and approval
records. Design leads product decisions; feasibility/security/QA findings feed
back before owner review. A title does not supply a new SDK, service connection,
or an independent permission boundary.

## Native delegation verified in this session

The session exposes `spawn_agent`, `send_message`, `followup_task`,
`interrupt_agent`, `list_agents`, and `wait_agent`. Four concurrent slots include
the coordinator. On 2026-11-03 three real subagents were launched:

- `product_designer`: leads full screen/state and UX audit.
- `backend_privacy`: performs distinct backend and privacy review passes.
- `flutter_qa`: performs distinct Flutter and QA/accessibility review passes.

These are actual delegated contexts, not simulated dialogue. Five responsibilities
are distributed across three workers to respect the limit. They share the
filesystem; explicit ownership is coordination, not technical write isolation.
The coordinator owns this file, root instructions and synthesis; each worker
owns its named audit documents. No worker may modify application/backend code.

The current spawn interface takes a task message rather than a custom-agent name.
Use explicit briefs and inherited instructions; do not assume custom TOML files
are loaded. Official documentation describes `.codex/agents/*.toml`, but no such
files are needed for this supported workflow. There are no existing project or
standard personal agent definitions found to migrate. No plugins/skills are
installed by this setup. Existing available skills are used only when applicable.

References: [native subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents),
[AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md).

## Review gates

1. **Audit (current):** route/state inventory, journeys, evidence-based issues,
   data/privacy constraints, IA alternatives, and design-system proposal.
2. **Visual proposals (requires approval):** actual screen images/boards and
   linked flows, with responsive and alternate-state designs. Written briefs
   alone do not satisfy this phase. No Flutter/backend changes.
3. **Design approval:** owner approves versioned boards, IA, content, state
   behavior and implementation scope. Record revision and explicit decision.
   A missing response is not approval. Proposed new features need explicit scope.
4. **Implementation (separate authorization):** one owner implements a small
   approved batch, preserving contracts and routes. Backend changes require
   separately scoped review. Specialists review results.
5. **Validation:** QA compares real emulator captures to approved designs and
   verifies behavior/accessibility; designer signs off fidelity; unresolved
   issues return to implementation. Owner reviews concrete evidence.
6. **Release:** commits, pushes, deployments and production writes remain
   prohibited unless explicitly authorized. No preceding gate grants these.

## Screenshot and test contract

Before starting a runtime, confirm nonproduction services/accounts and telemetry
configuration. Do not inspect or publish secret values. Record app revision and
dirty state, entrypoint, platform/device, logical viewport, density, orientation,
text scale, scenario, data source, and capture time for each artifact.
Capture unchanged baseline and implemented result at the same settings; compare
to the approved design revision. Use Android emulator and iOS simulator where
available; record platform gaps. Keep existing safe navigation/back/deep links.
Cover narrow/standard widths, landscape, keyboard, safe areas, loading/error/empty,
permissions, pending/destructive actions, 1x/2x text and reduced motion.

Actual provider content must remain actual. Missing photos get truthful neutral
fallbacks and attribution remains visible. Authorized dedicated test records are
not organic user activity. Deterministic fixtures cover hard-to-reproduce states
in tests and must be labeled; they do not prove live integrations work. Simulated
location requires explicit approval and must not trigger presence/check-in.
Use platform capture tools (`adb exec-out screencap` / `xcrun simctl io screenshot`)
only after verifying tooling/device access; do not claim capture from widget tests.
Store artifacts locally with a manifest and redact private data in review copies.

Run focused regression tests and analysis, then required CI checks/platform builds
appropriate to scope. Verify screen readers, semantics, focus/announcements,
contrast and touch targets independently of screenshots. A backend response,
build, golden image, or historical capture alone is not complete UX acceptance.
