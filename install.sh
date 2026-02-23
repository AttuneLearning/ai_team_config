#!/usr/bin/env bash
# =============================================================================
# AI Team Config Installer
# =============================================================================
#
# Interactive installer that sets up a project with:
#   1. Team selection (frontend, backend, qa, etc.)
#   2. Sub-team role selection (e.g., frontend-dev, frontend-qa)
#   3. Platform setup (claude, codex, or both)
#   4. Memory vault scaffolding
#   5. Dev communication scaffolding (if not already present)
#
# Usage:
#   ./ai_team_config/install.sh                    # Interactive mode
#   ./ai_team_config/install.sh --team frontend    # Skip team prompt
#   ./ai_team_config/install.sh --team frontend --role frontend-dev --platform claude
#   ./ai_team_config/install.sh --team frontend --role frontend-dev --platform both --devcomm create
#   ./ai_team_config/install.sh --team frontend --role frontend-dev --platform both --refresh-threshold 5
#   ./ai_team_config/install.sh --team frontend --role frontend-dev --platform both --force-refresh-links
#
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROFILES_FILE="${SCRIPT_DIR}/teams/profiles.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
TEAM_ID=""
ROLE_ID=""
PLATFORM=""
DEVCOMM_MODE="create"
DEVCOMM_LINK_TARGET=""
REFRESH_THRESHOLD=5
FORCE_REFRESH_LINKS=0
RUN_ID="$(date +%Y%m%d-%H%M%S)"

while [[ $# -gt 0 ]]; do
  case $1 in
    --team) TEAM_ID="$2"; shift 2 ;;
    --role) ROLE_ID="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --devcomm) DEVCOMM_MODE="$2"; shift 2 ;;
    --refresh-threshold) REFRESH_THRESHOLD="$2"; shift 2 ;;
    --force-refresh-links) FORCE_REFRESH_LINKS=1; shift 1 ;;
    --help|-h)
      echo "Usage: $0 [--team TEAM] [--role ROLE] [--platform claude|codex|both] [--devcomm create|skip|symlink:/abs/path] [--refresh-threshold N] [--force-refresh-links]"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

case "$DEVCOMM_MODE" in
  create|skip)
    ;;
  symlink:*)
    DEVCOMM_LINK_TARGET="${DEVCOMM_MODE#symlink:}"
    ;;
  *)
    echo -e "${RED}Invalid --devcomm mode: ${DEVCOMM_MODE}${NC}"
    echo "Use one of: create, skip, symlink:/absolute/path"
    exit 1
    ;;
esac

if ! [[ "$REFRESH_THRESHOLD" =~ ^[0-9]+$ ]]; then
  echo -e "${RED}Invalid --refresh-threshold: ${REFRESH_THRESHOLD}${NC}"
  echo "Use a non-negative integer."
  exit 1
fi

