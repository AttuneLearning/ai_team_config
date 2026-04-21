# Scripts

Scripts that projects wire into their own workflow (cron, systemd, or one-shot tooling).

## `qa_poll_cycle.sh`

Per-issue QA polling loop. See the script head for arguments. Typically used during an active QA push.

## `fullstack_qa_poll_cycle.sh`

Fullstack-QA polling loop for the consolidated `fullstack` team profile. It scans `dev_communication/fullstack/`, matches canonical `FS-ISS-*` handoffs, runs the fullstack automated gate sweep, writes QA blocked responses back to the shared inbox, and archives only the inbound dev handoff messages it consumed.

## `team-keepalive.sh`

Autonomous hourly-ish keepalive nudge. Checks a team's `inbox/` and `issues/queue/` for pending work; if there's anything to do, resumes the most recent Claude conversation as the team's **dev** sub-role via `claude --print --continue`. Optionally (`--run-qa-after-dev`) invokes **Codex** as the team's **QA** sub-role after a successful dev run, to process dev handoffs, render verdicts, and close passing issues. Writes a timestamped status file to `dev_communication/<team>/status/` each run and garbage-collects status files older than 7 days (tunable).

**Usage:**

```bash
team-keepalive.sh <project_root> <team_id> [options]
```

**Options:**

| Flag | Default | Purpose |
|---|---|---|
| `--interval-hours N` | `3` | Minimum hours between dev invocations (self-throttle) |
| `--pause-file PATH` | `~/.claude/pause-keepalive-<team>` | Skip run if this file exists |
| `--retention-days N` | `7` | Delete status files older than this |
| `--run-qa-after-dev` | off | Invoke Codex QA after a successful Claude dev run |
| `--no-qa-after-dev` | — | Explicit override |
| `--claude-cmd "cmd"` | `claude --print --continue` | Dev CLI invocation |
| `--codex-cmd "cmd"` | `codex exec` | QA CLI invocation — adjust for your Codex CLI version |
| `--dry-run` | off | Print what would happen; do not invoke any CLI |

**Example cron entry (dev only):**

```
*/15 * * * * /path/to/ai_team_config/scripts/team-keepalive.sh /path/to/project fullstack >> /home/user/.claude/keepalive-fullstack.log 2>&1
```

**Example cron entry (dev + QA pairing):**

```
*/15 * * * * /path/to/ai_team_config/scripts/team-keepalive.sh /path/to/project fullstack --run-qa-after-dev >> /home/user/.claude/keepalive-fullstack.log 2>&1
```

The script self-throttles (`--interval-hours`, default 3) so frequent cron fires only actually invoke the CLIs at the configured minimum spacing. Frequent cron → responsive nudges; interval → bounded token cost.

**Dev → QA pairing semantics.**

When `--run-qa-after-dev` is set, each cron tick does:

1. Scan inbox + queue. If nothing pending → exit, no CLIs invoked.
2. If pending → invoke Claude as the team's dev sub-role. Claude processes, commits, pushes, appends findings to the status file.
3. If Claude succeeded (exit 0) → invoke Codex as the team's QA sub-role using the prompt at `ai_team_config/prompts/codex/<team>-qa-autonomous-sweep.md`. Codex reviews the fresh handoffs, runs gates, renders verdicts, and appends its own findings section to the same status file.
4. If Claude failed → skip QA. Dev errors surface first; QA doesn't review broken work.

The prompt file for Codex QA is resolved as `<team_id>-qa-autonomous-sweep.md`. For a fullstack team, that's `fullstack-qa-autonomous-sweep.md`. If the file doesn't exist (older team profiles without a sweep prompt), QA is skipped with a warning and the dev-only side still completes successfully.

**Codex CLI invocation.** The default `codex exec` is a best-guess and may need adjustment for your specific Codex CLI version. Override with `--codex-cmd "<your-cli> <args>"`. Codex does not need a `--continue`-equivalent — QA sweeps start fresh each tick, which is cleaner for verdict rendering.

**Pause the loop** without editing cron:

```bash
touch ~/.claude/pause-keepalive-<team_id>
```

Resume by deleting the pause file. The pause file blocks both the dev and QA sides.

**Per-team status directory.** The script writes to `dev_communication/<team>/status/`. This directory is declared as `status_dir` on every team profile in `teams/profiles.json` and listed as a required dir in `install.sh`'s compliance check, so a fresh install of any team profile includes it.

**Conversation reuse (Claude only).** `claude --print --continue` resumes the most recent conversation in the project root. If you run an interactive Claude session in the same directory, the cron nudge will resume that same conversation — consider whether that's what you want. For strict separation, run the cron nudge against a distinct project checkout. Codex starts fresh each run, so QA doesn't have this concern.
