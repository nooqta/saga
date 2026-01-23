---
description: "Manual sync with PM tool (GitHub/GitLab)"
argument-hint: "[--full | --issues | --status]"
---

# PM Sync

Manually synchronize SAGA state with the configured PM tool (GitHub or GitLab).

## Pre-requisites

1. Check `.saga/project.json` for PM configuration
2. If `pm.platform` is "none": "No PM tool configured. Run `/saga init` to set up PM integration."
3. Verify token is available in environment

## Usage

```
/saga sync              # Smart sync - only changed items
/saga sync --full       # Full sync - recreate all issues
/saga sync --issues     # Only sync issues (create missing)
/saga sync --status     # Only update issue statuses
```

## Sync Process

### 1. Load Configuration

Read from `.saga/project.json`:
```json
{
  "pm": {
    "platform": "github",
    "url": "https://github.com",
    "project": "org/repo",
    "token_env": "GITHUB_TOKEN",
    "workflow": { ... }
  }
}
```

### 2. Load Current State

Read from:
- `.saga/plan.json` - Stories and their status
- `.saga/progress.txt` - Recent activity
- `.saga/changes/` - Change requests

### 3. Determine Actions

**For each story in plan.json:**

| Story Status | Issue Exists | Action |
|--------------|--------------|--------|
| passes: false, not started | No | Create issue (if workflow allows) |
| passes: false, not started | Yes | No action |
| passes: false, in progress | No | Create issue with in-progress label |
| passes: false, in progress | Yes | Update labels to in-progress |
| passes: true | Yes, open | Close issue, add done label |
| passes: true | Yes, closed | No action |
| blocked | Yes | Add blocked label, comment with reason |

**For each change request:**

| CR Status | Issue Exists | Action |
|-----------|--------------|--------|
| Open | No | Create issue with CR label |
| Open | Yes | No action |
| Closed | Yes, open | Close issue |

### 4. Execute Sync

Use the pm-workflow skill to perform actions:

**GitHub Actions:**
```
- mcp__plugin_github_github__issue_write (create/update)
- mcp__plugin_github_github__add_issue_comment
- mcp__plugin_github_github__create_pull_request
```

**GitLab Actions:**
```
- mcp__noqta_gitlab_server__create_issue
- mcp__noqta_gitlab_server__update_issue
- mcp__noqta_gitlab_server__create_issue_note
- mcp__noqta_gitlab_server__create_merge_request
```

### 5. Store Issue Mappings

Update `.saga/pm-links.json`:
```json
{
  "stories": {
    "US-001": { "issueNumber": 123, "url": "https://github.com/org/repo/issues/123" },
    "US-002": { "issueNumber": 124, "url": "https://github.com/org/repo/issues/124" }
  },
  "changeRequests": {
    "CR-001": { "issueNumber": 130, "url": "https://github.com/org/repo/issues/130" }
  },
  "lastSync": "2024-01-15T10:30:00Z"
}
```

## Output Format

```
SAGA PM Sync
============

Platform: GitHub (org/repo)
Last Sync: 2024-01-15 10:30:00

Sync Actions:
┌─────────────────────────────────────────────────────┐
│ ✅ US-001: Issue #123 already up to date            │
│ ✅ US-002: Issue #124 closed (story passed)         │
│ ➕ US-003: Created issue #125                       │
│ 🏷️  US-004: Added 'in-progress' label to #126       │
│ 💬 US-005: Added blocked comment to #127            │
│ ➕ CR-001: Created issue #130                       │
└─────────────────────────────────────────────────────┘

Summary:
- Issues created: 2
- Issues updated: 2
- Issues closed: 1
- Comments added: 1

PM Links updated: .saga/pm-links.json
```

## Sync Modes

### Smart Sync (default)
Only syncs items that have changed since last sync.
```
/saga sync
```

### Full Sync
Recreates all issues (useful for fresh PM setup).
```
/saga sync --full
```
Warning: May create duplicates if issues already exist without mapping.

### Issues Only
Only creates missing issues, doesn't update status.
```
/saga sync --issues
```

### Status Only
Only updates status of existing issues.
```
/saga sync --status
```

## Error Handling

```
Sync Errors:
┌─────────────────────────────────────────────────────┐
│ ❌ US-006: Failed to create issue                   │
│    Error: API rate limit exceeded                   │
│    Action: Wait and retry, or sync manually         │
│                                                     │
│ ⚠️  US-007: Issue #128 not found                    │
│    Action: Issue may have been deleted externally   │
│    Suggestion: Run /saga sync --full to recreate   │
└─────────────────────────────────────────────────────┘

Partial sync completed. 5/7 items synced successfully.
```

## Bi-directional Sync

Future enhancement: Read PM tool state and update SAGA state.

Currently SAGA is the source of truth:
- SAGA → PM tool (one-way)
- PM tool changes should be reflected via manual updates

## Dry Run

Preview what would happen without making changes:
```
/saga sync --dry-run
```

Output shows planned actions without executing them.
