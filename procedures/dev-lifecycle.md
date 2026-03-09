# Dev Lifecycle Procedure

**Applies to:** All dev roles (backend-dev, frontend-dev)
**Machine-readable:** `teams/checklists/dev-issue-lifecycle-backend.yaml` (backend),
`teams/checklists/dev-issue-lifecycle.yaml` (frontend)

---

## Overview

Two nested loops handle ALL development work — single issues, multi-phase
implementation plans, crosswalk requests, and QA iterations.

```
OUTER LOOP: Poll → Assess → Plan → Contracts → [INNER LOOP per issue]
INNER LOOP: Implement → Verify → Document → QA Handoff → Iterate
```

---

## Phase 0: Poll Comms & Triage

**When:** Start of every iteration (outer loop entry point).
**Blocking:** YES — do not proceed to Phase 1+ until all steps complete.
**Full procedure:** `procedures/polling-workflow.md` Steps 1–2.

Phase 0 is the SCAN + TRIAGE from the polling loop. Every iteration:

1. Read CONTENTS of every file in team inbox root (not `inbox/completed/`)
2. Read CONTENTS of every file in `issues/queue/` and `issues/active/`
3. Check active issues for `## Awaiting Response` entries
4. Output a triage table (message count, action items, routing)
5. Classify each actionable message:

| Message Type | Action |
|-------------|--------|
| Contract request | → Phase 1 |
| Implementation plan / crosswalk | → Phase 0b |
| QA finding / rejection | → Match to active issue, prioritize re-fix |
| Bug report from other team | → Phase 0b (assess, create issue) |
| Reply to our outbound request | → Match to original thread, unblock or create issue |
| Question from other team | → Respond directly |
| Status update | → Acknowledge, no action unless blocking |

6. Match findings and cross-team requests to active issues
7. Unblock issues where dependencies are resolved

**Do NOT dismiss issues without reading them.** "Assigned To: QA" does not mean
"skip" — read the issue and determine if your role has action items in it.

---

## Phase 0b: Assess & Decompose

**When:** New plan, crosswalk, or multi-endpoint feature (anything larger than a single issue).

1. Read the full request/plan document
2. Identify distinct work items (endpoints, enhancements, bug fixes, confirmations)
3. Group into phases ordered by dependency
4. Create a plan document in `dev_communication/shared/plans/` if needed
5. Create individual issues in `issues/queue/` for each work item
6. Note dependencies between issues
7. Proceed to Phase 1

---

## Phase 1: Contracts & Cross-Team Setup

**When:** New or changed endpoints are needed.

### Backend-Dev (contract owner):
1. Read cross-team contract requests from inbox
2. Read `contracts/types/` for existing DTOs
3. Define contract DTOs for each new/changed endpoint
4. Send ONE consolidated contract confirmation to the other team's inbox

### Frontend-Dev (contract consumer):
1. Check `contracts/types/` for available DTOs
2. If missing or insufficient, send a request to backend's inbox
3. Never invent local type shapes or write normalizers/transforms

**Key rule:** Backend defines contracts, frontend consumes them. Send ALL contracts
upfront for multi-endpoint plans. (ADR-DEV-004)

**Outbound thread tracking:** When you send a contract request or clarification,
note it in the related issue file under `## Awaiting Response` with the message
filename and date. Remove the entry when the reply is processed.

---

## Phase 2: Context Loading

1. Load relevant ADRs from `dev_communication/shared/architecture/decisions/`
2. Load memory patterns from `memory/patterns/`
3. Read the issue file for acceptance criteria and prior QA findings
4. Review existing code in the affected domain

---

## Phase 3: Implementation

1. Move issue from `queue/` to `active/` (if not already)
2. Plan if complex (schema migration, multi-service change, new middleware)
3. Implement following project architecture
4. Ensure response shapes match contract DTOs exactly
5. Write tests for new functionality
6. If QA re-fix, address specific QA findings first

**Rules:**
- New functionality MUST have corresponding tests
- Response shapes MUST match shared contract DTOs
- Do not add backward-compatibility shims or deprecated fields

---

## Phase 4: Dev Verification Gate (BLOCKING)

All checks must pass before handoff. Fix and re-run on failure.

### Backend-Dev:
| Check | Command | Criteria |
|-------|---------|----------|
| Typecheck | `npx tsc --noEmit` | 0 errors |
| Unit tests | `npm run test:unit` | All pass |
| Integration tests | `npm run test:integration` | All pass |
| Tests exist | (manual) | New functionality has tests |

### Frontend-Dev:
| Check | Command | Criteria |
|-------|---------|----------|
| Typecheck | `npx tsc --noEmit` | 0 errors |
| Unit tests | `npx vitest run` | All pass |
| Integration tests | `npx vitest run --config integration` | All pass |
| Tests exist | (manual) | New functionality has tests |

---

## Phase 5: Documentation & Handoff

1. Create session file at `memory/sessions/{date}-{issue-slug}.md`
2. Append resolution notes to the issue file
3. Confirm contract types are updated (if changed)
4. If cross-team impact, send message to other team's inbox
5. Commit and push

**Handoff rules:**
- Issue stays in `active/` with Status: ACTIVE
- Do NOT move to `completed/` or set Status: COMPLETE — QA owns that
- Dev does NOT run QA gate checks

---

## Phase 5b: Inbox Cleanup

After processing work, move handled inbox messages to `inbox/completed/`:

```
mv {team_inbox}/{message} {team_inbox}/completed/{message}
```

| Message type | Move when... |
|---|---|
| Question | Response sent |
| Contract request | Contract confirmed or issue created |
| QA finding | Fix implemented and re-handoff sent |
| Status update | Read and acknowledged |
| Bug report | Issue created |

The inbox root should only contain unprocessed messages. This keeps every
future scan fast and focused on new work.

---

## Phase 6: Iterate

QA runs verification independently. While waiting:
- Pick the next unblocked issue and begin Phase 2
- Multiple issues can be in-flight at different phases

**When QA responds:**

| QA Verdict | Action |
|-----------|--------|
| Pass | QA moves issue to `completed/` — done |
| Blocked | Return to Phase 0 with QA findings, iterate |
| Need More Info | Return to Phase 0, respond to QA questions |

**Exit condition:** All issues moved to `completed/` by QA, no issues in `queue/`,
no unprocessed inbox messages, no open outbound threads.

---

## Ownership Boundaries

| Action | Owner |
|--------|-------|
| Create issues | Dev |
| Move queue/ → active/ | Dev |
| Move active/ → completed/ | **QA only** |
| Set Status: COMPLETE | **QA only** |
| Run QA verification suite | **QA only** |
| Define backend contracts | Backend-Dev |
| Consume contracts | Frontend-Dev |
| Send cross-team comms | Any role |
