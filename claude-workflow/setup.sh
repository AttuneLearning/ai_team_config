#!/bin/bash

# Claude Dev Workflow Setup Script
# Run from your project root after adding the submodule

set -e

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
DEFAULT_PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
if [[ "$(basename "$SCRIPT_DIR")" == "claude-workflow" && "$(basename "$DEFAULT_PROJECT_ROOT")" == "ai_team_config" ]]; then
    DEFAULT_PROJECT_ROOT="$(dirname "$DEFAULT_PROJECT_ROOT")"
fi
PROJECT_ROOT="${WORKSPACE_ROOT:-$DEFAULT_PROJECT_ROOT}"
PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd -P)"

echo "Claude Dev Workflow Setup"
echo "========================="
echo ""
echo "DEPRECATION NOTICE: Prefer ./install.sh for unified Claude + Codex setup."
echo "  e.g.   ./ai_team_config/install.sh --team <id> --platform both"
echo "This script still works and now acts as a legacy entrypoint."
echo ""

# Check if running from correct location
if [ ! -d "$SCRIPT_DIR/skills" ]; then
    echo "Error: Script must be run from the submodule directory"
    echo "Usage: ./.claude-workflow/setup.sh"
    exit 1
fi

cd "$PROJECT_ROOT"

# Create .claude/commands directory
echo "Creating .claude/commands directory..."
mkdir -p .claude/commands

# Create skill symlinks
echo "Creating skill symlinks..."
SKILLS=(comms adr memory)
WORKFLOW_SKILLS=(context.skill reflect.skill refine.skill)

for skill in "${SKILLS[@]}"; do
    if [ ! -L ".claude/commands/${skill}.md" ]; then
        ln -sf "../../.claude-workflow/skills/${skill}.md" ".claude/commands/${skill}.md"
        echo "  Linked: ${skill}.md"
    else
        echo "  Exists: ${skill}.md"
    fi
done

for skill in "${WORKFLOW_SKILLS[@]}"; do
    name=$(echo "$skill" | sed 's/.skill//')
    if [ ! -L ".claude/commands/${name}.md" ]; then
        ln -sf "../../.claude-workflow/skills/${skill}.md" ".claude/commands/${name}.md"
        echo "  Linked: ${name}.md"
    else
        echo "  Exists: ${name}.md"
    fi
done

# Create or update settings.json
echo ""
echo "Checking .claude/settings.json..."
if [ ! -f ".claude/settings.json" ]; then
    cat > .claude/settings.json << 'EOF'
{
  "permissions": {
    "additionalDirectories": [
      "../.claude-workflow"
    ]
  }
}
EOF
    echo "  Created settings.json"
else
    echo "  settings.json exists - please verify additionalDirectories includes '../.claude-workflow'"
fi

# =========================================================================
# Dev Communication Setup
# =========================================================================
echo ""
echo "Dev Communication Setup"
echo "-----------------------"

if [ -d "dev_communication" ] && [ ! -L "dev_communication" ]; then
    # This is a real directory — likely the API project (owner)
    echo "dev_communication/ exists as a directory — this project owns it."
    echo "Checking structure..."

    # Ensure the team-grouped structure exists
    NEEDS_MIGRATION=false
    if [ -d "dev_communication/messaging" ] && [ ! -d "dev_communication/backend" ]; then
        NEEDS_MIGRATION=true
        echo "  Old flat structure detected. Migration needed."
        echo "  Run the migration manually or see PROCESS_GUIDE.md."
    fi

    if [ ! -d "dev_communication/backend" ]; then
        read -p "  Create team-grouped directory structure? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Read teams from registry or use defaults
            TEAMS=("backend" "frontend")
            for team in "${TEAMS[@]}"; do
                mkdir -p "dev_communication/${team}/inbox"
                mkdir -p "dev_communication/${team}/issues/queue"
                mkdir -p "dev_communication/${team}/issues/active"
                mkdir -p "dev_communication/${team}/issues/completed"
                touch "dev_communication/${team}/inbox/.gitkeep"
                touch "dev_communication/${team}/issues/queue/.gitkeep"
                touch "dev_communication/${team}/issues/active/.gitkeep"
                touch "dev_communication/${team}/issues/completed/.gitkeep"
                # Copy team template files
                if [ -d "$SCRIPT_DIR/scaffolds/dev_communication/${team}" ]; then
                    cp -n "$SCRIPT_DIR/scaffolds/dev_communication/${team}/definition.yaml" "dev_communication/${team}/" 2>/dev/null || true
                    cp -n "$SCRIPT_DIR/scaffolds/dev_communication/${team}/status.md" "dev_communication/${team}/" 2>/dev/null || true
                fi
                echo "  Created ${team}/ workspace"
            done
            mkdir -p "dev_communication/shared/architecture/decisions"
            mkdir -p "dev_communication/shared/architecture/suggestions"
            mkdir -p "dev_communication/shared/architecture/gaps"
            mkdir -p "dev_communication/shared/architecture/templates"
            mkdir -p "dev_communication/shared/guidance"
            mkdir -p "dev_communication/shared/specs"
            mkdir -p "dev_communication/shared/plans"
            mkdir -p "dev_communication/shared/contracts"
            mkdir -p "dev_communication/templates"
            mkdir -p "dev_communication/archive"

            # Copy templates and shared files from scaffold
            if [ -d "$SCRIPT_DIR/scaffolds/dev_communication/templates" ]; then
                cp -n "$SCRIPT_DIR/scaffolds/dev_communication/templates/"* "dev_communication/templates/" 2>/dev/null || true
                echo "  Copied templates from scaffold"
            fi
            if [ -d "$SCRIPT_DIR/scaffolds/dev_communication/shared" ]; then
                cp -n "$SCRIPT_DIR/scaffolds/dev_communication/shared/registry.yaml" "dev_communication/shared/" 2>/dev/null || true
                cp -n "$SCRIPT_DIR/scaffolds/dev_communication/shared/dependencies.md" "dev_communication/shared/" 2>/dev/null || true
            fi
            cp -n "$SCRIPT_DIR/scaffolds/dev_communication/index.md" "dev_communication/" 2>/dev/null || true
            cp -n "$SCRIPT_DIR/scaffolds/dev_communication/PROCESS_GUIDE.md" "dev_communication/" 2>/dev/null || true

            echo "  Team-grouped structure created."
        fi
    else
        echo "  Team-grouped structure already exists."
    fi

