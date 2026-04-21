# Scripts

Scripts that projects wire into their own workflow (cron, systemd, or one-shot tooling).

## `qa_poll_cycle.sh`

Per-issue QA polling loop. See the script head for arguments. Typically used during an active QA push.

## `team-keepalive.sh`

Autonomous hourly-ish keepalive nudge. Checks a team's `inbox/` and `issues/queue/` for pending work; if there's anything to do, resumes the most recent Claude conversation non-interactively via `claude --print --continue`. Writes a timestamped status file to `dev_communication/<team>/status/` each run and garbage-collects status files older than 7 days (tunable).

**Usage:**

```bash
team-keepalive.sh <project_root> <team_id> [--interval-hours N] [--pause-file PATH] [--retention-days N] [--dry-run]
```

**Example cron entry:**

```
*/15 * * * * /path/to/ai_team_config/scripts/team-keepalive.sh /path/to/project fullstack >> /home/user/.claude/keepalive-fullstack.log 2>&1
```

The script self-throttles (`--interval-hours`, default 3) so frequent cron fires only actually invoke Claude at the configured minimum spacing. This lets you run cron often for responsive nudges while keeping token costs bounded.

**Pause the loop** without editing cron:

```bash
touch ~/.claude/pause-keepalive-<team_id>
```

Resume by deleting the pause file.

**Per-team status directory.** The script writes to `dev_communication/<team>/status/`. This directory is declared as `status_dir` on every team profile in `teams/profiles.json` and listed as a required dir in `install.sh`'s compliance check, so a fresh install of any team profile includes it.

**Conversation reuse.** `claude --print --continue` resumes the most recent conversation in the project root. If you run an interactive Claude session in the same directory, the cron nudge will resume that same conversation — consider whether that's what you want. For strict separation, run the cron nudge against a distinct project checkout or cron-dedicated working copy.
