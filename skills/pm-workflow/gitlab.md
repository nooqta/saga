# GitLab Integration Patterns

Detailed patterns for GitLab integration in SAGA.

## Tool Availability

SAGA supports multiple methods for GitLab integration. Check availability in order:

### Method 1: MCP Tools (Preferred)
If `mcp__noqta_gitlab_server__*` tools are available, use them.

**Check for availability:**
- Look for MCP tools starting with `mcp__noqta_gitlab_server__`
- These provide direct API access with better error handling

### Method 2: glab CLI (Fallback)
If MCP tools unavailable, use the GitLab CLI (`glab`).

**Check for availability:**
```bash
which glab && glab auth status
```

## Authentication

Token should be available via environment variable:
- `GITLAB_TOKEN` (preferred)
- `GL_TOKEN` (alternative)

## Project Identification

GitLab uses project ID or URL-encoded path:
- Numeric ID: `12345`
- URL-encoded path: `group%2Fproject`

Get project info:
```
Tool: mcp__noqta_gitlab_server__get_project_from_git_url
Parameters:
  git_url: {git remote URL}
```

## Time Tracking & Assignment

### Duration Calculation

**IMPORTANT**: Always calculate duration from actual timestamps stored in plan.json metrics:

```javascript
// From plan.json story metrics
const startedAt = new Date(story.metrics.attempts[i].startedAt);
const completedAt = new Date(story.metrics.attempts[i].completedAt);
const durationMs = completedAt - startedAt;

// Format for display
const hours = Math.floor(durationMs / 3600000);
const minutes = Math.floor((durationMs % 3600000) / 60000);
const durationStr = hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`;

// Format for GitLab /spend command
const spendStr = hours > 0 ? `${hours}h${minutes}m` : `${minutes}m`;
```

### Time Tracking via Quick Actions

GitLab supports quick actions in issue comments. Use these for time tracking:

**Add Time Estimate:**
```
/estimate 2h
```

**Record Time Spent:**
```
/spend 1h30m
```

**Remove Estimate:**
```
/remove_estimate
```

**Remove Spent:**
```
/remove_time_spent
```

### Milestone Assignment

If a milestone is configured or active, assign stories to it:

```
Tool: mcp__noqta_gitlab_server__update_issue
Parameters:
  project_id: {projectId}
  issue_iid: {issueIID}
  milestone_id: {milestoneId}  # From project.json pm.milestone
```

Or via quick action in comment:
```
/milestone %"Sprint 5"
```

### User Assignment

**ALWAYS assign issues to the authenticated user:**

```
Tool: mcp__noqta_gitlab_server__update_issue
Parameters:
  project_id: {projectId}
  issue_iid: {issueIID}
  assignee_ids: [{userId}]  # From pm.assignee_id or search_user
```

Or via quick action:
```
/assign @username
/assign me
```

### Combined Quick Actions Comment

For maximum efficiency, combine actions in a single comment:

```
Tool: mcp__noqta_gitlab_server__create_issue_note
Parameters:
  project_id: {projectId}
  issue_iid: {issueIID}
  body: |
    /assign me
    /milestone %"Current Sprint"
    /estimate 2h
    /label ~"Doing"
    /unlabel ~"To Do"

    Starting work on this story.
```

## Creating Issues

### Story Issue with Full Metadata

```
Tool: mcp__noqta_gitlab_server__create_issue
Parameters:
  project_id: {projectId or encoded path}
  title: "[{storyId}] {storyTitle}"
  description: |
    ## User Story

    **ID:** {storyId}
    **Epic:** {epicId}
    **Feature:** {featureId}
    **Branch:** `{branch}`
    **Assigned:** @{assignee}

    ## Description

    {storyDescription}

    ## Acceptance Criteria

    {for each criterion}
    - [ ] {criterion}
    {end for}

    ## Linked Requirements

    {for each requirement}
    - {requirementId}: {requirementTitle}
    {end for}

    ## Estimates

    - **Estimated:** {estimate or "TBD"}
    - **Story Points:** {points or "N/A"}

    ## Traceability

    - SRS: `.saga/srs.md`
    - Plan: `.saga/plan.json`
    - Trace: `.saga/trace.md`

    ---
    *This issue is managed by SAGA. Do not modify labels manually.*
  labels: "saga,story,To Do"
  assignee_ids: [{userId}]
  milestone_id: {milestoneId}  # if available
```

### Change Request Issue

```
Tool: mcp__noqta_gitlab_server__create_issue
Parameters:
  project_id: {projectId}
  title: "[{crId}] {crTitle}"
  description: |
    ## Change Request

    **ID:** {crId}
    **Status:** Open
    **Created:** {timestamp}

    ## Description

    {crDescription}

    ## Impact Analysis

    ### Affected Requirements
    {impact table}

    ### Affected Stories
    {affected stories list}

    ### Estimated Effort
    {effort estimate}

    ---
    *This is a SAGA change request.*
  labels: "saga,change-request,To Do"
  assignee_ids: [{userId}]
```

## Updating Issues

### Mark In Progress (Story Start)

```
Tool: mcp__noqta_gitlab_server__create_issue_note
Parameters:
  project_id: {projectId}
  issue_iid: {issueIID}
  body: |
    /label ~"Doing"
    /unlabel ~"To Do"
    /estimate {estimatedDuration}

    **Starting iteration {iteration}**
    - Branch: `{branch}`
    - Agent: {agentRole}
    - Started: {timestamp}
