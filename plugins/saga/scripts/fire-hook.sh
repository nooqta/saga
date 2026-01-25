#!/bin/bash

# SAGA Hook Executor
# Fires lifecycle hooks with fallback logging and knowledge storage
#
# Usage: fire-hook.sh <hook-name> <json-context>
# Example: fire-hook.sh on-task-start '{"storyId":"US-001",...}'
#
# Hook configuration is read from hooks.json (saga section)

set -euo pipefail

HOOK_NAME="${1:-}"
CONTEXT="${2:-"{}"}"

if [[ -z "$HOOK_NAME" ]]; then
  echo "Error: Hook name required" >&2
  echo "Usage: fire-hook.sh <hook-name> <json-context>" >&2
  exit 1
fi

# Validate that context is valid JSON and doesn't contain unsubstituted placeholders
validate_context() {
  local ctx="$1"

  # Check for common unsubstituted placeholders
  if echo "$ctx" | grep -qE '\[STORY_ID\]|\[STORY_TITLE\]|\[REASON\]|\[COUNT\]|\[ERRORS_ARRAY\]|\[REQUIREMENTS_ARRAY\]|\[COMMIT_HASH\]|\[FILES_ARRAY\]|\[DURATION\]|\[ITERATION\]|\[BRANCH_NAME\]|\[CRITERIA_ARRAY\]'; then
    echo "Error: JSON context contains unsubstituted placeholders" >&2
    echo "Received: $ctx" >&2
    echo "" >&2
    echo "The orchestrator must replace ALL placeholders with actual values:" >&2
    echo "  [STORY_ID] → \"US-001\"" >&2
    echo "  [STORY_TITLE] → \"Add login feature\"" >&2
    echo "  [COUNT] → 3 (a number, not quoted)" >&2
    echo "  [ERRORS_ARRAY] → [\"error1\",\"error2\"] or []" >&2
    echo "  [REQUIREMENTS_ARRAY] → [\"FR-001\",\"FR-002\"] or []" >&2
    echo "  [FILES_ARRAY] → [\"src/file.ts\"] or []" >&2
    echo "  [DURATION] → 45000 (milliseconds, not quoted)" >&2
    echo "  [ITERATION] → 1 (a number, not quoted)" >&2
    exit 1
  fi

  # Validate JSON syntax
  if ! echo "$ctx" | jq -e . >/dev/null 2>&1; then
    echo "Error: Invalid JSON in context" >&2
    echo "Received: $ctx" >&2
    echo "" >&2
    echo "Hint: Ensure numeric values are NOT quoted and arrays are valid JSON:" >&2
    echo "  Good: {\"retryCount\":3,\"errors\":[\"err1\"]}" >&2
    echo "  Bad:  {\"retryCount\":\"3\",\"errors\":\"[err1]\"}" >&2
    exit 1
  fi
}

validate_context "$CONTEXT"

# Determine script directory and plugin root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_JSON="$PLUGIN_ROOT/hooks/hooks.json"

SAGA_DIR=".saga"
HOOKS_DIR="$SAGA_DIR/hooks"
KNOWLEDGE_DIR="$SAGA_DIR/knowledge"
HOOK_LOG="/tmp/saga-hooks.log"

# Ensure knowledge directory exists
mkdir -p "$KNOWLEDGE_DIR"

# Log hook call
log_hook() {
  local status="$1"
  local message="$2"
  echo "[$(date -Iseconds)] [$HOOK_NAME] $status: $message" >> "$HOOK_LOG"
}

# Store knowledge via bash fallback (if JS hooks don't run)
store_knowledge_fallback() {
  local filename="$1"
  local entry="$2"
  local filepath="$KNOWLEDGE_DIR/$filename"

  # Add timestamp to entry (use -c for compact single-line JSONL format)
  local timestamped
  timestamped=$(echo "$entry" | jq -c --arg ts "$(date -Iseconds)" '. + {timestamp: $ts}')

  echo "$timestamped" >> "$filepath"
  log_hook "KNOWLEDGE" "Stored entry in $filename"
}

# Get hook configuration from hooks.json
get_hook_config() {
  if [[ -f "$HOOKS_JSON" ]]; then
    local js_path
    local fallback

    js_path=$(jq -r ".saga[\"$HOOK_NAME\"].js // \"\"" "$HOOKS_JSON" 2>/dev/null || echo "")
    fallback=$(jq -r ".saga[\"$HOOK_NAME\"].fallback // \"bash\"" "$HOOKS_JSON" 2>/dev/null || echo "bash")

    if [[ -n "$js_path" ]]; then
      log_hook "CONFIG" "Found hook config in hooks.json: js=$js_path, fallback=$fallback"
      echo "$js_path"
      return 0
    fi
  fi

  # Default: look for hook in standard location
  echo "$HOOKS_DIR/${HOOK_NAME}.js"
}

