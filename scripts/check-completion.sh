#!/bin/bash

# Check Completion Script
# Checks if all stories in plan.json are passing

set -euo pipefail

PLAN_PATH="${1:-.saga/plan.json}"

if [[ ! -f "$PLAN_PATH" ]]; then
  echo "Error: Plan file not found: $PLAN_PATH" >&2
  exit 1
fi

# Count stories
TOTAL=$(jq '.userStories | length' "$PLAN_PATH")
PASSING=$(jq '[.userStories[] | select(.passes == true)] | length' "$PLAN_PATH")
FAILING=$((TOTAL - PASSING))

# Output status
echo "SAGA Plan Status: $PLAN_PATH"
echo "============================================"
echo ""

# List all stories with status
jq -r '.userStories[] | "\(.id): \(.title) [\(if .passes then "PASS" else "FAIL" end)]"' "$PLAN_PATH"

echo ""
echo "============================================"
echo "Progress: $PASSING/$TOTAL passing ($FAILING remaining)"
echo ""

if [[ "$FAILING" -eq 0 ]]; then
  echo "STATUS: COMPLETE - All stories passing!"
  exit 0
else
  # Show next story to work on
  NEXT_STORY=$(jq -r '[.userStories[] | select(.passes == false)][0] | "\(.id): \(.title)"' "$PLAN_PATH")
  echo "STATUS: IN PROGRESS"
  echo "Next story: $NEXT_STORY"
  exit 1
fi
