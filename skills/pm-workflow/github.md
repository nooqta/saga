# GitHub Integration Patterns

Detailed patterns for GitHub integration in SAGA.

## Authentication

Token should be available via environment variable:
- `GITHUB_TOKEN` (preferred)
- `GH_TOKEN` (alternative)

## Creating Issues

### Story Issue

```
Tool: mcp__plugin_github_github__issue_write
Parameters:
  method: create
  owner: {org from project config}
  repo: {repo from project config}
  title: "[{storyId}] {storyTitle}"
  body: |
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
  labels: ["saga", "story"]
```

### Change Request Issue

```
Tool: mcp__plugin_github_github__issue_write
Parameters:
  method: create
  owner: {org}
  repo: {repo}
  title: "[{crId}] {crTitle}"
  body: |
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
  labels: ["saga", "change-request"]
```

## Updating Issues

### Mark In Progress

```
Tool: mcp__plugin_github_github__issue_write
Parameters:
  method: update
  owner: {org}
  repo: {repo}
  issue_number: {issueNumber from pm-links.json}
  labels: ["saga", "story", "in-progress"]
```

### Mark Complete

```
Tool: mcp__plugin_github_github__issue_write
Parameters:
  method: update
  owner: {org}
  repo: {repo}
  issue_number: {issueNumber}
  state: closed
  labels: ["saga", "story", "done"]
```

### Mark Blocked

```
Tool: mcp__plugin_github_github__issue_write
Parameters:
  method: update
  owner: {org}
  repo: {repo}
  issue_number: {issueNumber}
  labels: ["saga", "story", "blocked"]
```

## Adding Comments

### Completion Comment

```
Tool: mcp__plugin_github_github__add_issue_comment
Parameters:
  owner: {org}
  repo: {repo}
  issue_number: {issueNumber}
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
Tool: mcp__plugin_github_github__add_issue_comment
Parameters:
  owner: {org}
  repo: {repo}
  issue_number: {issueNumber}
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

## Creating Pull Requests

```
Tool: mcp__plugin_github_github__create_pull_request
Parameters:
  owner: {org}
  repo: {repo}
  title: "[{storyId}] {storyTitle}"
  body: |
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

    - Closes #{issueNumber}
    - Requirements: {linkedRequirements}

    ---
    *Created by SAGA*
  head: {branch}
  base: main
  draft: false
```

## Searching for Existing Issues

Before creating, check if issue exists:

```
Tool: mcp__plugin_github_github__search_issues
Parameters:
  query: "repo:{org}/{repo} is:issue [{storyId}] in:title"
  owner: {org}
  repo: {repo}
```

If found, update instead of create.

## Label Management

Recommended labels:
- `saga` - All SAGA-managed issues
- `story` - User story issues
- `change-request` - CR issues
- `in-progress` - Currently being worked on
- `done` - Completed
- `blocked` - Cannot proceed
- `epic` - Epic-level issue (optional)

Create labels if they don't exist:
```
gh label create saga --color "#1f77b4" --description "Managed by SAGA"
gh label create story --color "#2ca02c" --description "User story"
gh label create change-request --color "#ff7f0e" --description "Change request"
```
