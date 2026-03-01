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

1. Read your team's inbox for new messages
2. Read your team's `issues/queue/` for unstarted issues
3. Read your team's `issues/active/` for in-progress or QA-blocked issues
4. Classify each inbox message:

| Message Type | Action |
|-------------|--------|
| Contract request | → Phase 1 (define contracts) |
| Implementation plan / crosswalk | → Phase 0b (assess & decompose) |
| QA finding / rejection | → Match to active issue, prioritize re-fix |
| Bug report from other team | → Phase 0b (assess, create issue) |
| Status update | → Acknowledge, no action unless blocking |

5. Match QA findings and cross-team requests to active issues
6. Unblock issues where dependencies are resolved

---

## Phase 0b: Assess & Decompose

**When:** New plan, crosswalk, large request, or multi-endpoint feature — anything
that is NOT a single issue.

1. Read the full request/plan document
2. Identify distinct work items (new endpoints, enhancements, bug fixes, confirmations)
3. Group into implementation phases ordered by dependency and priority
4. Create a plan document in `dev_communication/shared/plans/` if one doesn't exist
5. Create individual issues in your team's `issues/queue/` for each work item
6. Note dependencies between issues (which issues block which)
7. Proceed to Phase 1 with the full set of issues

**Rules:**
- Every actionable item becomes a tracked issue
- Phase ordering respects dependencies (contracts before implementation)
- Plan documents live in `dev_communication/shared/plans/`
- Issues reference the plan document for traceability

---

## Phase 1: Contracts & Cross-Team Setup

**When:** New or changed endpoints are needed (either from a plan or a single request).

### For Backend-Dev (contract owner):
1. Read cross-team contract requests from your inbox
2. Read `contracts/types/` for existing DTOs
3. For EACH new/changed endpoint across ALL planned issues:
   - Define the contract DTO in `contracts/types/`
   - Include request shape, response shape, query params, error cases
4. Send ONE consolidated contract confirmation to the other team's inbox
5. Include: endpoint paths, DTO details, implementation timeline/ordering

### For Frontend-Dev (contract consumer):
1. Check `contracts/types/` for available DTOs
2. If a contract is missing or insufficient, send a request to backend's inbox
3. Never invent local type shapes that differ from the contract
4. Never write normalizers, transforms, or compatibility shims

**Key rule:** Backend defines contracts, frontend consumes them. For plans with
multiple endpoints, send ALL contracts upfront so the other team is not waiting.

**Reference:** ADR-DEV-004-CONSUME-CONTRACTS-DIRECTLY-NO-NORMALIZERS

---

## Phase 2: Context Loading

1. Load relevant ADRs from `dev_communication/shared/architecture/decisions/`
2. Load memory patterns from `memory/patterns/` (or equivalent memory store)
3. Read the issue file for acceptance criteria and any prior QA findings
4. Identify which ADRs apply by change type
5. Review existing code in the affected domain (models, services, routes)

**Skill:** `/context` (if available on platform)

---

## Phase 3: Implementation

1. Move issue from `queue/` to `active/` (if not already active)
2. Plan if complex (schema migration, multi-service change, new middleware)
3. Implement the feature/fix following project architecture
4. Ensure response shapes match contract DTOs exactly
5. Write tests for new functionality as part of implementation
6. If this is a QA re-fix, address the specific QA findings before re-verifying

**Rules:**
- New functionality MUST have corresponding tests
- Response shapes MUST match shared contract DTOs
- Validate at system boundaries (request input, external APIs)
- Do not add backward-compatibility shims or deprecated fields
- When spawning sub-agents, include testing requirements

---

## Phase 4: Dev Verification Gate (BLOCKING)

All checks must pass. Do NOT hand off to QA with failures.

### Backend-Dev checks:
| Check | Command | Criteria |
|-------|---------|----------|
| Typecheck | `npx tsc --noEmit` | 0 errors |
| Unit tests | `npm run test:unit` | All pass |
| Integration tests | `npm run test:integration` | All pass |
| Tests exist | (manual) | New functionality has tests |

### Frontend-Dev checks:
| Check | Command | Criteria |
|-------|---------|----------|
| Typecheck | `npx tsc --noEmit` | 0 errors |
| Unit tests | `npx vitest run` | All pass |
| Integration tests | `npx vitest run --config integration` | All pass |
| Tests exist | (manual) | New functionality has tests |

**On failure:** Fix and re-run. Do not proceed to Phase 5.

---

## Phase 5: Documentation & Handoff

1. Create session file at `memory/sessions/{date}-{issue-slug}.md`
2. Append resolution notes to the issue file
3. If contract was added/changed, confirm contract types are updated
4. If new pattern discovered, update memory patterns or suggest ADR
5. If cross-team impact, send message to other team's inbox
6. Commit and push

**Handoff rule (CRITICAL):**
- Issue stays in `active/` with Status: ACTIVE
- Do NOT move to `completed/`. Do NOT set Status: COMPLETE.
- QA owns Phase 6 (verification) and Phase 7 (completion).
- Dev does NOT run QA gate checks — that is QA's job.

---

## Phase 6: Wait for QA

Dev does not act here. QA runs their qa-gate lifecycle independently.

**While waiting:** Do NOT idle. Pick the next unblocked issue from `queue/` or
`active/` and begin Phase 2 for that issue. Multiple issues can be in-flight
at different phases simultaneously.

**This phase ends when:**
- QA writes back to your inbox with a verdict, OR
- QA updates the issue file with findings

**Outcomes:**
| QA Verdict | Action |
|-----------|--------|
| Pass | QA moves issue to `completed/` — done |
| Blocked | Return to Phase 0 with QA findings, iterate |
| Need More Info | Return to Phase 0, respond to QA questions |

---

## Phase 7: Iterate

Loop back to Phase 0 (outer loop). The inbox will contain any QA findings,
new cross-team requests, or new work.

**Exit condition:** All issues in `active/` have been moved to `completed/` by QA,
AND no issues remain in `queue/`, AND no unprocessed messages remain in inbox.

---

## Ownership Boundaries

| Action | Owner |
|--------|-------|
| Create issues | Dev |
| Move issue queue/ → active/ | Dev |
| Move issue active/ → completed/ | **QA only** |
| Set Status: COMPLETE | **QA only** |
| Run QA verification suite | **QA only** |
| Define backend contracts | Backend-Dev |
| Consume contracts | Frontend-Dev |
| Send cross-team comms | Any role |
