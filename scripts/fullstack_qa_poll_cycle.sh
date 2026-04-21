#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ai_team_config/scripts/fullstack_qa_poll_cycle.sh [options]

Poll fullstack QA-ready items and run the automated gate sweep.

Options:
  --repo-root PATH          Project root (default: current directory)
  --interval SECONDS        Poll interval when --watch is used (default: 240)
  --gate-timeout SECONDS    Per-gate timeout (default: 1800)
  --state-root PATH         State/log directory (default: /tmp/<project>-fullstack-qa-state)
  --issue ISSUE             Process only one issue ref or slug (example: FS-ISS-003)
  --watch                   Run continuously
  --once                    Run a single poll cycle (default)
  --dry-run                 Do not modify issue/message files
  --help                    Show this help
EOF
}

log() {
  printf '[fullstack-qa-cycle] %s\n' "$*"
}

err() {
  printf '[fullstack-qa-cycle] ERROR: %s\n' "$*" >&2
}

timestamp_utc() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

day_stamp() {
  date -u +"%Y-%m-%d"
}

timestamp_slug() {
  date -u +"%Y%m%dT%H%M%SZ"
}

slugify() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
}

sha_file() {
  local target="$1"
  if [[ -f "$target" ]]; then
    sha1sum "$target" | awk '{print $1}'
  else
    printf 'missing'
  fi
}

repo_root="$(pwd)"
poll_interval=240
gate_timeout=1800
watch_mode=0
state_root=""
issue_filter=""
dry_run=0
state_version="v1"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-root) repo_root="$2"; shift 2 ;;
    --interval) poll_interval="$2"; shift 2 ;;
    --gate-timeout) gate_timeout="$2"; shift 2 ;;
    --state-root) state_root="$2"; shift 2 ;;
    --issue) issue_filter="$2"; shift 2 ;;
    --watch) watch_mode=1; shift 1 ;;
    --once) watch_mode=0; shift 1 ;;
    --dry-run) dry_run=1; shift 1 ;;
    --help|-h) usage; exit 0 ;;
    *) err "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

if ! [[ "$poll_interval" =~ ^[0-9]+$ ]]; then
  err "--interval must be a non-negative integer"
  exit 1
fi

if ! [[ "$gate_timeout" =~ ^[0-9]+$ ]]; then
  err "--gate-timeout must be a non-negative integer"
  exit 1
fi

repo_root="$(cd "$repo_root" && pwd)"
project_name="$(basename "$repo_root")"
if [[ -z "$state_root" ]]; then
  state_root="/tmp/${project_name}-fullstack-qa-state"
fi

inbox_dir="$repo_root/dev_communication/fullstack/inbox"
inbox_completed_dir="$inbox_dir/completed"
issues_active_dir="$repo_root/dev_communication/fullstack/issues/active"

if [[ ! -d "$inbox_dir" || ! -d "$issues_active_dir" ]]; then
  err "Missing fullstack communication directories."
  exit 1
fi

mkdir -p "$state_root" "$inbox_completed_dir"

extract_issue_ref() {
  local issue_file="$1"
  basename "$issue_file" .md | sed -E 's/^(FS-ISS-[0-9]+).*/\1/'
}

issue_matches_filter() {
  local issue_file="$1"
  local issue_ref
  local issue_slug

  if [[ -z "$issue_filter" ]]; then
    return 0
  fi

  issue_ref="$(extract_issue_ref "$issue_file")"
  issue_slug="$(basename "$issue_file" .md)"
  [[ "$issue_filter" == "$issue_ref" || "$issue_filter" == "$issue_slug" ]]
}

issue_qa_state() {
  local issue_file="$1"
  sed -n -E 's/^\*\*QA:\*\* (.*)$/\1/p' "$issue_file" | head -n1
}

issue_has_ready_markers() {
  local issue_file="$1"
  rg -q '^- \[[xX]\] Development Complete$' "$issue_file" \
    && rg -q '^- \[[xX]\] Awaiting QA$' "$issue_file"
}

issue_is_candidate() {
  local issue_file="$1"
  local qa_state

  if ! issue_matches_filter "$issue_file"; then
    return 1
  fi

  qa_state="$(issue_qa_state "$issue_file")"
  case "$qa_state" in
    PENDING|BLOCKED) ;;
    *) return 1 ;;
  esac

  issue_has_ready_markers "$issue_file"
}

