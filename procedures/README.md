# Procedures

Universal lifecycle procedures for all AI agent roles.

## Files

| File | Audience | Purpose |
|------|----------|---------|
| `dev-lifecycle.md` | Dev roles | Full loop: scan → assess → contracts → implement → verify → handoff → iterate |
| `qa-lifecycle.md` | QA roles | Full loop: scan → validate → verify → review → verdict → complete → iterate |
| `comms-protocol.md` | All roles | Cross-team communication, contract ownership, message flow |
| `polling-workflow.md` | All roles | Thin redirect to the lifecycle doc for your role function |

## Quick-Start Prompts

Compact, role-specific prompts live in `prompts/claude/` and `prompts/codex/`.
These distill the full lifecycle into a single-page reference for session start.

## Checklists

`teams/checklists/*.yaml` are machine-readable automation configs (commands, timeouts, state transitions).
The procedure docs above are the conversational equivalents. Both must stay in sync.
