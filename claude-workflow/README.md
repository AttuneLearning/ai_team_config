# Claude Dev Workflow

A comprehensive development workflow system for Claude Code projects.

## Features

- **Skills** - Reusable commands (`/comms`, `/adr`, `/memory`, `/context`, `/reflect`, `/refine`)
- **Patterns** - Code patterns with token-optimized format
- **Indexes** - Fast lookup for ADRs, patterns, and work types
- **Hooks** - Advisory reminders (pre/post implementation, testing)
- **Teams** - Generic role catalog and cross-team communication protocol
- **Scaffolds** - Ready-to-use directory structures for new projects

## Quick Start

```bash
# Add to your project
git submodule add https://github.com/yourusername/claude-dev-workflow.git .claude-workflow

# Run setup
./.claude-workflow/setup.sh

# Or follow manual setup in SETUP.md
```

See [SETUP.md](SETUP.md) for detailed instructions.

## Structure

```
claude-dev-workflow/
├── skills/                 # Skill definitions
│   ├── comms.md            # Inter-team communication
│   ├── adr.md              # Architecture decisions
│   ├── memory.md           # Memory vault management
│   ├── context.skill.md    # Pre-implementation context
│   ├── reflect.skill.md    # Post-implementation reflection
│   └── refine.skill.md     # Pattern refinement
│
├── patterns/               # Code patterns
│   ├── active/             # Production-ready patterns
│   ├── draft/              # Experimental patterns
│   └── archived/           # Deprecated patterns
│
├── indexes/                # Token-optimized lookups
│   ├── adr-index.md        # ADR quick reference
│   ├── pattern-index.md    # Pattern quick reference
│   └── work-type-index.md  # Work type to ADR/pattern mapping
│
├── hooks/                  # Advisory hooks
│   ├── pre-implementation.md
│   ├── post-implementation.md
│   └── test-reminder.md
│
├── teams/                  # Generic team definitions
│   ├── catalog.yaml        # Role catalog (frontend, backend, mobile, etc.)
│   └── protocol.yaml       # Cross-team communication rules
│
├── team-configs/           # Agent team configurations (shared)
│   ├── code-reviewer-config.json     # QA/Architect code gate
│   ├── agent-team-roles.json         # Agent team role definitions
│   ├── agent-team-hooks-guide.md     # Hook setup documentation
│   └── README.md                     # Config manifest
│
├── templates/              # Templates for new items
│   ├── pattern-template.md
│   ├── adr-template.md
│   └── session-template.md
│
├── scaffolds/              # Directory scaffolds
│   ├── dev_communication/  # Team-grouped communication hub
│   └── memory/             # Extended memory vault (includes team-configs/)
│
├── SETUP.md                # Setup instructions
├── setup.sh                # Automated setup script
└── README.md               # This file
```

## Skills

| Skill | Trigger | Purpose |
|-------|---------|---------|
| comms | `/comms` | Manage inter-team messages, issues, status |
| adr | `/adr` | Manage architecture decisions and gaps |
| memory | `/memory` | Add entities, patterns, sessions to vault |
| context | `/context` | Load relevant ADRs/patterns before implementing |
| reflect | `/reflect` | Capture learnings after implementation |
| refine | `/refine` | Review and promote patterns |

## Workflow

```
/context → Implement → /reflect → (accumulate) → /refine
```

1. **Pre-implementation**: Run `/context` to load relevant ADRs and patterns
2. **Implementation**: Follow loaded guidance, write tests per ADR-DEV-001
3. **Post-implementation**: Run `/reflect` to capture learnings
4. **Refinement**: Run `/refine` when patterns accumulate (5+ uses)

## Scaffolds

### dev_communication/

Team-grouped communication hub with:
- Per-team workspaces (`backend/`, `frontend/`) with inbox and issue tracking
- Shared resources (`shared/`) for architecture decisions, guidance, specs, contracts
- Cross-team protocol: messages cross boundaries, issues stay local
- Templates for messages and issues

### memory/

Extended memory vault with:
- Context (project background)
- Entities (system components)
- Patterns (conventions)
- Sessions (summaries)
- Team configs (learned team compositions from Phase 4 reviews)

### team-configs/

Shared agent team configurations (via submodule):
- Code reviewer gate config (Opus 4.6)
- Agent team role definitions (lead + implementer/tester/researcher)
- Hook setup documentation
- See `team-configs/README.md` for full manifest

## Updates

```bash
cd .claude-workflow
git pull origin master
cd ..
git add .claude-workflow
git commit -m "Update claude-dev-workflow submodule"
```

## License

MIT
