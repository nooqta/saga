#!/bin/bash
# SAGA lifecycle hook: on_task_completed
# Fired after story passes all checks
#
# Receives JSON via stdin with completion context:
# {
#   "storyId": "US-001",
#   "title": "Add user authentication",
#   "commitHash": "abc123def",
#   "filesChanged": ["src/auth.ts", "src/login.tsx"],
#   "linkedRequirements": ["FR-001"],
#   "metrics": {
#     "startedAt": "2024-01-15T10:30:00Z",
#     "completedAt": "2024-01-15T10:45:00Z",
#     "durationMs": 900000,
#     "tokensConsumed": 45000
#   }
# }
#
# Copy this file to: .saga/hooks/on-task-completed.sh
# Make executable: chmod +x .saga/hooks/on-task-completed.sh

set -e

# Read JSON context from stdin
CONTEXT=$(cat)

# Parse fields using jq
STORY_ID=$(echo "$CONTEXT" | jq -r '.storyId')
STORY_TITLE=$(echo "$CONTEXT" | jq -r '.title')
COMMIT_HASH=$(echo "$CONTEXT" | jq -r '.commitHash')
DURATION_MS=$(echo "$CONTEXT" | jq -r '.metrics.durationMs')
TOKENS=$(echo "$CONTEXT" | jq -r '.metrics.tokensConsumed')
FILES_CHANGED=$(echo "$CONTEXT" | jq -r '.filesChanged | join(", ")')
REQUIREMENTS=$(echo "$CONTEXT" | jq -r '.linkedRequirements | join(", ")')

# Calculate human-readable duration
DURATION_SEC=$((DURATION_MS / 1000))
DURATION_MIN=$((DURATION_SEC / 60))
DURATION_REMAINING_SEC=$((DURATION_SEC % 60))

# Log completion
echo "[SAGA Hook] Completed story $STORY_ID: $STORY_TITLE"
echo "  Duration: ${DURATION_MIN}m ${DURATION_REMAINING_SEC}s"
echo "  Tokens: $TOKENS"
echo "  Commit: $COMMIT_HASH"
echo "  Requirements: $REQUIREMENTS"

# ============================================
# PM INTEGRATION
# ============================================
# Note: SAGA handles PM integration via the pm-workflow skill.
# This hook is for custom logic only.

# ============================================
# NOTIFICATIONS
# ============================================

# Slack
# curl -X POST -H 'Content-type: application/json' \
#   --data "{\"text\":\"SAGA completed $STORY_ID: $STORY_TITLE in ${DURATION_MIN}m ${DURATION_REMAINING_SEC}s\"}" \
#   "$SLACK_WEBHOOK_URL"

# ============================================
# METRICS LOGGING
# ============================================
# Log metrics to a file for analysis
# echo "$CONTEXT" >> .saga/metrics.jsonl

# ============================================
# CUSTOM LOGIC
# ============================================
# Add your custom logic here

echo "[SAGA Hook] on_task_completed finished for $STORY_ID"
