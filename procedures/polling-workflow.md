# Polling Workflow

**Triggers:** "start polling", "poll", "begin polling", "check for work"

This document routes the polling command to the correct lifecycle based on your
active role. It is NOT a passive file-watch — it is the full end-to-end
development or QA workflow executed in a continuous loop.

---

## Step 1: Determine Your Role

Confirm sub-role is established (prompted at session start). Read `team.json` for team paths.
Read `ai_team_config/roles/{sub-role}.yaml` for:
- `role_id` — which lifecycle to follow
- `team_id` — which communication directories to check
- `function` — `dev` or `qa`

## Step 2: Load Your Lifecycle

| Function | Procedure | Checklist |
|----------|-----------|-----------|
| `dev` | `procedures/dev-lifecycle.md` | `teams/checklists/dev-issue-lifecycle-backend.yaml` (backend) or `dev-issue-lifecycle.yaml` (frontend) |
| `qa` | `procedures/qa-lifecycle.md` | `teams/checklists/qa-gate.yaml` |

## Step 3: Execute the Lifecycle Loop

**Dev roles:** Poll comms → assess → plan → contracts → implement → verify →
document → QA handoff → loop back.

**QA roles:** Poll for QA-ready items → validate → verify → review → verdict →
complete or iterate → loop back.

## Step 4: Loop Until Exit

Continue the outer loop until ALL of:
- No unprocessed messages remain in your inbox
- No open outbound threads awaiting replies (see dev-lifecycle.md Phase 0, step 4)
- No issues remain in queue/ or active/
- No new work has arrived since last poll

### Autonomous Polling Rules

- **Do NOT pause to ask the user** before continuing to the next issue, commit, or poll cycle. Execute continuously.
- **QA findings**: When QA returns findings (BLOCKED, FAIL, Need More Info), fix the issues immediately and re-handoff without asking the user.
- **Idle timeout**: If no new work arrives and no QA responses appear for 30 contiguous minutes of polling, stop the loop and report final status to the user.
- **Commits**: Commit completed work in batches as phases finish. Do not ask permission to commit — just commit and continue.
- **Handoff messages**: Always create QA handoff messages in the team inbox immediately after marking an issue DEV_COMPLETE.

---

## What Polling Is NOT

- NOT passive file watching that only reports new files
- NOT running the other role's checks (QA is QA's job, not Dev's)
- NOT a single check — it is a continuous loop with real work between polls
- NOT "continue where you left off" — every iteration restarts from Phase 0
  (inbox scan first, then implementation)
