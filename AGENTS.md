# Mitzone working agreement

Mitzone connects people through real-world places and shared moments. Preserve
working functionality, integrations, real data, attribution, and privacy controls.

## Current authorization

2026-11-05 update: the owner explicitly rejected the running UI as complete and
authorized local fixes for Android location/discovery plus the navigation
Home / Explore / Nearby / Groups / Profile. Chat moves to top messaging actions
and connected-user journeys. Preserve real existing features and privacy/Stop;
Groups must remain honestly unavailable. This latest scope overrides older
navigation-preservation/design-only text. No production/backend deployment, push
enablement, commits, pushes or publication is authorized. Current UI is not
accepted merely because a build or test passes.

2026-11-04 update: the owner approved Kinetic Teal & Muted Sage and authorized
safe, reversible private-beta implementation and local tests in isolated
branches/worktrees, with parallel specialized agents. This supersedes the
historical design-only restriction below within `/private/tmp/mitzone-beta`.
Preserve existing features, auth, repository contracts, privacy and navigation
logic. Defer Groups/premium/nonessential work. Production writes, deployment,
commits, pushes and build publication still require explicit approval.

The owner approved local workflow configuration, the whole-app audit, and the
first visual-design review package. Configuration, design documentation, editable
mockup sources and local image exports may change. Stop after two directions and
representative screens; obtain approval before expanding to all 25 destinations.
Do not edit Flutter/backend code, add features, or change navigation.
Implementation requires separate approval of concrete designs and scope.
Never commit, push, deploy, or perform production writes without explicit owner
approval. Workflow/design approval does not grant release or production approval.

## Architecture and sources

- Keep the feature-based presentation/domain/data architecture, Riverpod
  providers, GoRouter routes, and existing repository contracts.
- Reuse `lib/app/theme/` and `lib/shared/widgets/` before proposing duplicates.
- Read [specialist workflow](docs/specialist-workflow.md) and
  [audit overview](docs/design-audit.md).
- Use `docs/mitzone-design-direction.md`, `docs/home-phase1.md`, and
  `docs/production-architecture.md` as context. Historical scope/deferred claims
  may lag code. Current owner instructions govern scope; proposed layouts and
  future destinations are not approved behavior.

## Collaboration and evidence

The coordinator delegates bounded tasks through actual native subagent tools
when supported. Keep one implementation owner; reviewers do not edit that
owner's files. Pass shared safeguards and explicit output paths to each task.
Specialist responsibilities are defined in the workflow, not new tool powers.
Distinguish source inspection, historical evidence, live verification, fixtures,
and proposals. Never report a design or test as approved/passing without evidence.

## Data and privacy

Use authorized nonproduction accounts/services for state-changing validation.
Confirm runtime environment before launching the app: startup may register
tokens or emit telemetry. Do not expose credentials or personal information in
logs, screenshots, or docs. Never manufacture provider results or imagery.
Keep honest unavailable/empty states and source credits. Fixtures belong in
clearly identified tests/reviews, not production fallbacks.
Discovery permission is not presence consent. Preserve explicit foreground-only
presence, Stop/expiry, coarse context, server authorization, and symmetric block
restrictions. Simulated location never establishes real presence.

## Validation after approved implementation

Use relevant existing tests, `flutter analyze`, and appropriate platform builds;
follow `.github/workflows/flutter_ci.yml`. Review actual emulator/simulator
screenshots against approved designs at recorded viewport/text scale. Verify
screen-reader behavior, semantics, focus, contrast, touch targets, keyboard,
scrolling, and 2x text. Record unavailable checks instead of claiming completion.
