#!/bin/bash

# SAGA Stop Hook
# Prevents session exit when a saga loop is active
# Supports both explicit promise completion AND plan.json auto-completion

set -euo pipefail

# Read hook input from stdin (advanced stop hook API)
HOOK_INPUT=$(cat)

# Check if saga loop is active
SAGA_STATE_FILE=".saga/state.json"

if [[ ! -f "$SAGA_STATE_FILE" ]]; then
  # No active loop - allow exit
  exit 0
fi

# Parse state file with jq
if ! STATE=$(cat "$SAGA_STATE_FILE" 2>/dev/null); then
  echo "Warning: Could not read saga state file" >&2
  exit 0
fi

ITERATION=$(echo "$STATE" | jq -r '.iteration // 1')
MAX_ITERATIONS=$(echo "$STATE" | jq -r '.maxIterations // 0')
COMPLETION_PROMISE=$(echo "$STATE" | jq -r '.completionPromise // "COMPLETE"')
PLAN_PATH=$(echo "$STATE" | jq -r '.planPath // ".saga/plan.json"')

# Validate iteration is numeric
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  echo "Warning: SAGA state corrupted - removing" >&2
  rm -f "$SAGA_STATE_FILE"
  exit 0
fi

# Check if max iterations reached
if [[ "$MAX_ITERATIONS" =~ ^[0-9]+$ ]] && [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "SAGA loop: Max iterations ($MAX_ITERATIONS) reached."
  rm -f "$SAGA_STATE_FILE"
  exit 0
fi

# Get transcript path from hook input
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')

if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "Warning: Transcript file not found" >&2
  rm -f "$SAGA_STATE_FILE"
  exit 0
fi

# Read last assistant message from transcript
if ! grep -q '"role":"assistant"' "$TRANSCRIPT_PATH"; then
  echo "Warning: No assistant messages found" >&2
  rm -f "$SAGA_STATE_FILE"
  exit 0
fi

LAST_LINE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1)
LAST_OUTPUT=$(echo "$LAST_LINE" | jq -r '
  .message.content |
  map(select(.type == "text")) |
  map(.text) |
  join("\n")
' 2>/dev/null || echo "")

if [[ -z "$LAST_OUTPUT" ]]; then
  echo "Warning: Could not extract assistant output" >&2
  rm -f "$SAGA_STATE_FILE"
  exit 0
fi

# Check for explicit completion promise in <promise> tags
if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
  PROMISE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g; s/\s+/ /g' 2>/dev/null || echo "")

  if [[ -n "$PROMISE_TEXT" ]] && [[ "$PROMISE_TEXT" = "$COMPLETION_PROMISE" ]]; then
    echo "SAGA loop: Detected <promise>$COMPLETION_PROMISE</promise> - completing!"
    rm -f "$SAGA_STATE_FILE"
    exit 0
  fi
fi

# Check for plan.json auto-completion (all stories pass)
if [[ -f "$PLAN_PATH" ]]; then
  FAILING_COUNT=$(jq '[.userStories[] | select(.passes == false)] | length' "$PLAN_PATH" 2>/dev/null || echo "999")

  if [[ "$FAILING_COUNT" == "0" ]]; then
    echo "SAGA loop: All stories in plan.json are passing - auto-completing!"
    rm -f "$SAGA_STATE_FILE"
    exit 0
  fi
fi

# Not complete - continue loop
NEXT_ITERATION=$((ITERATION + 1))

# Update state file with new iteration
jq ".iteration = $NEXT_ITERATION" "$SAGA_STATE_FILE" > "${SAGA_STATE_FILE}.tmp" && mv "${SAGA_STATE_FILE}.tmp" "$SAGA_STATE_FILE"

# Read the prompt from state
PROMPT=$(echo "$STATE" | jq -r '.prompt // ""')

if [[ -z "$PROMPT" ]]; then
  echo "Warning: No prompt in state file" >&2
  rm -f "$SAGA_STATE_FILE"
  exit 0
fi

# Build system message
REMAINING_MSG=""
if [[ "$MAX_ITERATIONS" =~ ^[0-9]+$ ]] && [[ $MAX_ITERATIONS -gt 0 ]]; then
  REMAINING=$((MAX_ITERATIONS - NEXT_ITERATION + 1))
  REMAINING_MSG=" | $REMAINING iterations remaining"
fi

# Get coverage info if trace.md exists
COVERAGE_MSG=""
if [[ -f ".saga/trace.md" ]]; then
  # Try to extract coverage from trace.md header
  COVERAGE=$(head -20 ".saga/trace.md" | grep -o 'Covered: [0-9]*' | head -1 | grep -o '[0-9]*' || echo "")
  if [[ -n "$COVERAGE" ]]; then
    COVERAGE_MSG=" | Coverage: ${COVERAGE}%"
  fi
fi

SYSTEM_MSG="SAGA iteration $NEXT_ITERATION${REMAINING_MSG}${COVERAGE_MSG} | To complete: output <promise>$COMPLETION_PROMISE</promise> OR mark all plan.json stories as passes:true"

# Output JSON to block the stop and continue loop
jq -n \
  --arg prompt "$PROMPT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'

exit 0
