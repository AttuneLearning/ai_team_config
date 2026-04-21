#!/usr/bin/env bash
# =============================================================================
# DEPRECATED — agent-coord-setup.sh
# =============================================================================
#
# This script depended on `codex-workflow/install.sh`, which was removed in a
# prior refactor. The script no longer functions and is preserved only as a
# redirect to the maintained installer.
#
# Use the unified installer instead:
#
#     ./ai_team_config/install.sh --team <id> --platform both
#
# =============================================================================

set -euo pipefail

cat >&2 <<'EOF'

agent-coord-setup.sh is deprecated and no longer functional.

The codex-workflow/install.sh path it depended on was removed in a prior
refactor. The maintained entry point is the unified installer:

    ./ai_team_config/install.sh --team <id> --platform both

Examples:

    # Solo / small-team project (one contributor across the whole codebase)
    ./ai_team_config/install.sh --team fullstack --platform both

    # Multi-team project, frontend role
    ./ai_team_config/install.sh --team frontend --platform both

    # List available teams (interactive prompt if --team is omitted)
    ./ai_team_config/install.sh

    # All install.sh options
    ./ai_team_config/install.sh --help

EOF

exit 1
