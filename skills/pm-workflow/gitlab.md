# GitLab Integration Patterns

Detailed patterns for GitLab integration in SAGA.

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

## Label Setup

Create labels via GitLab UI or API:
- `saga` - Blue - "Managed by SAGA"
- `story` - Green - "User story"
- `change-request` - Orange - "Change request"
- `in-progress` - Yellow - "Work in progress"
- `done` - Green - "Completed"
- `blocked` - Red - "Blocked"
