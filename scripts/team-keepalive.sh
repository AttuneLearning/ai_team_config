#!/usr/bin/env bash
# =============================================================================
# team-keepalive.sh — autonomous keepalive nudge for a team's dev + QA loop
# =============================================================================
#
# Cron-driven, non-interactive. Each run:
#
#   1. Respects a pause signal (skip if pause file exists).
#   2. Garbage-collects status files older than --retention-days (default 7).
#   3. Throttles by --interval-hours (default 3): if the previous successful
#      invocation was less than that long ago, skip this firing.
#   4. Scans for pending work:
#        - dev_communication/<team>/inbox/           (unprocessed messages)
#        - dev_communication/<team>/issues/queue/    (issues waiting to start)
#   5. Writes a timestamped status file at dev_communication/<team>/status/
#      with the scan results.
#   6. If pending work exists, invokes `claude --print --continue` as the
#      team's dev sub-role. The prompt asks Claude to process the work,
#      commit + push, and append findings to the status file.
#   7. If --run-qa-after-dev is set AND Claude's dev run succeeded, invokes
#      the Codex CLI as the team's QA sub-role. The Codex prompt is the
#      <team>-qa-autonomous-sweep.md from the submodule, with a
#      non-interactive directive appended so Codex exits cleanly.
#      If Claude didn't run (no pending work, throttled, paused, or failed),
#      QA is skipped.
#   8. Records the outcome of both runs in the status file.
#
# Recommended cron cadence: every 15 minutes. The script self-throttles to
# the --interval-hours value, so frequent cron fires are cheap.
#
# =============================================================================
#
# Usage:
#   team-keepalive.sh <project_root> <team_id> [options]
#
# Options:
#   --interval-hours N      Minimum hours between dev invocations (default: 3)
#   --pause-file PATH       Skip run if this file exists (default: ~/.claude/pause-keepalive-<team_id>)
#   --retention-days N      Delete status files older than this (default: 7)
#   --run-qa-after-dev      Invoke Codex as <team>-qa after a successful
#                           Claude dev run. Skipped if Claude didn't run.
#                           Default: disabled (opt-in).
#   --no-qa-after-dev       Explicit override when the default changes.
#   --claude-cmd "cmd"      Dev CLI invocation (default: `claude --print --continue`).
#   --codex-cmd "cmd"       QA CLI invocation (default: `codex exec`).
#                           Adjust if your Codex CLI takes different flags.
#   --dry-run               Print what would happen; do not invoke any CLI.
#   -h | --help             Show this help
#
# Example cron entry:
#   */15 * * * * /home/adam/github/soundsafe/ai_team_config/scripts/team-keepalive.sh /home/adam/github/soundsafe fullstack --run-qa-after-dev >> /home/adam/.claude/keepalive-fullstack.log 2>&1
#
# Pause the loop without editing cron:
#   touch ~/.claude/pause-keepalive-fullstack
# Resume:
#   rm ~/.claude/pause-keepalive-fullstack
#
# =============================================================================

set -euo pipefail

PROJECT_ROOT=""
TEAM_ID=""
INTERVAL_HOURS=3
PAUSE_FILE=""
RETENTION_DAYS=7
DRY_RUN=0
RUN_QA_AFTER_DEV=0
CLAUDE_CMD="claude --print --continue"
CODEX_CMD="codex exec"

usage() {
  sed -n '2,60p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --interval-hours)   INTERVAL_HOURS="$2"; shift 2 ;;
    --pause-file)       PAUSE_FILE="$2"; shift 2 ;;
    --retention-days)   RETENTION_DAYS="$2"; shift 2 ;;
    --run-qa-after-dev) RUN_QA_AFTER_DEV=1; shift ;;
    --no-qa-after-dev)  RUN_QA_AFTER_DEV=0; shift ;;
    --claude-cmd)       CLAUDE_CMD="$2"; shift 2 ;;
    --codex-cmd)        CODEX_CMD="$2"; shift 2 ;;
    --dry-run)          DRY_RUN=1; shift ;;
    -h|--help)          usage 0 ;;
    --*)
      echo "Error: unknown option: $1" >&2
      usage 2
      ;;
    *)
      if [[ -z "$PROJECT_ROOT" ]]; then
        PROJECT_ROOT="$1"
      elif [[ -z "$TEAM_ID" ]]; then
        TEAM_ID="$1"
      else
        echo "Error: unexpected positional arg: $1" >&2
        usage 2
      fi
      shift
      ;;
  esac
done

if [[ -z "$PROJECT_ROOT" || -z "$TEAM_ID" ]]; then
  echo "Error: <project_root> and <team_id> are required" >&2
  usage 2
fi

PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd -P)"
TEAM_DIR="$PROJECT_ROOT/dev_communication/$TEAM_ID"
INBOX_DIR="$TEAM_DIR/inbox"
QUEUE_DIR="$TEAM_DIR/issues/queue"
STATUS_DIR="$TEAM_DIR/status"
PAUSE_FILE="${PAUSE_FILE:-$HOME/.claude/pause-keepalive-$TEAM_ID}"
LAST_RUN_FILE="$HOME/.claude/keepalive-lastrun-$TEAM_ID"
mkdir -p "$(dirname "$LAST_RUN_FILE")"

log() {
  local ts
  ts="$(date -u +%FT%TZ)"
  echo "[$ts] [$TEAM_ID] $*" >&2
}

# ---------------------------------------------------------------------------
# 1. Pause signal
# ---------------------------------------------------------------------------
if [[ -f "$PAUSE_FILE" ]]; then
  log "PAUSE: $PAUSE_FILE exists — skipping"
  exit 0
fi

# ---------------------------------------------------------------------------
# 2. Validate project root / team dir
# ---------------------------------------------------------------------------
if [[ ! -d "$TEAM_DIR" ]]; then
  log "ERROR: team dir not found: $TEAM_DIR"
  exit 1
fi
mkdir -p "$STATUS_DIR"

# ---------------------------------------------------------------------------
# 3. Garbage-collect old status files (always runs, even if we later skip)
# ---------------------------------------------------------------------------
if [[ -d "$STATUS_DIR" ]]; then
  # Only target the naming pattern we own; leave .gitkeep + anything else alone.
  mapfile -t OLD_FILES < <(find "$STATUS_DIR" -maxdepth 1 -type f -name '*_status.md' -mtime +"$RETENTION_DAYS" -print)
  if [[ "${#OLD_FILES[@]}" -gt 0 ]]; then
    for f in "${OLD_FILES[@]}"; do rm -f "$f"; done
    log "GC: removed ${#OLD_FILES[@]} status file(s) older than $RETENTION_DAYS days"
  fi
fi

# ---------------------------------------------------------------------------
# 4. Interval throttle
# ---------------------------------------------------------------------------
NOW="$(date +%s)"
MIN_INTERVAL_SEC=$(( INTERVAL_HOURS * 3600 ))
if [[ -f "$LAST_RUN_FILE" ]]; then
  LAST_RUN="$(cat "$LAST_RUN_FILE")"
  DELTA=$(( NOW - LAST_RUN ))
  if [[ "$DELTA" -lt "$MIN_INTERVAL_SEC" ]]; then
    log "THROTTLED: last run ${DELTA}s ago, interval is ${MIN_INTERVAL_SEC}s — skipping"
    exit 0
  fi
fi

# ---------------------------------------------------------------------------
# 5. Scan inbox + queue for pending work
# ---------------------------------------------------------------------------
count_work_files() {
  local dir="$1"
  [[ -d "$dir" ]] || { echo 0; return; }
  # Count top-level, non-hidden, non-.gitkeep files.
  find "$dir" -maxdepth 1 -type f ! -name '.gitkeep' ! -name '.*' -printf '.' 2>/dev/null | wc -c
}

list_work_files() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  find "$dir" -maxdepth 1 -type f ! -name '.gitkeep' ! -name '.*' -printf '- %f\n' 2>/dev/null | sort
}

INBOX_COUNT="$(count_work_files "$INBOX_DIR")"
QUEUE_COUNT="$(count_work_files "$QUEUE_DIR")"
TOTAL=$(( INBOX_COUNT + QUEUE_COUNT ))

# ---------------------------------------------------------------------------
# 6. Write initial status file
# ---------------------------------------------------------------------------
# Filesystem-safe ISO 8601: 2026-04-21T02-00-00Z
TIMESTAMP="$(date -u +%FT%H-%M-%SZ)"
STATUS_FILE="$STATUS_DIR/${TIMESTAMP}_status.md"
RUN_ISO="$(date -u +%FT%TZ)"

{
  echo "# Keepalive status — $RUN_ISO"
  echo
  echo "**Team:** $TEAM_ID"
  echo "**Project:** $(basename "$PROJECT_ROOT")"
  echo "**Source:** \`team-keepalive.sh\`"
  echo "**Retention:** status files older than $RETENTION_DAYS days are auto-deleted"
  echo
  echo "## Scan results"
  echo
  echo "- Inbox (\`$TEAM_DIR/inbox\`): **$INBOX_COUNT** pending message(s)"
  if [[ "$INBOX_COUNT" -gt 0 ]]; then
    list_work_files "$INBOX_DIR"
  fi
  echo "- Queue (\`$TEAM_DIR/issues/queue\`): **$QUEUE_COUNT** pending issue(s)"
  if [[ "$QUEUE_COUNT" -gt 0 ]]; then
    list_work_files "$QUEUE_DIR"
  fi
  echo "- **Total pending: $TOTAL**"
  echo
} > "$STATUS_FILE"