elif [ -L "dev_communication" ]; then
    # This is a symlink — non-API project
    echo "dev_communication/ is a symlink — this project uses shared comms."
    TARGET=$(readlink -f dev_communication)
    echo "  Points to: $TARGET"

else
    # No dev_communication at all — ask what to do
    echo "No dev_communication/ directory found."
    echo ""
    echo "Options:"
    echo "  1) Create dev_communication/ here (this is the API/owner project)"
    echo "  2) Create a symlink to another project's dev_communication/"
    echo "  3) Skip"
    echo ""
    read -p "Choose [1/2/3]: " -n 1 -r
    echo

    case $REPLY in
        1)
            echo "Creating dev_communication/ directory..."
            mkdir -p dev_communication

            # Create team workspaces
            TEAMS=("backend" "frontend")
            for team in "${TEAMS[@]}"; do
                mkdir -p "dev_communication/${team}/inbox"
                mkdir -p "dev_communication/${team}/issues/queue"
                mkdir -p "dev_communication/${team}/issues/active"
                mkdir -p "dev_communication/${team}/issues/completed"
                touch "dev_communication/${team}/inbox/.gitkeep"
                touch "dev_communication/${team}/issues/queue/.gitkeep"
                touch "dev_communication/${team}/issues/active/.gitkeep"
                touch "dev_communication/${team}/issues/completed/.gitkeep"
                # Copy team template files
                if [ -d "$SCRIPT_DIR/scaffolds/dev_communication/${team}" ]; then
                    cp -n "$SCRIPT_DIR/scaffolds/dev_communication/${team}/definition.yaml" "dev_communication/${team}/" 2>/dev/null || true
                    cp -n "$SCRIPT_DIR/scaffolds/dev_communication/${team}/status.md" "dev_communication/${team}/" 2>/dev/null || true
                fi
                echo "  Created ${team}/ workspace"
            done

            # Create shared resources
            mkdir -p "dev_communication/shared/architecture/decisions"
            mkdir -p "dev_communication/shared/architecture/suggestions"
            mkdir -p "dev_communication/shared/architecture/gaps"
            mkdir -p "dev_communication/shared/architecture/templates"
            mkdir -p "dev_communication/shared/guidance"
            mkdir -p "dev_communication/shared/specs"
            mkdir -p "dev_communication/shared/plans"
            mkdir -p "dev_communication/shared/contracts"
            mkdir -p "dev_communication/templates"
            mkdir -p "dev_communication/archive"

            # Copy scaffolds
            if [ -d "$SCRIPT_DIR/scaffolds/dev_communication" ]; then
                cp -n "$SCRIPT_DIR/scaffolds/dev_communication/templates/"* "dev_communication/templates/" 2>/dev/null || true
                cp -n "$SCRIPT_DIR/scaffolds/dev_communication/README.md" "dev_communication/README.md" 2>/dev/null || true
                cp -n "$SCRIPT_DIR/scaffolds/dev_communication/shared/registry.yaml" "dev_communication/shared/" 2>/dev/null || true
                cp -n "$SCRIPT_DIR/scaffolds/dev_communication/shared/dependencies.md" "dev_communication/shared/" 2>/dev/null || true
                cp -n "$SCRIPT_DIR/scaffolds/dev_communication/index.md" "dev_communication/" 2>/dev/null || true
                cp -n "$SCRIPT_DIR/scaffolds/dev_communication/PROCESS_GUIDE.md" "dev_communication/" 2>/dev/null || true
                echo "  Copied scaffolds"
            fi

            echo "  dev_communication/ created with team-grouped structure."
            ;;
        2)
            read -p "Path to API project root (e.g., ../<api_project_root>): " API_PATH
            if [ -d "${API_PATH}/dev_communication" ]; then
                ln -s "${API_PATH}/dev_communication" ./dev_communication
                echo "  Symlinked dev_communication/ → ${API_PATH}/dev_communication"
            else
                echo "  Error: ${API_PATH}/dev_communication not found."
                echo "  Run setup in the API project first to create it."
                exit 1
            fi
            ;;
        3)
            echo "  Skipped dev_communication setup."
            ;;
    esac
