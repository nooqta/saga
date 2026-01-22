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

If `glab` is not installed or authenticated:
```
Warning: GitLab CLI not available. Install with:
  brew install glab    # macOS
  apt install glab     # Debian/Ubuntu

Then authenticate:
  glab auth login
```

### Method 3: gh CLI with GitLab (Limited)
GitHub CLI can work with GitLab Enterprise instances via environment variables.

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

## Creating Issues

### Story Issue

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

    ## Traceability

    - SRS: `.saga/srs.md`
    - Plan: `.saga/plan.json`
    - Trace: `.saga/trace.md`

    ---
    *This issue is managed by SAGA. Do not modify labels manually.*
  labels: "saga,story"
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
  labels: "saga,change-request"
```

## Updating Issues

### Mark In Progress

```
Tool: mcp__noqta_gitlab_server__update_issue
Parameters:
  project_id: {projectId}
  issue_iid: {issueIID from pm-links.json}
  add_labels: "in-progress"
```

### Mark Complete

```
Tool: mcp__noqta_gitlab_server__update_issue
Parameters:
  project_id: {projectId}
  issue_iid: {issueIID}
  state_event: close
  remove_labels: "in-progress"
  add_labels: "done"
```

### Mark Blocked

```
Tool: mcp__noqta_gitlab_server__update_issue
Parameters:
  project_id: {projectId}
  issue_iid: {issueIID}
  remove_labels: "in-progress"
  add_labels: "blocked"
```

## Adding Comments (Notes)

### Completion Comment

```
Tool: mcp__noqta_gitlab_server__create_issue_note
Parameters:
  project_id: {projectId}
  issue_iid: {issueIID}
  body: |
    ## Story Completed ✅

    **Commit:** `{commitHash}`
    **Duration:** {duration}
    **Tokens Used:** {tokens}

    ### Files Changed
    {for each file}
    - `{filePath}`
    {end for}

    ### Learnings
    {learnings if any}

    ---
    *Completed by SAGA at {timestamp}*
```

### Blocked Comment

```
Tool: mcp__noqta_gitlab_server__create_issue_note
Parameters:
  project_id: {projectId}
  issue_iid: {issueIID}
  body: |
    ## Story Blocked 🚫

    **Reason:** {blockedReason}
    **Attempts:** {retryCount}

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

### Issue IID vs ID
- `iid`: Internal ID within the project (use this)
- `id`: Global ID across all GitLab

### Merge Request vs Pull Request
- GitLab uses "Merge Request" (MR)
- GitHub uses "Pull Request" (PR)
- SAGA config uses `create_mr` for both

### Project Path Encoding
- Slashes must be URL-encoded: `group/project` → `group%2Fproject`
- Or use numeric project ID

## glab CLI Fallback Patterns

When MCP tools are unavailable, use these glab CLI commands:

### Creating Issues

```bash
glab issue create \
  --title "[US-001] Story Title" \
  --description "## Story Details
**ID:** US-001
**Branch:** saga/feature

## Description
Story description here

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

---
*Managed by SAGA*" \
  --label "saga,story,in-progress"
```

### Updating Issues

```bash
# Add labels
glab issue update 123 --label "in-progress"

# Close issue
glab issue close 123

# Add comment
glab issue note 123 --message "Story completed. Commit: abc123"
```

### Creating Merge Requests

```bash
glab mr create \
  --source-branch "saga/US-001" \
  --target-branch "main" \
  --title "[US-001] Story Title" \
  --description "Closes #123" \
  --remove-source-branch
```

### Listing Issues

```bash
# List SAGA issues
glab issue list --label saga

# Search by title
glab issue list --search "US-001"
```

## Label Setup

Create labels via GitLab UI or API:
- `saga` - Blue - "Managed by SAGA"
- `story` - Green - "User story"
- `change-request` - Orange - "Change request"
- `in-progress` - Yellow - "Work in progress"
- `done` - Green - "Completed"
- `blocked` - Red - "Blocked"

## Troubleshooting

### MCP Tools Not Found
If `mcp__noqta_gitlab_server__*` tools are not available:
1. Check if the noqta_gitlab_server MCP is configured
2. Fall back to glab CLI commands
3. Warn user about limited functionality

### Authentication Issues
```bash
# Check glab authentication
glab auth status

# Re-authenticate
glab auth login --hostname gitlab.example.com
```

### Project Detection
```bash
# Get current project from git remote
git remote get-url origin | sed 's/.*gitlab.com[:/]\(.*\)\.git/\1/'
```
