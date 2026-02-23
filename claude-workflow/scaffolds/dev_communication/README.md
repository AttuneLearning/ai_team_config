# Dev Communication Hub

Centralized communication system for coordinating development across teams.

## Structure

```
dev_communication/
├── backend/                 # Backend team workspace
│   ├── definition.yaml      # Team identity and config
│   ├── status.md            # Current focus and blockers
│   ├── inbox/               # Messages TO this team
│   └── issues/              # Issue tracking
│       ├── queue/
│       ├── active/
│       └── completed/
│
├── frontend/                # Frontend team workspace
│   ├── definition.yaml
│   ├── status.md
│   ├── inbox/
│   └── issues/{queue,active,completed}/
│
├── shared/                  # Cross-team resources
│   ├── registry.yaml        # Active teams in this project
│   ├── dependencies.md      # Cross-team blockers
│   ├── architecture/        # ADRs, suggestions, gaps
│   ├── guidance/            # Development guidelines
│   ├── specs/               # Feature specifications
│   ├── plans/               # Planning documents
│   └── contracts/           # API endpoint contracts
│
├── templates/               # Message and issue templates
├── archive/                 # Completed message threads
├── index.md                 # Issue tracking dashboard
└── PROCESS_GUIDE.md         # Detailed workflow documentation
```

## Communication Protocol

- **Messages** cross team boundaries — save to `{recipient_team}/inbox/`
- **Issues** stay local — only create issues in your own team's queue
- See `.claude-workflow/teams/protocol.yaml` for the full protocol

## Skills

- `/comms` - Check inbox, send messages, manage issues
- `/adr` - Manage architecture decisions

## Symlink Setup (Non-API Projects)

```bash
ln -s ../<api_project_root>/dev_communication dev_communication
```
