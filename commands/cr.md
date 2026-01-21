---
description: "Log a change request with impact analysis"
argument-hint: "\"change description\""
---

# Change Request

Log a change request (CR) that affects the project requirements or implementation.

## Usage

```
/saga cr "Add support for OAuth2 authentication"
/saga cr "Change user table to support multiple emails"
```

## Pre-requisites

1. Check if `.saga/project.json` exists
2. Check if `.saga/srs.md` exists
3. Check if `.saga/plan.json` exists
4. Create `.saga/changes/` directory if not exists

## Process

### 1. Parse Change Request

Extract from user input:
- Change description
- Implied scope (new feature, modification, removal)

### 2. Generate CR Document

Determine next CR number by checking existing files in `.saga/changes/`.

Create `.saga/changes/CR-XXX.md`:

```markdown
# Change Request CR-XXX

**Title:** [Short title from description]
**Requested:** [Current date/time]
**Status:** Open
**Priority:** [To be determined]

---

## Description

[Full description of the requested change]

---

## Impact Analysis

### Affected Requirements

| Requirement | Impact | Description |
|-------------|--------|-------------|
| FR-001      | Modify | Need to update authentication flow |
| FR-003      | None   | No impact |
| NEW         | Add    | New requirement needed: FR-XXX |

### Affected Features

| Feature | Impact |
|---------|--------|
| F-001   | Modify |

### Affected Stories

| Story  | Impact | Action Required |
|--------|--------|-----------------|
| US-001 | Modify | Update acceptance criteria |
| US-002 | None   | No change needed |
| NEW    | Add    | New story needed |

### Estimated Effort

- New stories required: X
- Stories to modify: Y
- Approximate complexity: Low/Medium/High

---

## Recommendation

[AI recommendation on how to proceed]

---

## Approval

- [ ] Impact reviewed
- [ ] Stakeholder approved
- [ ] SRS updated
- [ ] Plan updated

---

## History

| Date | Action | By |
|------|--------|-----|
| [date] | Created | SAGA |
```

### 3. Impact Analysis

Analyze against existing artifacts:

**SRS Impact:**
- Read `.saga/srs.md`
- Identify which FR/NFR requirements are affected
- Determine if new requirements are needed

**Plan Impact:**
- Read `.saga/plan.json`
- Identify affected features and stories
- Determine if stories need to be added/modified
- Check if blocked stories would be unblocked

**Traceability Impact:**
- Would this change create new gaps?
- Would this change close existing gaps?

### 4. Display Summary

```
Change Request Logged: CR-001

Title: Add support for OAuth2 authentication
Status: Open

Impact Summary:
┌─────────────────────────────────────────────┐
│ Requirements Affected: 2                    │
│   - FR-001: Modify authentication flow      │
│   - NEW: OAuth2 configuration requirement   │
│                                             │
│ Features Affected: 1                        │
│   - F-001: Authentication System            │
│                                             │
│ Stories Affected: 3                         │
│   - US-001: Modify (update auth logic)      │
│   - NEW: OAuth2 provider setup              │
│   - NEW: OAuth2 callback handling           │
│                                             │
│ Estimated New Work: 2 stories               │
└─────────────────────────────────────────────┘

Document: .saga/changes/CR-001.md

Next steps:
1. Review the impact analysis
2. Update SRS if approved: /saga spec (to add new requirements)
3. Update plan if approved: /saga plan (to add new stories)
4. Run /saga trace to see updated coverage
```

### 5. PM Integration

If PM tool configured and `workflow.on_cr_created.create_issue: true`:

**GitHub:**
```
Create issue with:
- Title: "CR-001: [Change title]"
- Labels: change-request, saga
- Body: Summary of change and impact
```

**GitLab:**
```
Create issue with:
- Title: "CR-001: [Change title]"
- Labels: change-request, saga
- Description: Summary of change and impact
```

Display: "Created issue #XXX in [platform]"

## List Change Requests

If user runs `/saga cr` without argument, show list:

```
Change Requests:

| CR    | Title                     | Status | Created    | Impact |
|-------|---------------------------|--------|------------|--------|
| CR-001| OAuth2 support            | Open   | 2024-01-15 | High   |
| CR-002| Add email verification    | Closed | 2024-01-14 | Medium |

Commands:
  /saga cr "description"  - Create new CR
  /saga cr view CR-001    - View CR details
  /saga cr close CR-001   - Close a CR
```

## CR Lifecycle

1. **Open**: CR logged, awaiting review
2. **Approved**: Impact accepted, ready to implement
3. **In Progress**: Changes being made to SRS/plan
4. **Closed**: CR fully addressed (or rejected)

## Close CR

When changes are implemented:

```
/saga cr close CR-001
```

This updates the CR status and adds to history.
