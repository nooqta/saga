---
description: "Create Epic/Feature/Story hierarchy from SRS"
argument-hint: ""
---

# Plan Generation

You are creating an implementation plan with Epic → Feature → Story hierarchy from the SRS.

## IMPORTANT: Working Directory

**All file operations are relative to the user's current working directory, NOT the plugin directory.**

- `.saga/plan.json` means `$CWD/.saga/plan.json`
- `.saga/trace.md` means `$CWD/.saga/trace.md`
- Always verify the working directory before file operations

## Validation

After generating, you can validate the output:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/validate-saga.sh" --verbose
```

## Pre-requisites

1. Check if `.saga/srs.md` exists in the **current working directory**
   - If not: "Please run `/saga spec` first to generate the SRS."

2. Read project context from `.saga/project.json`
3. Read requirements from `.saga/srs.md`

## Generation Process

### 1. Analyze SRS

Parse the SRS to extract:
- All FR-XXX (Functional Requirements)
- All NFR-XXX (Non-Functional Requirements)
- System Features
- Acceptance Criteria

### 2. Create Hierarchy

Map requirements to a hierarchy:

```
Epic (E-001): Major capability or milestone
  └── Feature (F-001): Functional area
        └── User Story (US-001): Implementable unit
              └── Acceptance Criteria (from FR-XXX)
              └── Links to: FR-XXX
```

### 3. Generate plan.json

Create `.saga/plan.json`:

```json
{
  "project": "Project Name",
  "branchName": "saga/main",
  "description": "Project description",
  "createdAt": "2024-01-15T10:00:00Z",
  "srsVersion": "1.0",
  "epics": [
    {
      "id": "E-001",
      "title": "Epic Title",
      "description": "Epic description",
      "features": [
        {
          "id": "F-001",
          "title": "Feature Title",
          "description": "Feature description",
          "epicId": "E-001"
        }
      ]
    }
  ],
  "userStories": [
    {
      "id": "US-001",
      "title": "Story Title",
      "description": "As a [user], I want [feature] so that [benefit]",
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2",
        "Typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "featureId": "F-001",
      "epicId": "E-001",
      "linkedRequirements": ["FR-001", "FR-002"],
      "notes": ""
    }
  ],
  "settings": {
    "tddRequired": true,
    "autoPush": false,
    "executionMode": "sequential",
    "evaluatorEnabled": true,
    "allowReorder": true,
    "evaluateEveryNIterations": 3,
    "maxRetries": 3
  }
}
```

### 4. Story Guidelines

When creating stories:

1. **Atomic**: Each story should be completable in one iteration
2. **Testable**: Include "Typecheck passes" as minimum criterion
3. **Traceable**: Always link to source requirements (FR-XXX)
4. **Ordered**: Set priorities based on dependencies
5. **Clear**: Use "As a [user], I want [feature] so that [benefit]" format

### 5. Priority Assignment

Assign priorities based on:
1. Dependencies (prerequisite stories first)
2. Risk (high-risk items earlier for feedback)
3. Value (high-value features prioritized)
4. Complexity (simpler stories first to build momentum)

## After Generation

### 1. Display Summary

```
Plan Generated: .saga/plan.json

Hierarchy:
├── E-001: [Epic Title]
│   ├── F-001: [Feature Title]
│   │   ├── US-001: [Story Title] → FR-001
│   │   └── US-002: [Story Title] → FR-002
│   └── F-002: [Feature Title]
│       └── US-003: [Story Title] → FR-003, FR-004
└── E-002: [Epic Title]
    └── F-003: [Feature Title]
        └── US-004: [Story Title] → FR-005

Summary:
- Epics: 2
- Features: 3
- Stories: 4
- Requirements covered: 5/5 (100%)

Next steps:
- Run /saga trace to view traceability matrix
- Run /saga gaps to check for uncovered requirements
- Run /saga execute to start implementation
```

### 2. Generate Traceability

Automatically create `.saga/trace.md`:

```markdown
# Traceability Matrix

| Requirement | Feature | Story | Status | Test |
|-------------|---------|-------|--------|------|
| FR-001      | F-001   | US-001| ⏳ Pending | ❌ |
| FR-002      | F-001   | US-002| ⏳ Pending | ❌ |
| FR-003      | F-002   | US-003| ⏳ Pending | ❌ |
```

### 3. PM Integration

If PM integration is configured:
- Ask: "Would you like me to create issues for each story in [platform]?"
- If yes, use pm-workflow skill to create issues with labels

## Validation

Before completing:
- [ ] All FR-XXX from SRS have linked stories
- [ ] All stories have at least one acceptance criterion
- [ ] No circular dependencies in priorities
- [ ] plan.json is valid JSON

## Gap Detection

If any requirements are not covered:
```
Warning: The following requirements have no linked stories:
- FR-007: [Requirement title]
- NFR-002: [Requirement title]

Run /saga gaps to see detailed gap analysis.
```

## Iterative Updates

If plan.json already exists:
- Ask: "A plan already exists. Would you like to:"
  - "1. Regenerate from scratch"
  - "2. Add new stories for uncovered requirements"
  - "3. Cancel"
