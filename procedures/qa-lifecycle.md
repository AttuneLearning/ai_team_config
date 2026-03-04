# QA Lifecycle Procedure

**Applies to:** All QA roles (backend-qa, frontend-qa)
**Machine-readable:** `teams/checklists/qa-gate.yaml`

---

## Overview

QA operates independently from Dev. QA polls for work that Dev has handed off,
verifies it meets acceptance criteria, and either approves (moves to completed)
or rejects (sends findings back to Dev for iteration).

```
LOOP: Poll → Validate → Verify → Review → Verdict → Complete or Iterate
```

---

## Phase 0: Poll for QA-Ready Items

**When:** Start of every iteration.

1. Read your team's inbox for new messages
2. Read your team's `issues/active/` for issues marked QA-ready
3. Look for QA-ready markers in issue files:
   - "Development Complete"
   - "Awaiting QA"
   - "QA Ready"
   - "Resolution Notes" (appended by Dev)
   - `QA: PENDING_MANUAL_REVIEW` (automated checks passed, manual review needed)
4. Include issues with `QA: PENDING_MANUAL_REVIEW` — these passed automated
   gates and need manual review to be completed
5. Check for stale blocks: if an issue has `QA: BLOCKED` and the last QA
   verification is older than 12 hours, include it in the candidate set
   for automatic re-check
6. Classify inbox messages:

| Message Type | Action |
|-------------|--------|
| Dev handoff notification | → Phase 1 (validate entry) |
| Dev re-fix after rejection | → Phase 1 (re-validate) |
| Cross-team status update | → Acknowledge |

7. Prioritize: `PENDING_MANUAL_REVIEW` issues first (already passed automated gates),
   then re-fixes of previously blocked issues, then new handoffs

---

## Phase 1: Entry Validation

Before running any checks, confirm the issue is ready:

1. Issue has Status: ACTIVE or DEV_COMPLETE
2. Resolution notes are present (Dev filled these in during Phase 5)
3. Acceptance criteria are defined
4. Dev verification gate results are documented (typecheck, tests)
5. **Freshness check:** Issue has a QA Review Request or Dev Response timestamp
   newer than the last QA verification. Prevents re-running QA on stale stubs.
6. **Implementation evidence:** Issue has commit references, changed files, or
   test additions. If the issue is planning-only (no code evidence), emit
   "Need More Info" — do not run the full gate suite.

**If entry criteria are not met:** Send "Need More Info" back to Dev's inbox
with specific missing items. Do not proceed.

---

## Phase 2: Automated Verification (BLOCKING)

Run the automated test gates. All must pass for the issue to proceed.

### Backend-QA checks:
| Check | Command | Criteria |
|-------|---------|----------|
| Typecheck | `npx tsc --noEmit` | 0 errors |
| Unit tests | `npm run test:unit` | All pass |
| Integration tests | `npm run test:integration` | All pass |
| UAT (contract validation) | `npm run contracts:validate` | All pass |

### Frontend-QA checks:
| Check | Command | Criteria |
|-------|---------|----------|
| Typecheck | `npx tsc --noEmit` | 0 errors |
| Unit tests | `npx vitest run` | All pass |
| Integration tests | `npx vitest run --config integration` | All pass |
| UAT (E2E) | `npx playwright test` | All pass |

**Per-check timeout:** As configured in role yaml (default 120s).

**On all pass (no manual review):** Set `QA: PENDING_MANUAL_REVIEW`. Do NOT send
a message to Dev's inbox — this is not a dev blocker. Move to Phase 4 with
"Pending Manual Review" verdict.

**On failure:** Record which gate failed. Move to Phase 4 with "Blocked" verdict.

---

## Phase 3: Manual Review

Human-judgment checks that automation cannot catch:

| Check | What to Look For |
|-------|-----------------|
| Efficiency | No unnecessary loops, queries, or allocations |
| Accuracy | Logic matches acceptance criteria and spec |
| Non-duplication | No copy-paste code; uses existing patterns/services |
| Security | No injection vectors, proper auth checks, no PII leaks |
| ADR conformance | Follows architectural decisions (check relevant ADRs) |
| Contract alignment | Response shapes match shared contract DTOs exactly |
| Regression scope | Changes don't break unrelated functionality |