collect_related_messages() {
  local issue_ref="$1"
  local msg

  while IFS= read -r msg; do
    [[ -n "$msg" ]] || continue
    if [[ "$(basename "$msg")" == *"$issue_ref"* ]] || rg -q \
      -e "^# Message: ${issue_ref}([^0-9].*)?$" \
      -e "^- Issue: ${issue_ref}([^0-9].*)?$" \
      -e '^\*\*In-Response-To:\*\* '"${issue_ref}"'([^0-9].*)?$' \
      "$msg"; then
      printf '%s\n' "$msg"
    fi
  done < <(find "$inbox_dir" -maxdepth 1 -type f -name '*.md' | sort)
}

has_handoff_message() {
  local issue_ref="$1"
  local msg

  while IFS= read -r msg; do
    [[ -n "$msg" ]] || continue
    if rg -q \
      -e '^\*\*From:\*\* Fullstack-Dev$' \
      -e '^\*\*To:\*\* Fullstack-QA$' \
      -e '^\*\*Type:\*\* Request$' \
      "$msg" && {
        [[ "$(basename "$msg")" == *handoff* ]] || rg -qi \
          -e 'ready for qa' \
          -e 'development complete' \
          -e 'awaiting qa' \
          -e 'qa review request' \
          -e 'qa re-verification request' \
          -e 'qa recheck' \
          "$msg";
      }; then
      return 0
    fi
  done < <(collect_related_messages "$issue_ref")

  return 1
}

latest_related_hash() {
  local issue_ref="$1"
  local issue_file="$2"
  local parts=()
  local msg

  parts+=("state_version=$state_version")
  parts+=("issue=$(sha_file "$issue_file")")
  while IFS= read -r msg; do
    [[ -n "$msg" ]] || continue
    parts+=("$(basename "$msg")=$(sha_file "$msg")")
  done < <(collect_related_messages "$issue_ref")

  printf '%s\n' "${parts[@]}" | sha1sum | awk '{print $1}'
}

has_pattern_in_issue_or_messages() {
  local issue_file="$1"
  local issue_ref="$2"
  shift 2
  local pattern_args=("$@")
  local msg

  if rg -q "${pattern_args[@]}" "$issue_file"; then
    return 0
  fi

  while IFS= read -r msg; do
    [[ -n "$msg" ]] || continue
    if rg -q "${pattern_args[@]}" "$msg"; then
      return 0
    fi
  done < <(collect_related_messages "$issue_ref")

  return 1
}

has_commit_evidence() {
  local issue_file="$1"
  local issue_ref="$2"
  has_pattern_in_issue_or_messages \
    "$issue_file" \
    "$issue_ref" \
    -e '\b(commit|sha|hash)\b.*\b[0-9a-f]{7,40}\b' \
    -e '\b[0-9a-f]{7,40}\b.*\b(commit|sha|hash)\b'
}

has_push_evidence() {
  local issue_file="$1"
  local issue_ref="$2"
  has_pattern_in_issue_or_messages \
    "$issue_file" \
    "$issue_ref" \
    -e '\bpushed\b' \
    -e '\bpush evidence\b' \
    -e '\borigin/' \
    -e '\bshared remote branch\b' \
    -e '\bremote branch\b'
}

latest_section_timestamp() {
  local issue_file="$1"
  local section_name="$2"
  rg "^## ${section_name} \\(([^)]+)\\)$" -or '$1' "$issue_file" | tail -n1
}

blocked_reentry_has_fresh_dev_response() {
  local issue_file="$1"
  local qa_state
  local latest_qa_verification
  local latest_dev_response

  qa_state="$(issue_qa_state "$issue_file")"
  if [[ "$qa_state" != "BLOCKED" ]]; then
    return 0
  fi

  latest_qa_verification="$(latest_section_timestamp "$issue_file" "QA Verification")"
  latest_dev_response="$(latest_section_timestamp "$issue_file" "Dev Response")"

  if [[ -z "$latest_qa_verification" || -z "$latest_dev_response" ]]; then
    return 1
  fi

  [[ "$latest_dev_response" > "$latest_qa_verification" ]]
}

set_issue_field() {
  local issue_file="$1"
  local field="$2"
  local value="$3"
  local tmp_file

  if [[ "$dry_run" -eq 1 ]]; then
    log "DRY RUN: would set ${field}=${value} on $(basename "$issue_file")"
    return 0
  fi

  tmp_file="$(mktemp)"
  if rg -q "^\*\*${field}:\*\* " "$issue_file"; then
    sed -E "0,/^\*\*${field}:\*\* .*/s//**${field}:** ${value}/" "$issue_file" > "$tmp_file"
    mv "$tmp_file" "$issue_file"
  else
    cp "$issue_file" "$tmp_file"
    printf '\n**%s:** %s\n' "$field" "$value" >> "$tmp_file"
    mv "$tmp_file" "$issue_file"
  fi
}