# ---------------------------------------------------------------------------
# 7. Decide whether to invoke Claude
# ---------------------------------------------------------------------------
if [[ "$TOTAL" -eq 0 ]]; then
  {
    echo "## Action"
    echo
    echo "- Claude invoked: **no** (no pending work detected)"
    echo "- Last-run timestamp **not** updated — throttle does not apply to no-op runs"
  } >> "$STATUS_FILE"
  log "SKIP: no pending work; status written to $STATUS_FILE"
  exit 0
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  {
    echo "## Action"
    echo
    echo "- Claude invoked: **no** (dry run)"
    echo "- Would have invoked \`$CLAUDE_CMD\` at $RUN_ISO"
    if [[ "$RUN_QA_AFTER_DEV" -eq 1 ]]; then
      echo "- Codex QA invoked: **no** (dry run)"
      echo "- Would have invoked \`$CODEX_CMD\` after a successful Claude run"
    fi
  } >> "$STATUS_FILE"
  log "DRY-RUN: would invoke Claude for $TOTAL pending item(s); status $STATUS_FILE"
  exit 0
fi

# ---------------------------------------------------------------------------
# 8. Invoke Claude non-interactively
# ---------------------------------------------------------------------------
{
  echo "## Action"
  echo
  echo "- Claude invoked: **yes** at $RUN_ISO"
  echo "- Prompt: process pending inbox/queue per team lifecycle; append findings below"
  echo
  echo "## Claude's findings"
  echo
  echo "_(Populated by Claude during this run. If this section stays empty, the Claude run failed or was interrupted; see \`$HOME/.claude/keepalive-$TEAM_ID.log\`.)_"
  echo
} >> "$STATUS_FILE"

log "INVOKE: $TOTAL pending item(s) ($INBOX_COUNT inbox + $QUEUE_COUNT queue); status $STATUS_FILE"

