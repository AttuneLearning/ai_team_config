# Polling Workflow

**Triggers:** "start polling", "poll", "begin polling", "check for work"

This is a **continuous loop**, not a single check. It runs until 30 consecutive
minutes pass with no work found.

---

## Prerequisites

1. Sub-role established (prompted at session start)
2. `team.json` read for paths
3. Role YAML loaded for function (dev/qa), inbox paths, lifecycle procedure

---

## The Loop

```
┌─────────────────────────────────────────────────┐
│                POLL ITERATION                    │
│                                                  │
│  1. SCAN (read every message + all issues)       │
│  2. TRIAGE (classify, output table)              │
│  3. WORK (implement, respond, hand off)          │
│  4. CLEANUP (move completed messages)            │
│  5. Did you do any work this iteration? ─────┐   │
│        │                              │      │   │
│       YES                             NO     │   │
│        │                              │      │   │
│   Reset idle timer              Start/continue   │
│        │                        idle timer   │   │
│        │                              │      │   │
│        │                    30 min idle? ─┐  │   │
│        │                     │        │   │  │   │
│        │                    NO       YES  │  │   │
│        │                     │        │   │  │   │
│        └─── LOOP BACK ───────┘    EXIT ───┘  │   │
│             to step 1                        │   │
└─────────────────────────────────────────────────┘
```

---

## Step 1: SCAN

Read ALL of the following. "Read" means open the file and read its contents.

### 1a. Your team inbox (BLOCKING)

```
ls {team_inbox}/          (exclude completed/ subdirectory)
Read CONTENTS of every file.
```

Only files in the inbox root need reading — `inbox/completed/` contains
already-handled messages and should NOT be re-scanned.

### 1b. Your issue directories

```
ls {issues}/queue/
ls {issues}/active/
Read CONTENTS of every file in both.
```

Do NOT dismiss issues based on "Assigned To" metadata. Read the contents
and determine if YOUR role has action items.

### 1c. Verification

Before proceeding, you MUST output a triage summary:

```
## Poll Iteration [N] — [timestamp]

Inbox: [X] messages read, [Y] actionable
Queue: [X] issues
Active: [X] issues
New work found: YES/NO
```

If you cannot produce this summary, you skipped the scan. Go back to 1a.

---

## Step 2: TRIAGE

For each actionable item found in the scan, classify it:

| Message Type | Action |
|-------------|--------|
| Contract request | Respond with contract or create issue |
| QA finding / rejection | Match to active issue, prioritize re-fix |
| Bug report from other team | Assess, create issue if needed |
| Reply to outbound request | Match to original thread, unblock issue |
| Question from other team | Respond directly |
| Status update | Acknowledge, no action unless blocking |

---

## Step 3: WORK

Execute the appropriate lifecycle for your role:

| Function | Lifecycle | Checklist |
|----------|-----------|-----------|
| `dev` | `procedures/dev-lifecycle.md` | `teams/checklists/dev-issue-lifecycle-backend.yaml` (backend) or `dev-issue-lifecycle.yaml` (frontend) |
| `qa` | `procedures/qa-lifecycle.md` | `teams/checklists/qa-gate.yaml` |

Process ALL actionable items found in the scan before looping back.
Do not loop back with unprocessed work sitting in the triage table.

---

## Step 4: CLEANUP

After processing messages, move completed ones out of the inbox:

```
mv {team_inbox}/{message} {team_inbox}/completed/{message}
```

### Move criteria

| Message type | Move to completed/ when... |
|---|---|
| Question | Response sent to other team's inbox |
| Contract request | Contract confirmation sent, or issue created |
| QA finding | Fix implemented and re-handoff sent |
| Status update | Read and acknowledged |
| Bug report | Issue created in queue/ or active/ |

**Why this matters:** The inbox should only contain unprocessed messages.
Without cleanup, every scan re-reads 60+ handled messages to find the 2 new
ones — making it easy to miss them and slow to complete.

### Directory structure

Both teams use the same layout:

```
dev_communication/{team}/inbox/              ← unprocessed messages only
dev_communication/{team}/inbox/completed/    ← responded/acknowledged messages
```

---

## Step 5: LOOP DECISION

After completing all work from this iteration:

- **Work was done** → Reset idle timer to 0. Go to Step 1.
- **No work found** → Idle timer continues. If idle timer < 30 minutes, wait
  briefly then go to Step 1. If idle timer >= 30 minutes, EXIT.

---

## Exit

When exiting the loop, output a final status report:

```
## Polling Complete — [timestamp]

Iterations: [N]
Work items processed: [list]
Issues created: [list]
Messages sent: [list]
Messages moved to completed: [count]
Remaining in inbox: [count]
Remaining in queue/active: [list]
Reason for exit: 30-minute idle timeout / no remaining work
```

---

## Autonomous Rules

- **Do NOT pause to ask the user** before continuing to the next issue, commit, or poll cycle
- **QA findings**: Fix immediately and re-handoff without asking
- **Commits**: Commit completed work as phases finish — do not ask permission
- **Handoff messages**: Always send QA handoff messages immediately after DEV_COMPLETE
- **New messages mid-session**: The loop catches these because Step 1 re-scans every iteration
- **Cleanup**: Move processed messages to completed/ after each work phase — do not leave them in inbox

---

## What Polling Is NOT

- NOT a single pass that stops when the first scan finds nothing
- NOT listing filenames — it requires reading file contents
- NOT skipping files because you "already know" what they say
- NOT dismissing issues based on metadata without reading them
- NOT leaving answered messages in the inbox to pile up
