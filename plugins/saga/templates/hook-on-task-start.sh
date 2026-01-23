#!/bin/bash
# SAGA lifecycle hook: on_task_start
# Fired before story-executor spawns
#
# Receives JSON via stdin with story context:
# {
#   "storyId": "US-001",
#   "title": "Add user authentication",
#   "branch": "saga/user-auth",
#   "iteration": 1,
#   "priority": 1,
#   "acceptanceCriteria": ["...", "..."],
#   "linkedRequirements": ["FR-001"]
# }
#
# Copy this file to: .saga/hooks/on-task-start.sh
# Make executable: chmod +x .saga/hooks/on-task-start.sh

set -e

# Read JSON context from stdin
CONTEXT=$(cat)

# Parse fields using jq
STORY_ID=$(echo "$CONTEXT" | jq -r '.storyId')
STORY_TITLE=$(echo "$CONTEXT" | jq -r '.title')
BRANCH=$(echo "$CONTEXT" | jq -r '.branch')
ITERATION=$(echo "$CONTEXT" | jq -r '.iteration')
REQUIREMENTS=$(echo "$CONTEXT" | jq -r '.linkedRequirements | join(", ")')

# Log start
echo "[SAGA Hook] Starting story $STORY_ID: $STORY_TITLE (iteration $ITERATION)"
echo "[SAGA Hook] Linked requirements: $REQUIREMENTS"

# ============================================
# PM INTEGRATION
# ============================================
# Note: SAGA handles PM integration via the pm-workflow skill.
# This hook is for custom logic only.
#
# If you need manual PM integration, uncomment below:

# GITHUB (using gh CLI)
# if [[ "$STORY_ID" =~ ^US-([0-9]+)$ ]]; then
#   # Create or update issue
#   gh issue edit "$ISSUE_NUM" --add-label "in-progress"
# fi

# GITLAB (using glab CLI)
# if [[ "$STORY_ID" =~ ^US-([0-9]+)$ ]]; then
#   glab issue update "$ISSUE_NUM" --label "in-progress"
# fi

# ============================================
# NOTIFICATIONS
# ============================================

# Slack
# curl -X POST -H 'Content-type: application/json' \
#   --data "{\"text\":\"SAGA starting $STORY_ID: $STORY_TITLE\"}" \
#   "$SLACK_WEBHOOK_URL"

# Discord
# curl -X POST -H 'Content-type: application/json' \
#   --data "{\"content\":\"SAGA starting $STORY_ID: $STORY_TITLE\"}" \
#   "$DISCORD_WEBHOOK_URL"

# ============================================
# CUSTOM LOGIC
# ============================================
# Add your custom logic here

echo "[SAGA Hook] on_task_start completed for $STORY_ID"
