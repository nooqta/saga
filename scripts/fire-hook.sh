#!/bin/bash

# SAGA Hook Executor
# Fires lifecycle hooks with fallback logging and knowledge storage
#
# Usage: fire-hook.sh <hook-name> <json-context>
# Example: fire-hook.sh on-task-start '{"storyId":"US-001",...}'

set -euo pipefail

HOOK_NAME="${1:-}"
CONTEXT="${2:-"{}"}"

if [[ -z "$HOOK_NAME" ]]; then
  echo "Error: Hook name required" >&2
  echo "Usage: fire-hook.sh <hook-name> <json-context>" >&2
  exit 1
fi

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

  # Add timestamp to entry
  local timestamped
  timestamped=$(echo "$entry" | jq --arg ts "$(date -Iseconds)" '. + {timestamp: $ts}')

  echo "$timestamped" >> "$filepath"
  log_hook "KNOWLEDGE" "Stored entry in $filename"
}

# Try to execute hook
execute_hook() {
  local hook_js="$HOOKS_DIR/${HOOK_NAME}.js"
  local hook_sh="$HOOKS_DIR/${HOOK_NAME}.sh"

  # Try JS hook first
  if [[ -f "$hook_js" && -x "$hook_js" ]]; then
    log_hook "EXECUTING" "JS hook $hook_js"

    # Check if node_modules exists
    if [[ -d "$HOOKS_DIR/node_modules" ]]; then
      if echo "$CONTEXT" | "$hook_js" 2>>"$HOOK_LOG"; then
        log_hook "SUCCESS" "JS hook completed"
        return 0
      else
        log_hook "FAILED" "JS hook failed, trying fallback"
      fi
    else
      log_hook "SKIPPED" "node_modules not installed, using fallback"
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

      commit_hash=$(echo "$CONTEXT" | jq -r '.commitHash // "unknown"')
      files_changed=$(echo "$CONTEXT" | jq -c '.filesChanged // []')
      linked_reqs=$(echo "$CONTEXT" | jq -c '.linkedRequirements // []')

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