append_issue_section() {
  local issue_file="$1"
  local body="$2"

  if [[ "$dry_run" -eq 1 ]]; then
    log "DRY RUN: would append QA Verification section to $(basename "$issue_file")"
    return 0
  fi

  printf '\n## QA Verification (%s)\n\n%s\n' "$(timestamp_utc)" "$body" >> "$issue_file"
}

write_response_message() {
  local issue_ref="$1"
  local subject="$2"
  local qa_state="$3"
  local content="$4"
  local note="$5"
  local filename

  filename="$(day_stamp)_$(timestamp_slug)_$(slugify "$issue_ref $subject").md"

  if [[ "$dry_run" -eq 1 ]]; then
    log "DRY RUN: would write QA response $filename"
    return 0
  fi

  cat > "$inbox_dir/$filename" <<EOF
# Response: $subject

**From:** Fullstack-QA
**To:** Fullstack-Dev
**Date:** $(day_stamp)
**Type:** Response
**In-Response-To:** $issue_ref
**QA:** $qa_state

## Content

$content

## Status

- [x] Accepted
- [ ] Issue created: N/A

## Notes

$note
EOF
  log "Wrote QA response $filename for $issue_ref"
}

archive_dev_handoff_messages() {
  local issue_ref="$1"
  local msg

  while IFS= read -r msg; do
    [[ -n "$msg" ]] || continue
    if ! rg -q -e '^\*\*From:\*\* Fullstack-Dev$' -e '^\*\*Type:\*\* Request$' "$msg"; then
      continue
    fi

    if [[ "$dry_run" -eq 1 ]]; then
      log "DRY RUN: would archive $(basename "$msg") for $issue_ref"
    else
      mv "$msg" "$inbox_completed_dir/$(basename "$msg")"
      log "Archived processed handoff message $(basename "$msg") for $issue_ref"
    fi
  done < <(collect_related_messages "$issue_ref")
}

record_issue_state() {
  local state_file="$1"
  local issue_hash="$2"

  if [[ "$dry_run" -eq 1 ]]; then
    return 0
  fi

  printf '%s' "$issue_hash" > "$state_file"
}

run_gate() {
  local gate_name="$1"
  local cmd="$2"
  local log_path="$3"

  if [[ "$dry_run" -eq 1 ]]; then
    printf 'SKIP'
    return 0
  fi

  if [[ "$gate_timeout" -gt 0 ]] && command -v timeout >/dev/null 2>&1; then
    if timeout "${gate_timeout}s" bash -lc "cd '$repo_root' && $cmd" >"$log_path" 2>&1; then
      printf 'PASS'
    else
      printf 'FAIL'
    fi
  else
    if bash -lc "cd '$repo_root' && $cmd" >"$log_path" 2>&1; then
      printf 'PASS'
    else
      printf 'FAIL'
    fi
  fi
}

schema_check_enabled() {
  [[ -f "$repo_root/packages/roadmap-schema/package.json" ]] \
    && rg -q '"generate:check"' "$repo_root/packages/roadmap-schema/package.json"
}