**Coverage assessment:**
- Check that acceptance criteria have corresponding tests
- If tests are missing, document which criteria need test coverage
- Include the acceptance-criteria-to-test mapping in your verdict

---

## Phase 4: Verdict & Evidence

Emit one of four verdicts:

| Verdict | When | QA State | Next Step |
|---------|------|----------|-----------|
| **Pass** | All gates green, manual review clean | `PASS` | → Phase 5 (complete) |
| **Pass with Conditions** | Minor issues, non-blocking | `PASS` | → Phase 5 with notes |
| **Pending Manual Review** | All automated gates pass, manual review not done | `PENDING_MANUAL_REVIEW` | → Phase 6 (QA picks up on next iteration) |
| **Blocked** | Automated gate failed OR critical manual finding | `BLOCKED` | → Phase 6 (dev must fix) |
| **Need More Info** | Cannot determine pass/fail | `BLOCKED` | → Phase 6 (iterate) |

**IMPORTANT:** `PENDING_MANUAL_REVIEW` is NOT a dev blocker. Do NOT send findings
to Dev's inbox for this verdict. Dev should ignore issues in this state — they are
QA's responsibility to complete.

**Required evidence for every verdict:**
- Issue reference (ISS-xxx)
- File or route reference
- Automated gate results (pass/fail per gate)
- Coverage assessment (criteria-to-test mapping)
- Manual review notes
- For Blocked/Need More Info: clear unblock criteria

**Severity classification (for findings):**
- Critical: release-blocking, security, data loss
- High: role/capability broken
- Medium: workflow gap, non-blocking contract drift
- Low: minor UX/docs mismatch

**Write the verdict** to the issue file as an appended QA Verification section.

---

## Phase 5: Completion (Pass Only)

**QA owns this phase EXCLUSIVELY.** Dev cannot move issues to completed.

1. Update issue status to COMPLETE
2. Move issue file from `active/` to `completed/`
3. Send completion notification to Dev's inbox
4. If cross-team impact, notify the other team

---

## Phase 6: Iterate

### Pending Manual Review verdict:

1. Issue stays in `active/` with `QA: PENDING_MANUAL_REVIEW`
2. Do NOT send a message to Dev — no dev action is needed
3. QA picks this up on the next iteration (skip automated gates, go directly to Phase 3)

### Blocked or Need More Info verdicts:

1. Send findings to Dev's inbox with:
   - Which gates failed and why
   - Specific unblock criteria
   - Expected behavior vs actual
2. Wait for Dev to re-fix and re-submit
3. When Dev responds, return to Phase 0

**While waiting:** Pick the next QA-ready item and begin Phase 1.

**Exit condition:** All issues in `active/` have been moved to `completed/`,
no unprocessed messages remain in inbox.

---

## Autonomous Mode

The QA polling script supports `--autonomous` mode for unattended operation:

```bash
# Fully autonomous (recommended for unattended runs)
ai_team_config/scripts/qa_poll_cycle.sh --autonomous --manual-ok

# Two-pass mode (manual review separated)
# Pass 1: Run gates, issues reaching all-pass get PENDING_MANUAL_REVIEW
ai_team_config/scripts/qa_poll_cycle.sh --autonomous --once
# Pass 2: After operator reviews, promote to PASS and complete
ai_team_config/scripts/qa_poll_cycle.sh --autonomous --manual-ok --once
```

`--autonomous` implies `--watch --approve --recheck-existing --emit-dev-message`.
Explicit flags (e.g. `--once`, `--no-emit-dev-message`) override these defaults.

See `dev_communication/shared/specs/POLLING_AUTONOMOUS_QA_REVISION.md` for full
specification.

---

## Ownership Boundaries

| Action | Owner |
|--------|-------|
| Run verification gates | QA |
| Perform manual review | QA |
| Emit verdicts | QA |
| Move issue active/ → completed/ | **QA only** |
| Set Status: COMPLETE | **QA only** |
| Write implementation code | **Dev only** |
| Create issues | Dev (QA can create QA-specific blocker issues) |
