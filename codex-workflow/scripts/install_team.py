#!/usr/bin/env python3
"""
Install Codex workflow skills with an active team profile.

Usage examples:
  python3 .codex-workflow/scripts/install_team.py --list-teams
  python3 .codex-workflow/scripts/install_team.py --team backend
  python3 .codex-workflow/scripts/install_team.py --detect-team --workspace-root .
  python3 .codex-workflow/scripts/install_team.py --auto-team --workspace-root .
  python3 .codex-workflow/scripts/install_team.py --team data-warehousing --target /tmp/codex-skills --dry-run
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Optional

try:
  import yaml  # type: ignore
except Exception:  # pragma: no cover - optional dependency
  yaml = None


def _load_profiles(profiles_path: Path) -> Dict[str, Any]:
  if not profiles_path.exists():
    raise FileNotFoundError(f"Missing team profiles: {profiles_path}")
  with profiles_path.open("r", encoding="utf-8") as f:
    return json.load(f)


def _default_target(pack_name: str) -> Path:
  codex_home = os.environ.get("CODEX_HOME")
  if codex_home:
    return Path(codex_home).expanduser() / "skills" / pack_name
  return Path.home() / ".codex" / "skills" / pack_name


def _print_teams(profiles: Dict[str, Any]) -> None:
  teams = profiles.get("teams", {})
  if not teams:
    print("No teams found in profiles.")
    return
  print("Available teams:")
  for team_id in sorted(teams.keys()):
    team = teams[team_id]
    name = team.get("name", team_id)
    alias = team.get("alias", "-")
    prefix = team.get("issue_prefix", "-")
    print(f"  - {team_id:16} name={name}, alias={alias}, issue_prefix={prefix}")


def _load_yaml(path: Path) -> Dict[str, Any]:
  if yaml is None or not path.exists():
    return {}
  with path.open("r", encoding="utf-8") as f:
    payload = yaml.safe_load(f) or {}
  return payload if isinstance(payload, dict) else {}


def _normalize_rel_path(path_value: str) -> str:
  return path_value.strip().strip("/")


def _maybe_role_guidance_path(project_root: Path, sub_team_name: str, sub_team_id: str) -> Optional[str]:
  guidance_root = project_root / "dev_communication" / "shared" / "guidance"
  if not guidance_root.exists():
    return None
  candidates = []
  if sub_team_name:
    candidates.append(sub_team_name.upper().replace("-", "_"))
  if sub_team_id:
    candidates.append(sub_team_id.upper().replace("-", "_"))
  for candidate in candidates:
    rel = f"dev_communication/shared/guidance/{candidate}_ROLE_GUIDANCE.md"
    if (project_root / rel).exists():
      return rel
  return None


def _detect_team_from_project(project_root: Path, teams: Dict[str, Any]) -> Optional[str]:
  registry_path = project_root / "dev_communication" / "shared" / "registry.yaml"
  registry = _load_yaml(registry_path)
  active = registry.get("active_teams", [])
  project_name = project_root.name
  matches = []

  if isinstance(active, list):
    for item in active:
      if not isinstance(item, dict):
        continue
      team_id = str(item.get("id", "")).strip()
      repo_name = str(item.get("repo", "")).strip()
      if team_id and repo_name and repo_name == project_name and team_id in teams:
        matches.append(team_id)

  if len(matches) == 1:
    return matches[0]
  if len(matches) > 1:
    return None

  package_json = project_root / "package.json"
  if package_json.exists():
    try:
      package = json.loads(package_json.read_text(encoding="utf-8"))
      package_name = str(package.get("name", "")).lower()
      if ("api" in package_name or "backend" in package_name) and "backend" in teams:
        return "backend"
      if ("ui" in package_name or "frontend" in package_name) and "frontend" in teams:
        return "frontend"
    except Exception:
      pass

  if (project_root / "src" / "routes").exists() and "backend" in teams:
    return "backend"
  if (project_root / "src" / "app").exists() and "frontend" in teams:
    return "frontend"
  return None


def _resolve_other_team_inbox(
  project_root: Path,
  active_teams: list[dict[str, Any]],
  team_id: str
) -> Optional[str]:
  for item in active_teams:
    if not isinstance(item, dict):
      continue
    other_id = str(item.get("id", "")).strip()
    if not other_id or other_id == team_id:
      continue
    definition_rel = str(item.get("definition", "")).strip()
    if definition_rel:
      definition = _load_yaml(project_root / "dev_communication" / definition_rel)
      identity = definition.get("identity", {}) if isinstance(definition, dict) else {}
      inbox = identity.get("inbox") if isinstance(identity, dict) else None
      if isinstance(inbox, str) and inbox.strip():
        return f"dev_communication/{_normalize_rel_path(inbox)}"
    return f"dev_communication/{other_id}/inbox"
  return None


def _apply_repo_team_definition(
  project_root: Path,
  team_id: str,
  base_profile: Dict[str, Any]
) -> tuple[Dict[str, Any], str]:
  registry_path = project_root / "dev_communication" / "shared" / "registry.yaml"
  registry = _load_yaml(registry_path)
  active = registry.get("active_teams", [])
  if not isinstance(active, list):
    return base_profile, "profiles.json"

  team_entry: Optional[Dict[str, Any]] = None
  for item in active:
    if isinstance(item, dict) and str(item.get("id", "")).strip() == team_id:
      team_entry = item
      break
  if not team_entry:
    return base_profile, "profiles.json"

  definition_rel = str(team_entry.get("definition", "")).strip()
  if not definition_rel:
    return base_profile, "profiles.json"
  definition = _load_yaml(project_root / "dev_communication" / definition_rel)
  if not definition:
    return base_profile, "profiles.json"

  profile = json.loads(json.dumps(base_profile))
  team_meta = definition.get("team", {}) if isinstance(definition, dict) else {}
  identity = definition.get("identity", {}) if isinstance(definition, dict) else {}

  if isinstance(team_meta, dict):
    if team_meta.get("name"):
      profile["name"] = str(team_meta["name"])
    if team_meta.get("alias"):
      profile["alias"] = str(team_meta["alias"])
  if isinstance(team_entry, dict):
    if team_entry.get("name"):
      profile["name"] = str(team_entry["name"])
    if team_entry.get("alias"):
      profile["alias"] = str(team_entry["alias"])

  default_paths = dict(profile.get("default_paths", {}))
  if isinstance(identity, dict):
    issue_prefix = identity.get("issue_prefix")
    inbox = identity.get("inbox")
    issues = identity.get("issues")
    status = identity.get("status")
    if isinstance(issue_prefix, str) and issue_prefix.strip():
      profile["issue_prefix"] = issue_prefix.strip()
    if isinstance(inbox, str) and inbox.strip():
      default_paths["inbox"] = f"dev_communication/{_normalize_rel_path(inbox)}"
    if isinstance(issues, str) and issues.strip():
      issues_root = f"dev_communication/{_normalize_rel_path(issues)}"
      default_paths["issues_queue"] = f"{issues_root}/queue"
      default_paths["issues_active"] = f"{issues_root}/active"
      default_paths["issues_completed"] = f"{issues_root}/completed"
    if isinstance(status, str) and status.strip():
      default_paths["status"] = f"dev_communication/{_normalize_rel_path(status)}"

  other_team_inbox = _resolve_other_team_inbox(
    project_root,
    [item for item in active if isinstance(item, dict)],
    team_id
  )
  if other_team_inbox:
    default_paths["other_team_inbox"] = other_team_inbox
  profile["default_paths"] = default_paths

  sub_teams = definition.get("sub_teams")
  if isinstance(sub_teams, dict) and sub_teams:
    normalized_sub_teams: Dict[str, Any] = {}
    for sub_team_id, payload in sub_teams.items():
      if not isinstance(payload, dict):
        continue
      entry = {
        "name": payload.get("name", sub_team_id),
        "function": payload.get("function", ""),
        "issue_prefix": payload.get("issue_prefix", profile.get("issue_prefix", "")),
      }
      role_guidance = _maybe_role_guidance_path(
        project_root,
        str(payload.get("name", "")),
        str(sub_team_id)
      )
      if role_guidance:
        entry["role_guidance"] = role_guidance
      normalized_sub_teams[str(sub_team_id)] = entry
    if normalized_sub_teams:
      profile["sub_teams"] = normalized_sub_teams

  return profile, "dev_communication/shared/registry.yaml + team definition"


def _copy_skills(workflow_root: Path, target_root: Path, enabled_skills: list[str], dry_run: bool) -> None:
  target_skills = target_root / "skills"
  if dry_run:
    print(f"[dry-run] mkdir -p {target_skills}")
  else:
    target_skills.mkdir(parents=True, exist_ok=True)

  for skill in enabled_skills:
    src = workflow_root / "skills" / skill
    dst = target_skills / skill
    if not src.exists():
      raise FileNotFoundError(f"Skill folder not found: {src}")
    if dry_run:
      print(f"[dry-run] copytree {src} -> {dst}")
      continue
    shutil.copytree(src, dst, dirs_exist_ok=True)


def _copy_team_metadata(workflow_root: Path, target_root: Path, dry_run: bool) -> None:
  src_teams = workflow_root / "teams"
  dst_teams = target_root / "teams"
  if dry_run:
    print(f"[dry-run] copytree {src_teams} -> {dst_teams}")
    return
  shutil.copytree(src_teams, dst_teams, dirs_exist_ok=True)


def _write_json(path: Path, payload: Dict[str, Any], dry_run: bool) -> None:
  if dry_run:
    print(f"[dry-run] write {path}")
    return
  path.parent.mkdir(parents=True, exist_ok=True)
  with path.open("w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2)
    f.write("\n")


def _write_text_if_missing(path: Path, content: str, dry_run: bool) -> None:
  if path.exists():
    return
  if dry_run:
    print(f"[dry-run] write {path}")
    return
  path.parent.mkdir(parents=True, exist_ok=True)
  path.write_text(content, encoding="utf-8")


def _append_line_if_missing(path: Path, line: str, dry_run: bool) -> None:
  if not path.exists():
    _write_text_if_missing(path, f"{line}\n", dry_run)
    return
  existing = path.read_text(encoding="utf-8")
  if line in existing:
    return
  if dry_run:
    print(f"[dry-run] append line to {path}: {line}")
    return
  with path.open("a", encoding="utf-8") as f:
    if not existing.endswith("\n"):
      f.write("\n")
    f.write(f"{line}\n")


def _write_team_profile_md(path: Path, team_id: str, team: Dict[str, Any], dry_run: bool) -> None:
  lines = [
    f"# Active Team Profile: {team_id}",
    "",
    f"- Name: {team.get('name', team_id)}",
    f"- Alias: {team.get('alias', '-')}",
    f"- Issue Prefix: {team.get('issue_prefix', '-')}",
    "",
    "## Enabled Skills",
  ]
  for skill in team.get("enabled_skills", []):
    lines.append(f"- `{skill}`")
  lines.append("")
  lines.append("## Default Paths")
  for key, value in sorted(team.get("default_paths", {}).items()):
    lines.append(f"- `{key}`: `{value}`")
  lines.append("")
  body = "\n".join(lines) + "\n"

  if dry_run:
    print(f"[dry-run] write {path}")
    return
  path.parent.mkdir(parents=True, exist_ok=True)
  path.write_text(body, encoding="utf-8")


def _ensure_ai_team_store(
  project_root: Path,
  team_id: str,
  enabled_skills: list[str],
  dry_run: bool
) -> Dict[str, str]:
  ai_root = project_root / "ai_team_config"
  shared_memory_root = ai_root / "memory_store"
  team_root = ai_root / team_id
  adr_store = team_root / "adr_store"
  memory_store = team_root / "memory_store"
  context_store = team_root / "context_store"
  skill_store_root = team_root / "skill_store"

  dirs = [ai_root, shared_memory_root, team_root, adr_store, memory_store, context_store, skill_store_root]
  for directory in dirs:
    if directory.exists():
      continue
    if dry_run:
      print(f"[dry-run] mkdir -p {directory}")
    else:
      directory.mkdir(parents=True, exist_ok=True)

  # Root vault index
  root_index = ai_root / "index.md"
  root_index_content = (
    "# AI Team Config Vault\n\n"
    "This is the shared team-oriented AI storage vault in Obsidian-compatible Markdown.\n\n"
    "## Shared Stores\n"
    "- Shared Memory: [[ai_team_config/memory_store/index]]\n\n"
    "## Team Roots\n"
    f"- [[ai_team_config/{team_id}/index]]\n\n"
    "## Notes\n"
    "- Use wiki links for cross-reference and backlinks.\n"
    "- Keep skill memory in `skill_store/<skill>/memory_store/`.\n"
  )
  _write_text_if_missing(root_index, root_index_content, dry_run)
  _append_line_if_missing(root_index, "- Shared Memory: [[ai_team_config/memory_store/index]]", dry_run)
  _append_line_if_missing(root_index, f"- [[ai_team_config/{team_id}/index]]", dry_run)

  shared_memory_index = shared_memory_root / "index.md"
  _write_text_if_missing(
    shared_memory_index,
    (
      "# Shared Memory Store\n\n"
      "Backlinks: [[ai_team_config/index]] [[TEAM_CONFIG_CONTRACT]]\n\n"
      "This vault stores shared cross-team memory artifacts in Obsidian-compatible Markdown.\n"
    ),
    dry_run
  )

  # Team index with cross-links
  team_index = team_root / "index.md"
  team_index_content = (
    f"# Team Vault: {team_id}\n\n"
    f"Backlink: [[ai_team_config/index]]\n\n"
    "## Core Stores\n"
    f"- ADR: [[ai_team_config/{team_id}/adr_store/index]]\n"
    f"- Memory: [[ai_team_config/{team_id}/memory_store/index]]\n"
    f"- Context: [[ai_team_config/{team_id}/context_store/index]]\n"
    f"- Skill Store: [[ai_team_config/{team_id}/skill_store/index]]\n"
  )
  _write_text_if_missing(team_index, team_index_content, dry_run)

  adr_index = adr_store / "index.md"
  _write_text_if_missing(
    adr_index,
    (
      "# ADR Store\n\n"
      f"Backlinks: [[ai_team_config/{team_id}/index]] [[ai_team_config/index]]\n\n"
      "Store architecture notes, ADR drafts, and decision snapshots here.\n"
    ),
    dry_run
  )

  memory_index = memory_store / "index.md"
  _write_text_if_missing(
    memory_index,
    (
      "# Memory Store\n\n"
      f"Backlinks: [[ai_team_config/{team_id}/index]] [[ai_team_config/index]]\n\n"
      "Store long-lived team memory and distilled implementation notes here.\n"
    ),
    dry_run
  )

  context_index = context_store / "index.md"
  _write_text_if_missing(
    context_index,
    (
      "# Context Store\n\n"
      f"Backlinks: [[ai_team_config/{team_id}/index]] [[ai_team_config/index]]\n\n"
      "Store pre-implementation context packs and topic context notes here.\n"
    ),
    dry_run
  )

  skill_store_index = skill_store_root / "index.md"
  skill_store_index_content = (
    "# Skill Store\n\n"
    f"Backlinks: [[ai_team_config/{team_id}/index]] [[ai_team_config/index]]\n\n"
    "## Skill Memory Stores\n"
  )
  for skill in enabled_skills:
    skill_store_index_content += f"- [[ai_team_config/{team_id}/skill_store/{skill}/memory_store/index]]\n"
  _write_text_if_missing(skill_store_index, skill_store_index_content, dry_run)

  for skill in enabled_skills:
    skill_memory_dir = skill_store_root / skill / "memory_store"
    if not skill_memory_dir.exists():
      if dry_run:
        print(f"[dry-run] mkdir -p {skill_memory_dir}")
      else:
        skill_memory_dir.mkdir(parents=True, exist_ok=True)

    skill_memory_index = skill_memory_dir / "index.md"
    _write_text_if_missing(
      skill_memory_index,
      (
        f"# Skill Memory: {skill}\n\n"
        f"Backlinks: [[ai_team_config/{team_id}/skill_store/index]] "
        f"[[ai_team_config/{team_id}/memory_store/index]] [[ai_team_config/{team_id}/index]]\n\n"
        "Store skill-specific memory notes in this folder.\n"
      ),
      dry_run
    )

  return {
    "vault_root": str(ai_root),
    "shared_memory_root": str(shared_memory_root),
    "team_root": str(team_root),
    "adr_store": str(adr_store),
    "memory_store": str(memory_store),
    "context_store": str(context_store),
    "skill_store_root": str(skill_store_root)
  }


def _ensure_team_contract(project_root: Path, dry_run: bool) -> None:
  contract_path = project_root / "TEAM_CONFIG_CONTRACT.md"
  contract_content = (
    "# Team Config Contract\n\n"
    "This file defines how team-scoped AI storage is organized for the project.\n\n"
    "Required shared vault structure:\n"
    "- `ai_team_config/memory_store/`\n\n"
    "Required team vault structure:\n"
    "- `ai_team_config/<team>/adr_store/`\n"
    "- `ai_team_config/<team>/memory_store/`\n"
    "- `ai_team_config/<team>/context_store/`\n"
    "- `ai_team_config/<team>/skill_store/<skill>/memory_store/`\n\n"
    "Storage format: Obsidian-compatible Markdown with wiki-links/backlinks.\n"
  )
  _write_text_if_missing(contract_path, contract_content, dry_run)


def main() -> int:
  parser = argparse.ArgumentParser(description="Install Codex workflow with team-specific profile")
  parser.add_argument("--team", help="Team id, e.g. backend, frontend, data-warehousing")
  parser.add_argument("--auto-team", action="store_true", help="Auto-detect team from repository definitions when --team is omitted")
  parser.add_argument("--detect-team", action="store_true", help="Print detected team id for this workspace and exit")
  parser.add_argument("--list-teams", action="store_true", help="List available team ids")
  parser.add_argument("--target", help="Install destination (default: $CODEX_HOME/skills/codex-workflow or ~/.codex/skills/codex-workflow)")
  parser.add_argument("--pack-name", default="codex-workflow", help="Pack name under skills directory (default: codex-workflow)")
  parser.add_argument("--workspace-root", help="Project root (default: parent of .codex-workflow)")
  parser.add_argument("--force", action="store_true", help="Overwrite existing target directory")
  parser.add_argument("--dry-run", action="store_true", help="Print actions without writing files")
  parser.add_argument("--no-local-config", action="store_true", help="Do not write .codex-workflow/config/active-team.json")
  parser.add_argument("--no-repo-profile", action="store_true", help="Use only static profiles.json values and ignore dev_communication team definitions")
  args = parser.parse_args()

  workflow_root = Path(__file__).resolve().parents[1]
  project_root = Path(args.workspace_root).resolve() if args.workspace_root else workflow_root.parent
  profiles_path = workflow_root / "teams" / "profiles.json"
  profiles = _load_profiles(profiles_path)
  teams = profiles.get("teams", {})

  if args.list_teams:
    _print_teams(profiles)
    return 0

  detected_team = _detect_team_from_project(project_root, teams)
  if args.detect_team:
    if detected_team:
      print(detected_team)
      return 0
    return 1

  if not args.team:
    if args.auto_team and detected_team:
      args.team = detected_team
      print(f"Auto-detected team: {args.team}")
    else:
      parser.error("--team is required unless --list-teams is used (or pass --auto-team)")

  if args.team not in teams:
    print(f"Unknown team: {args.team}", file=sys.stderr)
    _print_teams(profiles)
    return 2

  target_root = Path(args.target).expanduser() if args.target else _default_target(args.pack_name)
  team_profile = json.loads(json.dumps(teams[args.team]))
  team_profile_source = "profiles.json"
  if not args.no_repo_profile:
    team_profile, team_profile_source = _apply_repo_team_definition(project_root, args.team, team_profile)

  if target_root.exists():
    if not args.force:
      print(
        f"Target exists: {target_root}\n"
        "Use --force to replace, or pass --target to install elsewhere.",
        file=sys.stderr,
      )
      return 3
    if args.dry_run:
      print(f"[dry-run] rm -rf {target_root}")
    else:
      shutil.rmtree(target_root)

  if args.dry_run:
    print(f"[dry-run] mkdir -p {target_root}")
  else:
    target_root.mkdir(parents=True, exist_ok=True)

  enabled_skills = team_profile.get("enabled_skills", [])
  _copy_skills(workflow_root, target_root, enabled_skills, args.dry_run)
  _copy_team_metadata(workflow_root, target_root, args.dry_run)
  _ensure_team_contract(project_root, args.dry_run)
  team_store_paths = _ensure_ai_team_store(project_root, args.team, enabled_skills, args.dry_run)

  installed_at = datetime.now(timezone.utc).isoformat()
  team_profile_with_store = dict(team_profile)
  default_paths = dict(team_profile_with_store.get("default_paths", {}))
  default_paths.update({
    "memory_root": team_store_paths["shared_memory_root"],
    "team_vault_root": team_store_paths["team_root"],
    "adr_store": team_store_paths["adr_store"],
    "memory_store": team_store_paths["memory_store"],
    "context_store": team_store_paths["context_store"],
    "skill_store_root": team_store_paths["skill_store_root"]
  })
  team_profile_with_store["default_paths"] = default_paths

  manifest = {
    "pack_name": args.pack_name,
    "installed_at": installed_at,
    "team_id": args.team,
    "team_profile": team_profile_with_store,
    "team_profile_source": team_profile_source,
    "team_store_paths": team_store_paths,
    "source_workflow_root": str(workflow_root),
    "project_root": str(project_root),
  }

  _write_json(target_root / "config" / "active-team.json", manifest, args.dry_run)
  _write_json(target_root / "install-manifest.json", manifest, args.dry_run)
  _write_team_profile_md(target_root / "TEAM_PROFILE.md", args.team, team_profile, args.dry_run)

  if not args.no_local_config:
    _write_json(workflow_root / "config" / "active-team.json", manifest, args.dry_run)

  print("Installation complete." if not args.dry_run else "Dry-run complete.")
  print(f"Team: {args.team}")
  print(f"Team profile source: {team_profile_source}")
  print(f"Target: {target_root}")
  if args.no_local_config:
    print("Local config: skipped (--no-local-config)")
  else:
    print(f"Local config: {workflow_root / 'config' / 'active-team.json'}")
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
