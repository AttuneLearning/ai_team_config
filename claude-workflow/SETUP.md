# Claude Dev Workflow - Setup Guide

Complete guide to setting up the Claude Code development workflow in a new project.

## Quick Start

```bash
# 1. Add submodule to your project
git submodule add https://github.com/yourusername/claude-dev-workflow.git .claude-workflow

# 2. Run unified agent coordination setup (Claude + Codex)
./agent-coord-setup.sh --team backend

# Claude-only setup (if needed)
./agent-coord-setup.sh --claude-only
```

## Manual Setup

### Step 1: Add the Submodule

```bash
cd your-project
git submodule add https://github.com/yourusername/claude-dev-workflow.git .claude-workflow
```

### Step 2: Create Project Directories

#### Option A: Shared dev_communication (recommended for multi-project)

If you have multiple projects (e.g., API + UI) that share communication:

```bash
# In your first project (e.g., API)
cp -r .claude-workflow/scaffolds/dev_communication ./dev_communication

# In your second project (e.g., UI)
ln -s ../first-project/dev_communication ./dev_communication
```

#### Option B: Project-specific dev_communication

```bash
cp -r .claude-workflow/scaffolds/dev_communication ./dev_communication
```

#### Memory Vault (always project-specific)

```bash
cp -r .claude-workflow/scaffolds/memory ./memory
```

### Step 3: Set Up Skills

Create symlinks from your project's `.claude/commands/` to the submodule skills:

```bash
mkdir -p .claude/commands

# Core skills
ln -sf ../../.claude-workflow/skills/comms.md .claude/commands/comms.md
ln -sf ../../.claude-workflow/skills/adr.md .claude/commands/adr.md
ln -sf ../../.claude-workflow/skills/memory.md .claude/commands/memory.md

# Workflow skills
ln -sf ../../.claude-workflow/skills/context.skill.md .claude/commands/context.md
ln -sf ../../.claude-workflow/skills/reflect.skill.md .claude/commands/reflect.md
ln -sf ../../.claude-workflow/skills/refine.skill.md .claude/commands/refine.md
```

### Step 4: Configure Permissions

Update `.claude/settings.json`:

```json
{
  "permissions": {
    "additionalDirectories": [
      "../.claude-workflow"
    ]
  }
}
```

### Step 5: Update CLAUDE.md

Add to your project's `CLAUDE.md`:

```markdown
## Development Workflow

**Submodule:** `.claude-workflow/`

### Skills Available
- `/comms` - Inter-team communication
- `/adr` - Architecture decisions
- `/memory` - Memory vault management
- `/context` - Pre-implementation context
- `/reflect` - Post-implementation reflection
- `/refine` - Pattern refinement

### Directories
- `dev_communication/` - Inter-team hub
- `memory/` - Extended memory vault
```

### Step 6: Initialize Content

#### Set Up Team Status

Edit `dev_communication/{team}/status.md` for each active team:
- Set the current date
- Add current focus
- List any blockers

#### Initialize Team Registry

Edit `dev_communication/shared/registry.yaml`:
- Set your project name
- List active teams with their repos and aliases

#### Create Initial Context

Create `memory/context/project-overview.md`:
```markdown
---
title: Project Overview
created: YYYY-MM-DD
tags: [context, overview]
---

# Project Overview

## What is this project?
{Description}

## Key Technologies
{List}

## Architecture
{Brief overview}
```

Create `memory/context/tech-stack.md`:
```markdown
---
title: Tech Stack
created: YYYY-MM-DD
tags: [context, tech]
---

# Tech Stack

## Backend
- {Technology}: {Version}

## Frontend
- {Technology}: {Version}

## Database
- {Technology}

## Infrastructure
- {Services}
```

## Directory Structure After Setup

```
your-project/
├── .claude/
│   ├── commands/           # Symlinks to skills
│   │   ├── comms.md -> ../../.claude-workflow/skills/comms.md
│   │   ├── adr.md -> ...
│   │   └── ...
│   ├── hooks/              # Quality gate hooks (agent teams)
│   │   ├── task-completed.sh
│   │   └── teammate-idle.sh
│   ├── team-configs/       # Local overrides (non-frontend projects only)
│   ├── archive/            # Legacy configs (if upgrading)
│   └── settings.json
├── .claude-workflow/       # Git submodule
│   ├── skills/
│   ├── patterns/
│   ├── indexes/
│   ├── hooks/
│   ├── teams/              # Generic role catalog + communication protocol
│   ├── team-configs/       # Shared agent team configs (override in .claude/team-configs/)
│   ├── templates/
│   └── scaffolds/
├── dev_communication/      # Copied from scaffold (or symlinked)
│   ├── backend/            # Backend team workspace
│   │   ├── definition.yaml
│   │   ├── status.md
│   │   ├── inbox/
│   │   └── issues/{queue,active,completed}/
│   ├── frontend/           # Frontend team workspace
│   │   ├── definition.yaml
│   │   ├── status.md
│   │   ├── inbox/
│   │   └── issues/{queue,active,completed}/
│   ├── shared/             # Cross-team resources
│   │   ├── registry.yaml
│   │   ├── dependencies.md
│   │   ├── architecture/
│   │   ├── guidance/
│   │   ├── specs/
│   │   ├── plans/
│   │   └── contracts/
│   ├── templates/
│   ├── archive/
│   └── index.md
├── memory/                 # Copied from scaffold
│   ├── context/
│   ├── entities/
│   ├── patterns/
│   ├── sessions/
│   └── team-configs/       # Learned team compositions
└── CLAUDE.md
```

