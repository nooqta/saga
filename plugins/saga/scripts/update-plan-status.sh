#!/bin/bash

# Update Plan Status Script
# Updates a story's pass status and notes in plan.json

set -euo pipefail

# Usage: update-plan-status.sh <story-id> <pass|fail> [notes]

if [[ $# -lt 2 ]]; then
  echo "Usage: update-plan-status.sh <story-id> <pass|fail> [notes]" >&2
  exit 1
fi

STORY_ID="$1"
STATUS="$2"
NOTES="${3:-}"
PLAN_PATH="${PLAN_PATH:-.saga/plan.json}"

if [[ ! -f "$PLAN_PATH" ]]; then
  echo "Error: Plan file not found: $PLAN_PATH" >&2
  exit 1
fi

# Validate status
case "$STATUS" in
  pass|true|1)
    PASSES=true
    ;;
  fail|false|0)
    PASSES=false
    ;;
  *)
    echo "Error: Status must be 'pass' or 'fail', got: $STATUS" >&2
    exit 1
    ;;
esac

# Check if story exists
if ! jq -e ".userStories[] | select(.id == \"$STORY_ID\")" "$PLAN_PATH" > /dev/null 2>&1; then
  echo "Error: Story not found: $STORY_ID" >&2
  exit 1
fi

# Update the story
TEMP_FILE="${PLAN_PATH}.tmp.$$"

if [[ -n "$NOTES" ]]; then
  jq "(.userStories[] | select(.id == \"$STORY_ID\")) |= . + {passes: $PASSES, notes: \"$NOTES\"}" "$PLAN_PATH" > "$TEMP_FILE"
else
  jq "(.userStories[] | select(.id == \"$STORY_ID\")).passes = $PASSES" "$PLAN_PATH" > "$TEMP_FILE"
fi

mv "$TEMP_FILE" "$PLAN_PATH"

# Output result
echo "Updated $STORY_ID: passes=$PASSES"

# Check if all stories pass
TOTAL=$(jq '.userStories | length' "$PLAN_PATH")
PASSING=$(jq '[.userStories[] | select(.passes == true)] | length' "$PLAN_PATH")

echo "Progress: $PASSING/$TOTAL stories passing"

if [[ "$PASSING" -eq "$TOTAL" ]]; then
  echo ""
  echo "All stories complete!"
fi