CLAUDE_PROMPT=$(cat <<PROMPT_EOF
Autonomous keepalive run (team: $TEAM_ID).

The \`team-keepalive.sh\` cron job detected $INBOX_COUNT unprocessed message(s) in \`$TEAM_DIR/inbox\` and $QUEUE_COUNT pending issue(s) in \`$TEAM_DIR/issues/queue\`. Your job: process them per the team's lifecycle, then append your findings to the status file at:

    $STATUS_FILE

Procedure:

1. **Pick your sub-role.** Read \`team.json\` for \`allowed_sub_roles\` and \`AGENTS.md\` / \`CLAUDE.md\` for project context. Choose based on what the work needs:
   - Inbox has QA verdict or QA message addressed to dev → act as the dev sub-role
   - Inbox has dev handoff → act as the QA sub-role
   - Queue has a new issue → act as the dev sub-role
   Default: the dev sub-role.

2. **Process pending items** per \`ai_team_config/procedures/dev-lifecycle.md\` (or \`qa-lifecycle.md\` if you chose QA). Commit and push each completed unit. Do not prompt the user; this is non-interactive.

3. **Append to the status file** at \`$STATUS_FILE\`. Add a section under the \`## Claude's findings\` heading:

   ### What I did
   - (one bullet per issue/message processed, with commit hashes if code changed)

   ### Next actions
   - (one bullet per planned next step — what should happen on the next keepalive tick)

   ### Blockers
   - (any unresolved blockers — note if QA is needed, if Adam's input is needed, if a dependency is missing)

4. Commit the status file update alongside your other work if code changed; otherwise commit it alone with a short message. Push.

If there is nothing genuinely actionable (e.g., all pending items are handoffs from this Claude that are awaiting QA, or QA verdicts that need Adam's judgment), record that in "Next actions" and exit. Do NOT loop forever; this is a single-run nudge.
PROMPT_EOF
)

cd "$PROJECT_ROOT"

# Use printf to stream the prompt to claude's stdin; --print makes it
# non-interactive, --continue resumes the most recent conversation in cwd.
# shellcheck disable=SC2086  # CLAUDE_CMD intentionally word-splits
if printf '%s\n' "$CLAUDE_PROMPT" | $CLAUDE_CMD 2>&1 | tee -a "$HOME/.claude/keepalive-$TEAM_ID.log"; then
  CLAUDE_EXIT=0
else
  CLAUDE_EXIT="${PIPESTATUS[1]:-$?}"
fi

if [[ "$CLAUDE_EXIT" -eq 0 ]]; then
  log "SUCCESS: Claude dev run completed"
  echo "$NOW" > "$LAST_RUN_FILE"
else
  log "ERROR: Claude dev run exited $CLAUDE_EXIT"
  {
    echo
    echo "### Keepalive error"
    echo
    echo "Claude CLI exited with code \`$CLAUDE_EXIT\`. See \`$HOME/.claude/keepalive-$TEAM_ID.log\` for stdout/stderr."
    echo
    echo "_(Codex QA run skipped — dev side failed.)_"
  } >> "$STATUS_FILE"
  # Do NOT update last-run on failure — let the next cron tick retry
  # immediately instead of waiting the full interval.
  exit "$CLAUDE_EXIT"
fi

# ---------------------------------------------------------------------------
# 9. Optional: invoke Codex QA after successful Claude dev run
# ---------------------------------------------------------------------------
if [[ "$RUN_QA_AFTER_DEV" -ne 1 ]]; then
  log "DONE (dev only; QA skipped per config)"
  exit 0
fi

CODEX_PROMPT_FILE="$PROJECT_ROOT/ai_team_config/prompts/codex/${TEAM_ID}-qa-autonomous-sweep.md"
if [[ ! -f "$CODEX_PROMPT_FILE" ]]; then
  log "WARN: Codex QA prompt not found at $CODEX_PROMPT_FILE — skipping QA run"
  {
    echo
    echo "## Codex QA run"
    echo
    echo "- Invoked: **no** (QA autonomous-sweep prompt not found at \`$CODEX_PROMPT_FILE\`)"
    echo "- Skipped; dev run already succeeded"
  } >> "$STATUS_FILE"
  exit 0
fi

QA_RUN_ISO="$(date -u +%FT%TZ)"
log "INVOKE: Codex QA after successful dev run; prompt $CODEX_PROMPT_FILE"

{
  echo
  echo "## Codex QA run"
  echo
  echo "- Invoked: **yes** at $QA_RUN_ISO"
  echo "- Prompt source: \`$CODEX_PROMPT_FILE\` + non-interactive directive"
  echo "- CLI: \`$CODEX_CMD\`"
  echo
  echo "### Codex's findings"
  echo
  echo "_(Populated by Codex during this run. If this section stays empty, the Codex run failed; see \`$HOME/.claude/keepalive-$TEAM_ID.log\`.)_"
  echo
} >> "$STATUS_FILE"

# Build the QA prompt: the autonomous-sweep prompt + keepalive directive
# pointing at this status file. The Codex agent reads its own prompt and
# then knows to append findings here.
CODEX_PROMPT=$(cat <<PROMPT_EOF
$(cat "$CODEX_PROMPT_FILE")

---

## Additional directive (from team-keepalive.sh)

This is a non-interactive keepalive run. A successful dev-side Claude run just
completed at $RUN_ISO. Your job now: process any fresh dev handoffs in
\`$TEAM_DIR/inbox\` per the sweep above, render verdicts, and exit cleanly.

When you finish, append your findings to the status file at:

    $STATUS_FILE

Under the \`### Codex's findings\` heading, record:

- **Issues processed:** one bullet per issue with verdict (PASS / PASS WITH CONDITIONS / BLOCKED / NEED MORE INFO) and the FS-ISS id.
- **Commits:** any new commits made by QA (e.g., moving issues to completed/, writing QA verification sections).
- **Blockers surfaced:** anything that needs Dev attention on the next tick.
- **Next actions:** what the next keepalive tick should expect.

Commit the status-file update. Do NOT loop forever; this is a single-run sweep.
PROMPT_EOF
)

# shellcheck disable=SC2086  # CODEX_CMD intentionally word-splits
if printf '%s\n' "$CODEX_PROMPT" | $CODEX_CMD 2>&1 | tee -a "$HOME/.claude/keepalive-$TEAM_ID.log"; then
  CODEX_EXIT=0
else
  CODEX_EXIT="${PIPESTATUS[1]:-$?}"
fi

if [[ "$CODEX_EXIT" -eq 0 ]]; then
  log "SUCCESS: Codex QA run completed"
else
  log "ERROR: Codex QA run exited $CODEX_EXIT"
  {
    echo
    echo "### Codex QA error"
    echo
    echo "Codex CLI exited with code \`$CODEX_EXIT\`. See \`$HOME/.claude/keepalive-$TEAM_ID.log\` for stdout/stderr."
    echo
    echo "_(Dev run succeeded; only QA failed. Next keepalive tick will retry QA.)_"
  } >> "$STATUS_FILE"
  # Don't fail the whole script — dev work succeeded and is pushed. Just
  # record the QA failure for the next tick to retry.
fi

log "DONE"
