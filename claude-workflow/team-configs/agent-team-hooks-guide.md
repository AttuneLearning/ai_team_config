# Agent Team Hooks Guide

## Overview

Quality gate hooks that enforce code-reviewer-config.json criteria when agent teams are active. These hooks run automatically via Claude Code's hook system - they are NOT advisory markdown files.

## Hook Scripts

### TaskCompleted (`task-completed.sh`)

- **Location**: `.claude/hooks/task-completed.sh` (project-level, must be executable)
- **Fires**: When any teammate marks a task as completed
- **No matcher**: Fires on every task completion
- **Enforces**:
  1. TypeScript compilation (`npx tsc --noEmit`)
  2. Tests pass for modified source files
  3. Test files exist for implementation tasks
- **Exit 2**: Blocks completion, stderr fed back to teammate as instructions
- **Exit 0**: Allows completion
- **Timeout**: 120 seconds

### TeammateIdle (`teammate-idle.sh`)

- **Location**: `.claude/hooks/teammate-idle.sh` (project-level, must be executable)
- **Fires**: When a teammate is about to go idle (stop working)
- **No matcher**: Fires on every idle event
- **Enforces**:
  1. No TypeScript errors remain
  2. Modified source files have corresponding test changes
- **Exit 2**: Keeps teammate working, stderr fed back as instructions
- **Exit 0**: Allows idle
- **Timeout**: 30 seconds

## Setup

Add to `.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "hooks": {
    "TaskCompleted": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/task-completed.sh",
            "timeout": 120
          }
        ]
      }
    ],
    "TeammateIdle": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/teammate-idle.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

## Hook Input Format

Both hooks receive JSON via stdin with these fields:

### TaskCompleted Input
| Field | Description |
|-------|-------------|
| `task_id` | Identifier of the task being completed |
| `task_subject` | Title of the task |
| `task_description` | Detailed description (may be absent) |
| `teammate_name` | Name of the completing teammate (may be absent) |
| `team_name` | Name of the team (may be absent) |
| `cwd` | Current working directory |
| `session_id` | Current session identifier |

### TeammateIdle Input
| Field | Description |
|-------|-------------|
| `teammate_name` | Name of the teammate going idle |
| `team_name` | Name of the team |
| `cwd` | Current working directory |
| `session_id` | Current session identifier |

## Team Detection

Both hooks detect the team from `cwd` in the JSON input:

| Path contains | Team | Test command |
|---------------|------|-------------|
| `cadencelms_ui` | UI | `npx vitest run` |
| `cadencelms_api` | API | `npm run test:unit` |

## Gate Criteria Reference

From `code-reviewer-config.json`:

| Criterion | Hook | Automated | Blocking |
|-----------|------|-----------|----------|
| TypeScript 0 errors | TaskCompleted + TeammateIdle | Yes (`tsc --noEmit`) | Yes |
| Tests pass | TaskCompleted | Yes (vitest/npm test) | Yes |
| Tests exist | TaskCompleted | Yes (git diff check) | Yes |
| Modified files have test changes | TeammateIdle | Yes (git diff check) | Yes |
| Session file created | N/A (lead handles) | No | Yes |
| Issue updated | N/A (lead handles) | No | Yes |

## Decision Control

These hooks use **exit codes only** - no JSON decision output:

- **Exit 0**: Allow the action (task completion or idle)
- **Exit 2**: Block the action, stderr becomes feedback to the teammate
- **Other exit codes**: Non-blocking error, logged in verbose mode

## Debugging

Run Claude Code with `--debug` to see hook execution:
```bash
claude --debug
```

Or toggle verbose mode with `Ctrl+O` during a session to see hook output in the transcript.