fi

# Ask about memory
echo ""
echo "Memory Vault Setup"
echo "------------------"
MEMORY_ROOT="ai_team_config/memory_store"
LEGACY_MEMORY_ROOT="memory"

if [ -d "$MEMORY_ROOT" ]; then
    echo "$MEMORY_ROOT already exists - skipping"
elif [ -d "$LEGACY_MEMORY_ROOT" ]; then
    echo "Legacy memory/ detected."
    read -p "Move memory/ to $MEMORY_ROOT? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mkdir -p "ai_team_config"
        mv "$LEGACY_MEMORY_ROOT" "$MEMORY_ROOT"
        echo "Moved memory/ -> $MEMORY_ROOT"
    else
        echo "Skipped migration of legacy memory/."
    fi
else
    read -p "Create memory vault directory at $MEMORY_ROOT? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mkdir -p "ai_team_config"
        cp -r "$SCRIPT_DIR/scaffolds/memory" "./$MEMORY_ROOT"
        echo "Created $MEMORY_ROOT from scaffold"
    fi
fi

# Ask about agent teams
echo ""
echo "Agent Teams Setup"
echo "-----------------"
read -p "Enable Claude Code agent teams? (adds hooks + team-configs) [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Create hooks directory
    mkdir -p .claude/hooks
    echo "  Created .claude/hooks/"

    # Create memory_store/team-configs if not exists
    if [ -d "$MEMORY_ROOT" ] && [ ! -d "$MEMORY_ROOT/team-configs" ]; then
        if [ -d "$SCRIPT_DIR/scaffolds/memory/team-configs" ]; then
            cp -r "$SCRIPT_DIR/scaffolds/memory/team-configs" "$MEMORY_ROOT/team-configs"
            echo "  Created $MEMORY_ROOT/team-configs/ from scaffold"
        else
            mkdir -p "$MEMORY_ROOT/team-configs"
            echo "  Created $MEMORY_ROOT/team-configs/"
        fi
    fi

    echo ""
    echo "  Agent teams enabled. Next steps for hooks:"
    echo "  1. Create .claude/hooks/task-completed.sh (see .claude-workflow/team-configs/agent-team-hooks-guide.md)"
    echo "  2. Create .claude/hooks/teammate-idle.sh"
    echo "  3. chmod +x .claude/hooks/*.sh"
    echo "  4. Add env + hooks config to .claude/settings.json (see SETUP.md Step 7)"
fi

# Archive legacy configs if found
LEGACY_CONFIGS=$(ls .claude/team-config*.json .claude/bug-fix-team-config*.json 2>/dev/null || true)
if [ -n "$LEGACY_CONFIGS" ]; then
    echo ""
    echo "Legacy Config Migration"
    echo "-----------------------"
    echo "Found legacy team configs in .claude/:"
    echo "$LEGACY_CONFIGS"
    read -p "Archive them to .claude/archive/? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mkdir -p .claude/archive
        for f in $LEGACY_CONFIGS; do
            mv "$f" .claude/archive/
            echo "  Archived: $(basename "$f")"
        done
    fi
fi

echo ""
echo "Setup Complete!"
echo ""
echo "Next steps:"
echo "1. Review .claude/settings.json"
echo "2. Add workflow section to CLAUDE.md (see SETUP.md)"
echo "3. Initialize team status in {team}/status.md"
echo "4. Initialize shared/registry.yaml with your active teams"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "5. Set up agent team hooks (see SETUP.md Step 7)"
fi
echo ""
echo "Available skills: /comms /adr /memory /context /reflect /refine"
