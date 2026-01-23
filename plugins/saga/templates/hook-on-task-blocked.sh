#!/bin/bash
# SAGA lifecycle hook: on_task_blocked
# Fired after max retries exceeded
#
# Receives JSON via stdin with blocked context:
# {
#   "storyId": "US-001",
#   "title": "Add user authentication",
#   "blockedReason": "Typecheck failed: Cannot find module 'auth-lib'",
#   "retryCount": 3,
#   "linkedRequirements": ["FR-001"],
#   "errors": ["Error 1", "Error 2", "Error 3"],
#   "lastAttempt": {
#     "startedAt": "2024-01-15T10:30:00Z",
#     "completedAt": "2024-01-15T10:35:00Z",
#     "error": "Typecheck failed"
#   }
# }
#
# Copy this file to: .saga/hooks/on-task-blocked.sh
# Make executable: chmod +x .saga/hooks/on-task-blocked.sh

set -e

# Read JSON context from stdin
CONTEXT=$(cat)

# Parse fields using jq
STORY_ID=$(echo "$CONTEXT" | jq -r '.storyId')
STORY_TITLE=$(echo "$CONTEXT" | jq -r '.title')
BLOCKED_REASON=$(echo "$CONTEXT" | jq -r '.blockedReason')
RETRY_COUNT=$(echo "$CONTEXT" | jq -r '.retryCount')
ERRORS=$(echo "$CONTEXT" | jq -r '.errors | join("\n  - ")')
REQUIREMENTS=$(echo "$CONTEXT" | jq -r '.linkedRequirements | join(", ")')

# Log blocked status
echo "[SAGA Hook] BLOCKED story $STORY_ID: $STORY_TITLE"
echo "  Reason: $BLOCKED_REASON"
echo "  Attempts: $RETRY_COUNT"
echo "  Requirements: $REQUIREMENTS"
echo "  Errors:"
echo "  - $ERRORS"

# ============================================
# PM INTEGRATION
# ============================================
# Note: SAGA handles PM integration via the pm-workflow skill.
# This hook is for custom logic only.

# ============================================
# NOTIFICATIONS
# ============================================

# Slack (urgent notification)
# curl -X POST -H 'Content-type: application/json' \
#   --data "{\"text\":\"BLOCKED: SAGA could not complete $STORY_ID: $STORY_TITLE after $RETRY_COUNT attempts. Reason: $BLOCKED_REASON\"}" \
#   "$SLACK_WEBHOOK_URL"

# ============================================
# ALERTING
# ============================================

# PagerDuty (for critical stories)
# curl -X POST -H "Authorization: Token token=$PAGERDUTY_TOKEN" \
#   "https://events.pagerduty.com/v2/enqueue" \
#   -d "{\"routing_key\": \"$PAGERDUTY_SERVICE_KEY\", \"event_action\": \"trigger\", \"payload\": {\"summary\": \"SAGA blocked on $STORY_ID\", \"severity\": \"warning\", \"source\": \"saga\"}}"

# ============================================
# CUSTOM LOGIC
# ============================================
# Add your custom logic here
#
# Common actions:
# - Create a JIRA ticket for manual review
# - Send email to tech lead
# - Log to error tracking system

echo "[SAGA Hook] on_task_blocked finished for $STORY_ID"
