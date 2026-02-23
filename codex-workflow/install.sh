#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "DEPRECATION NOTICE: Prefer ./agent-coord-setup.sh for unified Claude + Codex setup." >&2
echo "This script still works and now acts as a legacy entrypoint." >&2

python3 "$SCRIPT_DIR/scripts/install_team.py" "$@"