safe_link() {
  local target="$1"
  local link_path="$2"
  local label="$3"
  local target_for_link="$target"

  if [[ "$target" = /* ]]; then
    target_for_link="$(python3 - "$target" "$(dirname "$link_path")" <<'PY'
import os
import sys

target = os.path.abspath(sys.argv[1])
base = os.path.realpath(sys.argv[2])
target = os.path.realpath(target)
print(os.path.relpath(target, base))
PY
)"
  fi

  if [ -L "$link_path" ]; then
    local current_target
    current_target="$(readlink "$link_path" || true)"
    if [ "$current_target" != "$target_for_link" ]; then
      ln -sf "$target_for_link" "$link_path"
      echo "  Updated symlink: ${label}"
    else
      echo "  Symlink already current: ${label}"
    fi
  elif [ -e "$link_path" ]; then
    if [ "$FORCE_REFRESH_LINKS" = "1" ]; then
      local backup_path="${link_path}.legacy-${RUN_ID}"
      mv "$link_path" "$backup_path"
      ln -s "$target_for_link" "$link_path"
      echo -e "  ${YELLOW}Refreshed link ${label}; backup: ${backup_path}${NC}"
    else
      echo -e "  ${YELLOW}Skipped symlink ${label}: regular file/directory exists.${NC}"
      return 1
    fi
  else
    ln -s "$target_for_link" "$link_path"
    echo "  Created symlink: ${label}"
  fi

  return 0
}

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  AI Team Config Installer${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

# ---- Check prerequisites ----
if ! command -v python3 &>/dev/null; then
  echo -e "${RED}Error: python3 is required but not found.${NC}"
  exit 1
fi

if [ ! -f "$PROFILES_FILE" ]; then
  echo -e "${RED}Error: profiles.json not found at ${PROFILES_FILE}${NC}"
  exit 1
fi

# ---- Load available teams ----
AVAILABLE_TEAMS=$(python3 -c "
import json
with open('$PROFILES_FILE') as f:
    data = json.load(f)
for tid, team in data['teams'].items():
    print(f'{tid}|{team[\"name\"]}')
")

# ---- Step 1: Select team ----
if [ -z "$TEAM_ID" ]; then
  echo -e "${GREEN}Step 1: Select your team${NC}"
  echo ""
  i=1
  declare -a TEAM_IDS
  while IFS='|' read -r tid tname; do
    TEAM_IDS+=("$tid")
    echo "  ${i}) ${tname} (${tid})"
    ((i++))
  done <<< "$AVAILABLE_TEAMS"
  echo ""
  read -rp "Enter team number: " TEAM_NUM

  if [[ "$TEAM_NUM" -ge 1 && "$TEAM_NUM" -le "${#TEAM_IDS[@]}" ]]; then
    TEAM_ID="${TEAM_IDS[$((TEAM_NUM-1))]}"
  else
    echo -e "${RED}Invalid selection.${NC}"
    exit 1
  fi
fi

echo -e "  Selected team: ${YELLOW}${TEAM_ID}${NC}"
echo ""

# ---- Load team profile ----
TEAM_JSON=$(python3 -c "
import json
with open('$PROFILES_FILE') as f:
    data = json.load(f)
team = data['teams'].get('$TEAM_ID')
if not team:
    print('NOT_FOUND')
else:
    print(json.dumps(team))
")

if [ "$TEAM_JSON" = "NOT_FOUND" ]; then
  echo -e "${RED}Team '$TEAM_ID' not found in profiles.json${NC}"
  exit 1
fi

# ---- Step 2: Select sub-team role ----
SUB_TEAMS=$(python3 -c "
import json
team = json.loads('$TEAM_JSON')
for sid, sub in team.get('sub_teams', {}).items():
    print(f'{sid}|{sub[\"name\"]}|{sub.get(\"function\", \"\")}')
")

if [ -z "$ROLE_ID" ]; then
  echo -e "${GREEN}Step 2: Select your sub-team role${NC}"
  echo "  (This defines what this agent controller window operates as)"
  echo ""
  i=1
  declare -a ROLE_IDS
  while IFS='|' read -r rid rname rfunc; do
    ROLE_IDS+=("$rid")
    echo "  ${i}) ${rname} (${rid}) — ${rfunc}"
    ((i++))
  done <<< "$SUB_TEAMS"
  echo ""
  read -rp "Enter role number: " ROLE_NUM

  if [[ "$ROLE_NUM" -ge 1 && "$ROLE_NUM" -le "${#ROLE_IDS[@]}" ]]; then
    ROLE_ID="${ROLE_IDS[$((ROLE_NUM-1))]}"
  else
    echo -e "${RED}Invalid selection.${NC}"
    exit 1
  fi
fi

echo -e "  Selected role: ${YELLOW}${ROLE_ID}${NC}"
echo ""

# ---- Step 3: Select platform ----
if [ -z "$PLATFORM" ]; then
  echo -e "${GREEN}Step 3: Select platform${NC}"
  echo ""
  echo "  1) Claude Code"
  echo "  2) Codex"
  echo "  3) Both"
  echo ""
  read -rp "Enter platform number: " PLAT_NUM

  case $PLAT_NUM in
    1) PLATFORM="claude" ;;
    2) PLATFORM="codex" ;;
    3) PLATFORM="both" ;;
    *) echo -e "${RED}Invalid selection.${NC}"; exit 1 ;;
  esac
fi

echo -e "  Selected platform: ${YELLOW}${PLATFORM}${NC}"
echo ""

# ---- Step 4: Scaffold memory/ ----
echo -e "${GREEN}Step 4: Setting up memory vault...${NC}"

MEMORY_DIR="${PROJECT_ROOT}/memory"
if [ -d "$MEMORY_DIR" ]; then
  echo "  memory/ already exists, preserving existing content."
  # Ensure subdirectories exist
  for subdir in sessions context patterns entities templates team-configs prompts prompts/agents prompts/tasks prompts/workflows prompts/team-configs; do
    mkdir -p "${MEMORY_DIR}/${subdir}"
  done

  # Seed missing scaffold files without overwriting project-local memory data
  while IFS= read -r rel_file; do
    src_file="${SCRIPT_DIR}/scaffolds/memory/${rel_file}"
    dst_file="${MEMORY_DIR}/${rel_file}"
    if [ ! -f "$dst_file" ]; then
      mkdir -p "$(dirname "$dst_file")"
      cp "$src_file" "$dst_file"
      echo "  Seeded: memory/${rel_file}"
    fi
  done < <(cd "${SCRIPT_DIR}/scaffolds/memory" && find . -type f | sed 's|^\./||')
else
  echo "  Creating memory/ from scaffold..."
  cp -r "${SCRIPT_DIR}/scaffolds/memory" "$MEMORY_DIR"
fi
echo "  Done."
echo ""

# ---- Step 5: Setup dev_communication/ ----
echo -e "${GREEN}Step 5: Setting up dev_communication/...${NC}"

DEVCOMM_DIR="${PROJECT_ROOT}/dev_communication"
DEVCOMM_SCAFFOLD="${SCRIPT_DIR}/scaffolds/dev_communication"
if [ -e "$DEVCOMM_DIR" ]; then
  echo "  dev_communication/ already exists ($(file -b "$DEVCOMM_DIR"))."
else
  echo -e "  ${YELLOW}dev_communication/ not found.${NC}"

  case "$DEVCOMM_MODE" in
    create)
      if [ -d "$DEVCOMM_SCAFFOLD" ]; then
        cp -r "$DEVCOMM_SCAFFOLD" "$DEVCOMM_DIR"
        echo "  Created from ai_team_config scaffold."
      else
        echo -e "  ${RED}Scaffold not found at ${DEVCOMM_SCAFFOLD}.${NC}"
        exit 1
      fi
      ;;
    symlink:*)
      if [ -d "$DEVCOMM_LINK_TARGET" ]; then
        ln -s "$DEVCOMM_LINK_TARGET" "$DEVCOMM_DIR"
        echo "  Symlinked to ${DEVCOMM_LINK_TARGET}."
      else
        echo -e "  ${RED}Symlink target not found: ${DEVCOMM_LINK_TARGET}${NC}"
        exit 1
      fi
      ;;
    skip)
      echo "  Skipped. Set up dev_communication/ before using /comms or /adr."
      ;;
  esac
fi
echo ""

# ---- Step 6: Run platform setup ----
echo -e "${GREEN}Step 6: Installing platform skills...${NC}"

if [ "$PLATFORM" = "claude" ] || [ "$PLATFORM" = "both" ]; then
  echo ""
  echo "  --- Claude Code ---"
  FORCE_REFRESH_LINKS="$FORCE_REFRESH_LINKS" RUN_ID="$RUN_ID" bash "${SCRIPT_DIR}/platforms/claude/setup.sh" "$PROJECT_ROOT"
fi

if [ "$PLATFORM" = "codex" ] || [ "$PLATFORM" = "both" ]; then
  echo ""
  echo "  --- Codex ---"
  FORCE_REFRESH_LINKS="$FORCE_REFRESH_LINKS" RUN_ID="$RUN_ID" bash "${SCRIPT_DIR}/platforms/codex/setup.sh" "$PROJECT_ROOT" "$TEAM_ID" "$ROLE_ID"
fi
echo ""

# ---- Step 7: Write active-role.json ----
echo -e "${GREEN}Step 7: Writing active role configuration...${NC}"

ROLE_FILE="${SCRIPT_DIR}/roles/${ROLE_ID}.yaml"
if [ -f "$ROLE_FILE" ]; then
  echo "  Role definition found: ${ROLE_FILE}"
else
  echo -e "  ${YELLOW}No role definition file for ${ROLE_ID}. Skills will infer from team context.${NC}"
fi

# Write a JSON active-role for easy consumption by any platform
python3 -c "
import json
team = json.loads('''$TEAM_JSON''')
sub = team.get('sub_teams', {}).get('$ROLE_ID', {})
role = {
    'role_id': '$ROLE_ID',
    'role_name': sub.get('name', '$ROLE_ID'),
    'team_id': '$TEAM_ID',
    'team_name': team.get('name', '$TEAM_ID'),
    'function': sub.get('function', ''),
    'issue_prefix': sub.get('issue_prefix', team.get('issue_prefix', '')),
    'role_guidance': sub.get('role_guidance', ''),
    'allowed_roles': list(team.get('sub_teams', {}).keys()),
    'paths': team.get('default_paths', {})
}
with open('${PROJECT_ROOT}/active-role.json', 'w') as f:
    json.dump(role, f, indent=2)
print('  Wrote: active-role.json')
"

if [ -d "${PROJECT_ROOT}/.codex-workflow/config" ]; then
  safe_link "${PROJECT_ROOT}/active-role.json" "${PROJECT_ROOT}/.codex-workflow/config/active-role.json" ".codex-workflow/config/active-role.json" || true
  safe_link "${PROJECT_ROOT}/active-role.json" "${PROJECT_ROOT}/.codex-workflow/config/active-agent-role.json" ".codex-workflow/config/active-agent-role.json" || true
fi

if [ -d "${PROJECT_ROOT}/.claude" ]; then
  safe_link "${PROJECT_ROOT}/active-role.json" "${PROJECT_ROOT}/.claude/active-role.json" ".claude/active-role.json" || true
fi
echo ""

# ---- Step 8: Compliance audit ----
echo -e "${GREEN}Step 8: Running compliance audit...${NC}"

COMPLIANCE_ISSUES=0
report_issue() {
  local message="$1"
  echo "  [non-compliant] ${message}"
  COMPLIANCE_ISSUES=$((COMPLIANCE_ISSUES + 1))
}

# Required memory files (from canonical scaffold)
while IFS= read -r rel_file; do
  if [ ! -f "${MEMORY_DIR}/${rel_file}" ]; then
    report_issue "Missing memory file: memory/${rel_file}"
  fi
done < <(cd "${SCRIPT_DIR}/scaffolds/memory" && find . -type f | sed 's|^\./||')

if [ ! -e "$DEVCOMM_DIR" ]; then
  report_issue "Missing dev_communication/ root"
else
  if [ -L "$DEVCOMM_DIR" ] && [ ! -e "$DEVCOMM_DIR" ]; then
    report_issue "Broken dev_communication symlink"
  fi

  for required_dir in \
    "shared/architecture" \
    "templates" \
    "archive" \
    "${TEAM_ID}/inbox" \
    "${TEAM_ID}/issues/queue" \
    "${TEAM_ID}/issues/active" \
    "${TEAM_ID}/issues/completed"
  do
    if [ ! -d "${DEVCOMM_DIR}/${required_dir}" ]; then
      report_issue "Missing dev_communication/${required_dir}"
    fi
  done
fi

if [ ! -f "$ROLE_FILE" ]; then
  report_issue "Missing role definition: ai_team_config/roles/${ROLE_ID}.yaml"
fi

if [ "$PLATFORM" = "claude" ] || [ "$PLATFORM" = "both" ]; then
  for skill_src_dir in "${PROJECT_ROOT}/ai_team_config/skills"/*/; do
    skill_name=$(basename "$skill_src_dir")
    if [ ! -L "${PROJECT_ROOT}/.claude/commands/${skill_name}.md" ]; then
      report_issue "Missing Claude skill symlink: .claude/commands/${skill_name}.md"
    fi
  done
fi

if [ "$PLATFORM" = "codex" ] || [ "$PLATFORM" = "both" ]; then
  for skill_src_dir in "${PROJECT_ROOT}/ai_team_config/skills"/*/; do
    skill_name=$(basename "$skill_src_dir")
    if [ ! -L "${PROJECT_ROOT}/.codex-workflow/skills/${skill_name}/SKILL.md" ]; then
      report_issue "Missing Codex skill symlink: .codex-workflow/skills/${skill_name}/SKILL.md"
    fi
  done
fi

echo "  Compliance issues detected: ${COMPLIANCE_ISSUES}"
if [ "$COMPLIANCE_ISSUES" -ge "$REFRESH_THRESHOLD" ]; then
  echo -e "  ${YELLOW}Recommendation: refresh setup (issues >= threshold ${REFRESH_THRESHOLD}).${NC}"
  echo "  Suggested command:"
  echo "    ./ai_team_config/install.sh --team ${TEAM_ID} --role ${ROLE_ID} --platform ${PLATFORM} --devcomm create"
fi
echo ""

# ---- Summary ----
echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  Installation Complete${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
echo -e "  Team:      ${YELLOW}${TEAM_ID}${NC}"
echo -e "  Role:      ${YELLOW}${ROLE_ID}${NC}"
echo -e "  Platform:  ${YELLOW}${PLATFORM}${NC}"
echo -e "  Memory:    ${GREEN}${MEMORY_DIR}${NC}"
echo ""
echo "  Working directories:"
echo "    Skills (canonical):  ai_team_config/skills/"
echo "    Memory vault:        memory/"
echo "    ADRs & specs:        dev_communication/shared/architecture/"
echo "    Team comms:          dev_communication/${TEAM_ID}/"
echo "    Role definition:     ai_team_config/roles/${ROLE_ID}.yaml"
echo "    Active role:         active-role.json"
echo ""
echo "  To switch this window's role:"
echo "    ./ai_team_config/install.sh --team ${TEAM_ID} --role <new-role> --platform ${PLATFORM}"
echo ""
echo "  Available skills: /comms /adr /memory /context /reflect /refine"
echo ""
