---
name: pm-workflow
description: "Handle GitHub/GitLab integration for SAGA workflow events. Use when syncing stories with PM tools."
---

# PM Workflow Skill

Expert guidance for integrating SAGA with GitHub and GitLab project management.

## When to Use

- During `/saga execute` lifecycle events (story start, complete, blocked)
- During `/saga sync` manual synchronization
- During `/saga cr` change request creation
- When creating issues/MRs for stories

## Configuration

Read PM config from `.saga/project.json`:

```json
{
  "pm": {
    "platform": "github" | "gitlab",
    "url": "https://github.com",
    "project": "org/repo",
    "token_env": "GITHUB_TOKEN",
    "workflow": {
      "on_story_start": { ... },
      "on_story_complete": { ... },
      "on_story_blocked": { ... },
      "on_cr_created": { ... }
    }
  }
}
```

## Event Handlers

### on_story_start

Triggered when a story begins execution.

**Input Context:**
```json
{
  "storyId": "US-001",
  "title": "Implement login",
  "description": "...",
  "branch": "saga/feature",
  "iteration": 1,
  "linkedRequirements": ["FR-001"]
}
```

**Actions (based on workflow config):**

1. **Create Issue** (if `create_issue: true`):
   - GitHub: Use `mcp__plugin_github_github__issue_write`
   - GitLab: Use `mcp__noqta_gitlab_server__create_issue`

2. **Add Labels** (if `add_labels` defined):
   - GitHub: Include labels in issue creation or update
   - GitLab: Include labels in issue creation or update

**Example GitHub:**
```
mcp__plugin_github_github__issue_write:
  method: create
  owner: [org]
  repo: [repo]
  title: "[US-001] Implement login"
  body: |
    ## Story
    **ID:** US-001
    **Branch:** saga/feature

    ## Description
    [description]

    ## Acceptance Criteria
    - [ ] Criterion 1
    - [ ] Criterion 2

    ## Linked Requirements
    - FR-001

    ---
    *Managed by SAGA*
  labels: ["in-progress", "saga"]
```

### on_story_complete

Triggered when a story passes all checks.

**Input Context:**
```json
{
  "storyId": "US-001",
  "title": "Implement login",
  "commitHash": "abc123",
  "filesChanged": ["src/auth.ts"],
  "metrics": {
    "durationMs": 540000,
    "tokensConsumed": 22000
  }
}
```

**Actions:**

1. **Close Issue** (if `close_issue: true`):
   - GitHub: Use `mcp__plugin_github_github__issue_write` with `state: closed`
   - GitLab: Use `mcp__noqta_gitlab_server__update_issue` with `state_event: close`

2. **Create MR/PR** (if `create_mr: true`):
   - GitHub: Use `mcp__plugin_github_github__create_pull_request`
   - GitLab: Use `mcp__noqta_gitlab_server__create_merge_request`

3. **Update Labels** (if `add_labels` defined):
   - Remove "in-progress", add "done"

4. **Add Comment** with completion summary

### on_story_blocked

Triggered when a story exceeds max retries.

**Input Context:**
```json
{
  "storyId": "US-001",
  "title": "Implement login",
  "blockedReason": "Typecheck failed: missing dependency",
  "retryCount": 3,
  "errors": ["Error 1", "Error 2"]
}
```

**Actions:**

1. **Add Labels** (if `add_labels` defined):
   - Add "blocked" label
   - Remove "in-progress" label

2. **Add Comment** (if `add_comment: true`):
   - Include blocked reason and errors

### on_cr_created

Triggered when `/saga cr` creates a change request.

**Input Context:**
```json
{
  "crId": "CR-001",
  "title": "Add OAuth support",
  "description": "...",
  "impact": { ... }
}
```

**Actions:**

1. **Create Issue** (if `create_issue: true`):
   - Title: "[CR-001] Add OAuth support"
   - Labels: ["change-request", "saga"]
   - Body: CR summary with impact analysis

## Platform-Specific Patterns

### GitHub

**Available MCP Tools:**
- `mcp__plugin_github_github__issue_write` - Create/update issues
- `mcp__plugin_github_github__add_issue_comment` - Add comments
- `mcp__plugin_github_github__create_pull_request` - Create PRs
- `mcp__plugin_github_github__list_issues` - List issues
- `mcp__plugin_github_github__search_issues` - Search issues

**Issue Body Template:**
```markdown
## Story Details
**ID:** {storyId}
**Branch:** {branch}
**Requirements:** {linkedRequirements}

## Description
{description}

## Acceptance Criteria
{acceptanceCriteria as checkboxes}

---
*Managed by SAGA | [View Traceability](.saga/trace.md)*
```

### GitLab

**Available MCP Tools:**
- `mcp__noqta_gitlab_server__create_issue` - Create issues
- `mcp__noqta_gitlab_server__update_issue` - Update issues
- `mcp__noqta_gitlab_server__create_issue_note` - Add comments
- `mcp__noqta_gitlab_server__create_merge_request` - Create MRs
- `mcp__noqta_gitlab_server__list_issues` - List issues

**Issue Description Template:**
Same as GitHub, GitLab uses Markdown.

## Issue Linking

Store mappings in `.saga/pm-links.json`:

```json
{
  "stories": {
    "US-001": {
      "issueNumber": 123,
      "issueUrl": "https://github.com/org/repo/issues/123",
      "prNumber": null,
      "prUrl": null
    }
  },
  "changeRequests": {
    "CR-001": {
      "issueNumber": 150,
      "issueUrl": "https://github.com/org/repo/issues/150"
    }
  }
}
```

## Tool Availability Check

Before making PM calls, check tool availability:

### GitHub
1. **MCP Tools** (preferred): Check for `mcp__plugin_github_github__*` tools
2. **gh CLI** (fallback): `which gh && gh auth status`

### GitLab
1. **MCP Tools** (preferred): Check for `mcp__noqta_gitlab_server__*` tools
2. **glab CLI** (fallback): `which glab && glab auth status`

**If neither available:**
```
Warning: PM integration unavailable.
GitHub: Install gh CLI or configure GitHub MCP
GitLab: Install glab CLI or configure GitLab MCP
Continuing without PM sync.
```

## Error Handling

**API Errors:**
- Rate limiting: Wait and retry
- Auth failures: Log warning, continue without PM sync
- Network errors: Log warning, continue without PM sync

**Tool Unavailable:**
- MCP tools missing: Try CLI fallback
- CLI not installed: Warn user, continue without PM sync
- Both unavailable: Log warning, execution continues

**Missing Configuration:**
- If PM not configured, skip silently
- If token missing, warn user

## Best Practices

1. **Idempotent Operations**: Check if issue exists before creating
2. **Minimal API Calls**: Batch updates when possible
3. **Clear Labels**: Use consistent label naming (saga, in-progress, done, blocked)
4. **Traceability**: Always include story ID in issue title
5. **Links**: Include links back to SAGA artifacts in issue body