process_issue() {
  local issue_file="$1"
  local issue_ref
  local issue_slug
  local issue_hash
  local state_file
  local matched_handoffs
  local cargo_check_status
  local typecheck_status
  local cargo_test_status
  local pnpm_test_status
  local schema_status
  local gate_summary
  local body

  issue_ref="$(extract_issue_ref "$issue_file")"
  issue_slug="$(basename "$issue_file" .md)"
  issue_hash="$(latest_related_hash "$issue_ref" "$issue_file")"
  state_file="$state_root/${issue_slug}.last"

  if [[ -f "$state_file" ]] && [[ "$(cat "$state_file")" == "$issue_hash" ]]; then
    return 0
  fi

  log "Processing QA-ready candidate $issue_ref"

  if ! has_handoff_message "$issue_ref"; then
    log "$issue_ref is waiting on a fresh Fullstack-Dev handoff message"
    record_issue_state "$state_file" "$issue_hash"
    return 0
  fi

  if ! blocked_reentry_has_fresh_dev_response "$issue_file"; then
    log "$issue_ref is BLOCKED and still waiting on a fresh Dev Response section"
    record_issue_state "$state_file" "$issue_hash"
    return 0
  fi

  matched_handoffs="$(collect_related_messages "$issue_ref" | xargs -r -n1 basename | paste -sd ',' -)"
  log "$issue_ref matched handoff(s): $matched_handoffs"

  if ! has_commit_evidence "$issue_file" "$issue_ref" || ! has_push_evidence "$issue_file" "$issue_ref"; then
    set_issue_field "$issue_file" "QA" "BLOCKED"
    body='- QA Verdict: Need More Info
- Coverage Assessment: not evaluated; entry validation failed
- Manual Review: not started
- Unblock Criteria: include commit hash/reference and explicit push evidence in the issue handoff or Dev Response section before re-submitting for QA'
    append_issue_section "$issue_file" "$body"
    write_response_message \
      "$issue_ref" \
      "$issue_ref QA needs commit/push evidence" \
      "BLOCKED" \
      "Entry validation failed. The handoff is missing either a commit reference, explicit push evidence, or both. QA did not proceed to verification." \
      "Unblock by adding a fresh Dev Response section plus a fresh inbox handoff that includes the commit hash and confirms the work was pushed."
    record_issue_state "$state_file" "$(latest_related_hash "$issue_ref" "$issue_file")"
    return 0
  fi

  set_issue_field "$issue_file" "QA" "IN_PROGRESS"

  cargo_check_status="$(run_gate "cargo-check" "cargo check --workspace" "$state_root/${issue_ref}-cargo-check.log")"
  typecheck_status="$(run_gate "pnpm-typecheck" "pnpm -r typecheck" "$state_root/${issue_ref}-pnpm-typecheck.log")"
  cargo_test_status="$(run_gate "cargo-nextest" "cargo nextest run --workspace" "$state_root/${issue_ref}-cargo-nextest.log")"
  pnpm_test_status="$(run_gate "pnpm-test" "pnpm test" "$state_root/${issue_ref}-pnpm-test.log")"
  if schema_check_enabled; then
    schema_status="$(run_gate "schema-check" "pnpm --filter @soundsafe/roadmap-schema generate:check" "$state_root/${issue_ref}-schema-check.log")"
  else
    schema_status="SKIP"
  fi

  gate_summary="cargo check=$cargo_check_status; pnpm typecheck=$typecheck_status; cargo nextest=$cargo_test_status; pnpm test=$pnpm_test_status; schema check=$schema_status"

  if [[ "$dry_run" -eq 1 ]]; then
    log "$issue_ref dry-run gate summary: $gate_summary"
    return 0
  fi

  if [[ "$cargo_check_status" == "PASS" && "$typecheck_status" == "PASS" && "$cargo_test_status" == "PASS" && "$pnpm_test_status" == "PASS" && ( "$schema_status" == "PASS" || "$schema_status" == "SKIP" ) ]]; then
    set_issue_field "$issue_file" "QA" "PENDING_MANUAL_REVIEW"
    body="- QA Verdict: Pending Manual Review
- Coverage Assessment: automated gates passed; manual acceptance-criteria mapping still required
- Manual Review: pending
- Gate Results: $gate_summary
- Commit/Push Evidence: present"
    append_issue_section "$issue_file" "$body"
    archive_dev_handoff_messages "$issue_ref"
    log "$issue_ref automated gates passed; awaiting manual review"
  else
    set_issue_field "$issue_file" "QA" "BLOCKED"
    body="- QA Verdict: Blocked
- Coverage Assessment: incomplete because one or more automated gates failed
- Manual Review: not completed
- Gate Results: $gate_summary
- Unblock Criteria: fix the failing automated gate(s), add a fresh Dev Response section, and re-submit with a fresh inbox handoff"
    append_issue_section "$issue_file" "$body"
    write_response_message \
      "$issue_ref" \
      "$issue_ref blocked in QA automated gates" \
      "BLOCKED" \
      "Automated verification failed. Review the latest QA Verification section in the issue for gate results and re-submit with fresh dev evidence after fixes are pushed." \
      "Gate summary: $gate_summary."
    archive_dev_handoff_messages "$issue_ref"
    log "$issue_ref blocked by automated gates"
  fi

  record_issue_state "$state_file" "$(latest_related_hash "$issue_ref" "$issue_file")"
}

scan_once() {
  local inbox_count
  local active_count
  local candidate_count=0
  local issue_file

  inbox_count="$(find "$inbox_dir" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
  active_count="$(find "$issues_active_dir" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
  log "Triage summary: inbox=$inbox_count active_issues=$active_count"

  while IFS= read -r issue_file; do
    [[ -n "$issue_file" ]] || continue
    if issue_is_candidate "$issue_file"; then
      candidate_count=$((candidate_count + 1))
      process_issue "$issue_file"
    fi
  done < <(find "$issues_active_dir" -maxdepth 1 -type f -name '*.md' | sort)

  log "Cycle complete: qa_ready=$candidate_count"
}

log "Fullstack-QA watcher starting with interval=${poll_interval}s"
if [[ "$watch_mode" -eq 1 ]]; then
  while true; do
    scan_once
    sleep "$poll_interval"
  done
else
  scan_once
fi