# Try to execute hook
execute_hook() {
  # Get configured hook path from hooks.json
  local hook_js
  hook_js=$(get_hook_config)
  local hook_sh="$HOOKS_DIR/${HOOK_NAME}.sh"

  # Try JS hook first (hooks use native Node.js modules only, no npm install needed)
  if [[ -f "$hook_js" && -x "$hook_js" ]]; then
    log_hook "EXECUTING" "JS hook $hook_js"
    if echo "$CONTEXT" | "$hook_js" 2>>"$HOOK_LOG"; then
      log_hook "SUCCESS" "JS hook completed"
      return 0
    else
      log_hook "FAILED" "JS hook failed, trying fallback"
    fi
  fi

  # Try shell hook
  if [[ -f "$hook_sh" && -x "$hook_sh" ]]; then
    log_hook "EXECUTING" "Shell hook $hook_sh"

    if echo "$CONTEXT" | "$hook_sh" 2>>"$HOOK_LOG"; then
      log_hook "SUCCESS" "Shell hook completed"
      return 0
    else
      log_hook "FAILED" "Shell hook failed"
    fi
  fi

  # Fallback: Log and store knowledge
  log_hook "FALLBACK" "No working hook, using bash fallback"
  handle_fallback
  return 0
}

# Fallback handlers for each hook type
handle_fallback() {
  local story_id
  local title

  story_id=$(echo "$CONTEXT" | jq -r '.storyId // "unknown"')
  title=$(echo "$CONTEXT" | jq -r '.title // "unknown"')

  case "$HOOK_NAME" in
    on-task-start)
      log_hook "FALLBACK" "Starting story $story_id: $title"
      echo "Hook: on-task-start | Story: $story_id | Title: $title"
      ;;

    on-task-completed)
      log_hook "FALLBACK" "Completed story $story_id"

      # Store pattern knowledge
      local commit_hash
      local files_changed
      local linked_reqs
      local duration_ms

      commit_hash=$(echo "$CONTEXT" | jq -r '.commitHash // "unknown"')
      files_changed=$(echo "$CONTEXT" | jq -c '.filesChanged // []')
      linked_reqs=$(echo "$CONTEXT" | jq -c '.linkedRequirements // []')
      duration_ms=$(echo "$CONTEXT" | jq -r '.metrics.durationMs // 0')

      local entry
      entry=$(jq -n \
        --arg sid "$story_id" \
        --arg t "$title" \
        --arg ch "$commit_hash" \
        --argjson fc "$files_changed" \
        --argjson lr "$linked_reqs" \
        '{storyId: $sid, title: $t, commitHash: $ch, filesChanged: $fc, linkedRequirements: $lr, pattern: "Completed via fallback"}'
      )

      store_knowledge_fallback "patterns.jsonl" "$entry"

      # Update progress.txt
      local progress_file="$SAGA_DIR/progress.txt"
      local date_str
      local duration_min
      local files_str
      local reqs_str

      date_str=$(date +%Y-%m-%d)
      duration_min=$((duration_ms / 60000))
      files_str=$(echo "$files_changed" | jq -r 'join(", ")')
      reqs_str=$(echo "$linked_reqs" | jq -r 'join(", ")')

      cat >> "$progress_file" << PROGRESS_EOF

## $date_str - $story_id: $title
- **Commit:** $commit_hash
- **Files:** $files_str
- **Duration:** ${duration_min} min
- **Requirements:** $reqs_str
---
PROGRESS_EOF
      log_hook "PROGRESS" "Updated progress.txt"

      echo "Hook: on-task-completed | Story: $story_id | Commit: $commit_hash"
      ;;

    on-task-blocked)
      log_hook "FALLBACK" "Blocked story $story_id"

      # Store blocker knowledge
      local blocked_reason
      local retry_count
      local errors

      blocked_reason=$(echo "$CONTEXT" | jq -r '.blockedReason // "unknown"')
      retry_count=$(echo "$CONTEXT" | jq -r '.retryCount // 0')
      errors=$(echo "$CONTEXT" | jq -c '.errors // []')

      local entry
      entry=$(jq -n \
        --arg sid "$story_id" \
        --arg t "$title" \
        --arg br "$blocked_reason" \
        --argjson rc "$retry_count" \
        --argjson err "$errors" \
        '{storyId: $sid, title: $t, blockedReason: $br, retryCount: $rc, errors: $err}'
      )

      store_knowledge_fallback "blockers.jsonl" "$entry"
      echo "Hook: on-task-blocked | Story: $story_id | Reason: $blocked_reason"
      ;;

    *)
      log_hook "UNKNOWN" "Unknown hook type: $HOOK_NAME"
      echo "Hook: $HOOK_NAME (no handler)"
      ;;
  esac
}

# Main
log_hook "CALLED" "Context: $CONTEXT"
execute_hook