```

### Mark In Review (Code Review)

```
Tool: mcp__noqta_gitlab_server__create_issue_note
Parameters:
  project_id: {projectId}
  issue_iid: {issueIID}
  body: |
    /label ~"Review"
    /unlabel ~"Doing"

    Code ready for review.
    - Commit: `{commitHash}`
    - Files changed: {fileCount}
```

### Mark Complete

```
Tool: mcp__noqta_gitlab_server__create_issue_note
Parameters:
  project_id: {projectId}
  issue_iid: {issueIID}
  body: |
    /label ~"Done"
    /unlabel ~"Doing" ~"Review"
    /spend {actualDuration}
    /close

    ## Story Completed

    **Commit:** `{commitHash}`
    **Duration:** {durationStr} (calculated from {startedAt} to {completedAt})
    **Iteration:** {iteration}

    ### Files Changed
    {for each file}
    - `{filePath}`
    {end for}

    ### Acceptance Criteria - All Met
    {for each criterion}
    - [x] {criterion}
    {end for}

    ### Agent Report
    - **Agent:** {agentRole}
    - **Tokens Used:** {tokens}
    - **Learnings:** {learnings}

    ---
    *Completed by SAGA at {timestamp}*
```

### Mark Blocked

```
Tool: mcp__noqta_gitlab_server__create_issue_note
Parameters:
  project_id: {projectId}
  issue_iid: {issueIID}
  body: |
    /label ~"On Hold"
    /unlabel ~"Doing"
    /spend {timeSpentSoFar}

    ## Story Blocked

    **Reason:** {blockedReason}
    **Attempts:** {retryCount}
    **Time Spent:** {timeSpentSoFar}

    ### Errors Encountered
    {for each error}
    - {error}
    {end for}

    ### Suggested Actions
    - Review the error details
    - Check dependencies
    - Manual intervention may be required

    ---
    *Blocked by SAGA at {timestamp}*
```

## Creating Merge Requests

```
Tool: mcp__noqta_gitlab_server__create_merge_request
Parameters:
  project_id: {projectId}
  source_branch: {branch}
  target_branch: main
  title: "[{storyId}] {storyTitle}"
  description: |
    ## Summary

    Implements {storyId}: {storyTitle}

    **Time Spent:** {actualDuration}
    **Agent:** {agentRole}

    ## Changes

    {for each file}
    - `{filePath}`
    {end for}

    ## Acceptance Criteria

    {for each criterion}
    - [x] {criterion}
    {end for}

    ## Related

    - Closes #{issueIID}
    - Requirements: {linkedRequirements}

    ---
    *Created by SAGA*
  assignee_id: {userId}
  reviewer_ids: [{reviewerIds}]
```

## Project Configuration

Enhanced `.saga/project.json` structure:

```json
{
  "pm": {
    "platform": "gitlab",
    "url": "https://gitlab.noqta.tn",
    "project": "group/project",
    "projectId": 260,
    "token_env": "GITLAB_TOKEN",
    "assignee": "marrouchi",
    "assignee_id": 1,
    "milestone": "Sprint 5",
    "milestone_id": 12,
    "default_estimate": "2h",
    "labels": {
      "todo": "To Do",
      "doing": "Doing",
      "review": "Review",
      "blocked": "On Hold",
      "done": "Done"
    },
    "workflow": {
      "on_story_start": {
        "create_issue": true,
        "assign_to_me": true,
        "set_milestone": true,
        "add_estimate": true,
        "add_labels": ["Doing"],
        "remove_labels": ["To Do"]
      },
      "on_story_complete": {
        "close_issue": true,
        "record_time_spent": true,
        "create_mr": false,
        "add_labels": ["Done"],
        "remove_labels": ["Doing", "Review"]
      },
      "on_story_blocked": {
        "add_labels": ["On Hold"],
        "remove_labels": ["Doing"],
        "add_comment": true,
        "record_time_spent": true
      },
      "on_code_review": {
        "add_labels": ["Review"],
        "remove_labels": ["Doing"]
      }
    }
  }
}
```

## Listing Issues

Find existing issues:

```
Tool: mcp__noqta_gitlab_server__list_issues
Parameters:
  project_id: {projectId}
  labels: "saga"
  state: opened
```

## GitLab-Specific Notes

### Labels
- GitLab labels are comma-separated strings, not arrays
- Labels are scoped to project (create them first if needed)
- Use `~"Label Name"` syntax for labels with spaces

### Issue IID vs ID
- `iid`: Internal ID within the project (use this)
- `id`: Global ID across all GitLab

### Quick Actions Reference
- `/assign @user` - Assign to user
- `/milestone %"name"` - Set milestone
- `/estimate Xh` - Set time estimate
- `/spend Xh` - Record time spent
- `/label ~"name"` - Add label
- `/unlabel ~"name"` - Remove label
- `/close` - Close issue
- `/reopen` - Reopen issue
- `/due YYYY-MM-DD` - Set due date

### Time Format
- Hours: `1h`, `2h30m`
- Minutes: `30m`, `45m`
- Days: `1d` (8 hours)
- Weeks: `1w` (40 hours)

## Error Handling

### API Errors
- Rate limiting: Wait and retry
- Auth failures: Log warning, continue without PM sync
- Network errors: Log warning, continue without PM sync

### Tool Unavailable
- MCP tools missing: Try glab CLI fallback
- CLI not installed: Warn user, continue without PM sync
- Both unavailable: Log warning, execution continues

### Missing Configuration
- If PM not configured, skip silently
- If token missing, warn user