## Multi-Project Setup

For projects that share communication (e.g., API + UI):

```
parent-directory/
├── api-project/
│   ├── .claude-workflow/     # Submodule
│   ├── dev_communication/    # Original copy
│   └── memory/               # API-specific
├── ui-project/
│   ├── .claude-workflow/     # Submodule
│   ├── dev_communication -> ../api-project/dev_communication
│   └── memory/               # UI-specific
└── claude-dev-workflow/      # Can also be standalone for development
```

## Updating the Submodule

```bash
# Pull latest changes
cd .claude-workflow
git pull origin master
cd ..
git add .claude-workflow
git commit -m "Update claude-dev-workflow submodule"
```

### Step 7: Agent Teams Setup (Optional)

Enable Claude Code experimental agent teams for parallel development.

#### 7a. Enable Agent Teams

Add to `.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

#### 7b. Install Quality Gate Hooks

Create `.claude/hooks/` directory and add the hook scripts:

```bash
mkdir -p .claude/hooks

# Copy hook scripts from the submodule guide or create per:
# .claude-workflow/team-configs/agent-team-hooks-guide.md
```

Add hook wiring to `.claude/settings.json`:

```json
{
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

Make hooks executable:

```bash
chmod +x .claude/hooks/task-completed.sh
chmod +x .claude/hooks/teammate-idle.sh
```

#### 7c. Create Learned Team Configs Directory

```bash
mkdir -p memory/team-configs
```

Or if setting up from scaffolds:

```bash
cp -r .claude-workflow/scaffolds/memory/team-configs memory/team-configs
```

This directory stores learned team compositions from Phase 4 reviews. Phase 1.5 (Team Selection) reads these to inform future preset choices.

#### 7d. Archive Legacy Configs (If Upgrading)

If you have legacy team configs in `.claude/` (e.g., `team-config.json`, `team-config-*.json`):

```bash
mkdir -p .claude/archive
mv .claude/team-config*.json .claude/archive/
mv .claude/bug-fix-team-config*.json .claude/archive/
```

These are superseded by `.claude-workflow/team-configs/agent-team-roles.json` and the preset system.

#### 7e. Create Local Overrides (Non-Frontend Projects)

If your project is NOT a frontend/React project, create local overrides of the team configs:

```bash
mkdir -p .claude/team-configs

# Copy submodule configs as starting point
cp .claude-workflow/team-configs/agent-team-roles.json .claude/team-configs/
cp .claude-workflow/team-configs/code-reviewer-config.json .claude/team-configs/
```

Then edit the copied files to swap:
- Architecture pattern (FSD → your layers)
- Test framework (Vitest/RTL → Jest/supertest/etc.)
- Framework-specific checks (shadcn/ARIA → your conventions)
- Test/coverage commands

See `.claude-workflow/team-configs/README.md` for a detailed override guide.

#### 7f. Verify Setup

```bash
# Check jq is available (hooks depend on it)
which jq

# Verify hooks are executable
ls -la .claude/hooks/

# Verify settings.json is valid
python3 -c "import json; json.load(open('.claude/settings.json'))"

# Test hook with dry run
echo '{"task_subject":"test","cwd":"'$(pwd)'"}' | .claude/hooks/task-completed.sh
```

**References:**
- Hook setup details: `.claude-workflow/team-configs/agent-team-hooks-guide.md`
- Agent team roles: `.claude-workflow/team-configs/agent-team-roles.json`
- Code review gate: `.claude-workflow/team-configs/code-reviewer-config.json`

---

## Customization

### Project-Specific Patterns

Add patterns specific to your project in `.claude-workflow/patterns/active/`:
- They'll be available to all projects using the submodule
- Or keep project-specific patterns in `memory/patterns/`

### Team Configuration

Edit skill behavior by modifying the symlinked skills or creating project-specific overrides in `.claude/commands/`.

## Troubleshooting

### Skills not found
- Check symlinks exist: `ls -la .claude/commands/`
- Verify submodule initialized: `git submodule status`

### Permission denied on submodule
- Check `.claude/settings.json` includes `additionalDirectories`

### Submodule empty after clone
```bash
git submodule init
git submodule update
```
