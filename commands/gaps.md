---
description: "Show uncovered requirements and traceability gaps"
---

# Gap Analysis

Identify and display requirements that don't have implementation coverage.

## Pre-requisites

1. Check if `.saga/srs.md` exists
2. Check if `.saga/plan.json` exists

## Analysis Process

### 1. Extract All Requirements

From `.saga/srs.md`, extract:
- All FR-XXX (Functional Requirements)
- All NFR-XXX (Non-Functional Requirements)

### 2. Check Coverage

From `.saga/plan.json`, for each requirement:
- Find stories with `linkedRequirements` containing this requirement
- Determine coverage status

### 3. Categorize Gaps

**Fully Uncovered:**
- Requirement has NO linked stories

**Partially Covered:**
- Requirement is linked to stories, but not all acceptance criteria are addressed

**Covered but Blocked:**
- Requirement has linked story, but story is blocked

## Output Format

```
SAGA Gap Analysis
=================

## Coverage Summary

┌─────────────────────────────────────────────────┐
│ Total Requirements: 12                          │
│ Fully Covered: 8 (67%)                          │
│ Partially Covered: 2 (17%)                      │
│ Uncovered: 2 (17%)                              │
│                                                 │
│ Coverage: ████████░░░░ 67%                      │
└─────────────────────────────────────────────────┘

## Uncovered Requirements

### FR-007: Email Verification
**Priority:** High
**Description:** Users must verify their email address before accessing premium features.

**Impact:**
- Blocks premium feature rollout
- Security compliance requirement

**Suggested Action:**
- Create new story under F-002 (User Management)
- Link to FR-007
- Estimated effort: Medium

---

### NFR-003: API Response Time
**Priority:** Medium
**Description:** API endpoints must respond within 200ms for 95th percentile.

**Impact:**
- Performance SLA not guaranteed
- User experience may suffer

**Suggested Action:**
- Create performance optimization story
- Add monitoring/alerting story
- Estimated effort: High

---

## Partially Covered Requirements

### FR-004: User Profile Management
**Covered by:** US-004
**Missing Criteria:**
- [ ] Profile picture upload
- [ ] Account deletion

**Suggested Action:**
- Extend US-004 acceptance criteria, OR
- Create new story US-XXX for missing functionality

---

## Blocked Coverage

### FR-006: Data Import
**Covered by:** US-006 (BLOCKED)
**Blocked Reason:** Missing third-party API credentials

**Suggested Action:**
- Resolve blocker: Obtain API credentials
- Or: Create alternative implementation story

---

## Recommendations

1. **High Priority Gaps:**
   - FR-007 (Email Verification) - Security impact

2. **Medium Priority Gaps:**
   - NFR-003 (API Response Time) - Performance impact

3. **Quick Wins:**
   - FR-004 partial coverage can be fixed by extending US-004

## Commands

To address gaps:
  /saga plan          - Regenerate plan to cover gaps
  /saga spec          - Update SRS with new requirements
  /saga cr "..."      - Log change request for scope changes
```

## Gap Severity Levels

| Level | Criteria |
|-------|----------|
| Critical | Security or compliance requirement uncovered |
| High | Core functionality not covered |
| Medium | Important but not blocking functionality |
| Low | Nice-to-have or enhancement |

## Auto-Fix Suggestions

For each gap, suggest:
1. Which feature it should belong to
2. Draft story title and acceptance criteria
3. Priority based on requirement priority
4. Estimated effort

Example suggestion:
```
Suggested Story for FR-007:

{
  "id": "US-XXX",
  "title": "Implement email verification flow",
  "description": "As a user, I want to verify my email so that I can access premium features",
  "acceptanceCriteria": [
    "Verification email sent on registration",
    "Clicking link verifies the email",
    "Unverified users see prompt to verify",
    "Typecheck passes"
  ],
  "featureId": "F-002",
  "linkedRequirements": ["FR-007"],
  "priority": 3
}

Would you like me to add this story to plan.json? (y/n)
```

## Integration with Plan

If user confirms, automatically:
1. Add suggested story to `.saga/plan.json`
2. Update `.saga/trace.md`
3. Recalculate coverage metrics
