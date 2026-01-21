---
description: "Show SAGA progress dashboard with coverage metrics"
---

# SAGA Status

Display the current status of SAGA execution with full coverage and traceability metrics.

## Check These Items

### 1. SAGA Loop State

Check if `.saga/state.json` exists:
- If exists: Show iteration count, max iterations, completion promise
- If not: "No active SAGA loop"

### 2. Project Info

Read `.saga/project.json`:
- Project name and description
- PM platform and project
- Workflow configuration summary

### 3. Plan Status

Read `.saga/plan.json` if it exists:
- Show project name and branch
- List epics with completion status
- List features with completion status
- List all user stories with their pass/fail status
- Calculate completion percentage
- Highlight the next story to work on (first with `passes: false`)

### 4. Traceability Coverage

Read `.saga/trace.md` or calculate from plan.json:
- Total requirements from SRS
- Requirements with linked stories
- Requirements without coverage (gaps)
- Coverage percentage

### 5. Progress Log

Check `.saga/progress.txt` if it exists:
- Show the Codebase Patterns section if present
- Show the last 2-3 entries

### 6. PM Integration Status

If PM configured:
- Show linked issues
- Show recent PM activity

## Output Format

```
╔══════════════════════════════════════════════════════════════════╗
║                        SAGA Status Dashboard                      ║
╠══════════════════════════════════════════════════════════════════╣

## Loop State
┌────────────────────────────────────────────┐
│ Active: Yes/No                             │
│ Iteration: X of Y (or X, unlimited)        │
│ Mode: sequential/parallel                  │
│ Started: 2024-01-15 10:30:00              │
└────────────────────────────────────────────┘

## Project
┌────────────────────────────────────────────┐
│ Name: [Project Name]                       │
│ Branch: [branch-name]                      │
│ PM: GitHub (org/repo)                      │
└────────────────────────────────────────────┘

## Requirements Coverage
┌────────────────────────────────────────────┐
│ Total Requirements: 10                     │
│ Covered: 8 (80%) ████████░░                │
│ Gaps: 2 (20%)                              │
│                                            │
│ Functional: 7/8 covered                    │
│ Non-Functional: 1/2 covered                │
└────────────────────────────────────────────┘

## Epic Progress
┌────────────────────────────────────────────┐
│ E-001: User Management      [████████░░] 80%│
│   ├─ F-001: Authentication  [██████████] ✓ │
│   └─ F-002: User Profile    [████░░░░░░] 40%│
│                                            │
│ E-002: Data Processing      [░░░░░░░░░░] 0% │
│   └─ F-003: Import/Export   [░░░░░░░░░░] 0% │
└────────────────────────────────────────────┘

## Story Status

| ID     | Title                    | Status | Req    |
|--------|--------------------------|--------|--------|
| US-001 | Add user authentication  | ✅ PASS| FR-001 |
| US-002 | Create login page        | ✅ PASS| FR-002 |
| US-003 | Add session management   | 🔄 WIP | FR-003 | <-- Current
| US-004 | User profile page        | ⏳     | FR-004 |
| US-005 | Profile editing          | ⏳     | FR-005 |
| US-006 | Data import              | 🚫 BLK | FR-006 |

Progress: 2/6 stories (33%) ███░░░░░░░

## PM Integration
┌────────────────────────────────────────────┐
│ Platform: GitHub                           │
│ Issues Created: 4                          │
│ Issues Closed: 2                           │
│ PRs/MRs Created: 2                         │
│                                            │
│ Recent:                                    │
│   #123 - US-001 (closed)                   │
│   #124 - US-002 (closed)                   │
│   #125 - US-003 (in-progress)              │
└────────────────────────────────────────────┘

## Recent Activity
┌────────────────────────────────────────────┐
│ [2024-01-15 10:45] US-002 completed        │
│   Duration: 8m 30s                         │
│   Files: src/login.ts, src/LoginForm.tsx   │
│                                            │
│ [2024-01-15 10:30] US-001 completed        │
│   Duration: 12m 15s                        │
│   Files: src/auth.ts, src/middleware.ts    │
└────────────────────────────────────────────┘

## Codebase Patterns
┌────────────────────────────────────────────┐
│ • Auth: JWT tokens stored in httpOnly      │
│   cookies                                  │
│ • Components: Use shadcn/ui patterns       │
│ • Testing: Jest + React Testing Library    │
└────────────────────────────────────────────┘

╚══════════════════════════════════════════════════════════════════╝
```

## Status Icons

| Icon | Meaning |
|------|---------|
| ✅ | Completed/Passed |
| 🔄 | Work in Progress |
| ⏳ | Pending |
| 🚫 | Blocked |
| ⚠️ | Gap (uncovered) |

## Commands Available

After showing status, remind the user:

```
Commands:
  /saga execute   - Start or continue execution
  /saga cancel    - Stop the loop
  /saga trace     - View full traceability matrix
  /saga gaps      - See uncovered requirements
  /saga sync      - Manual PM sync
  /saga cr        - Log a change request
```

## Quick Status (Minimal)

If user just wants a quick check:

```
SAGA: 2/6 stories (33%) | Coverage: 80% | Next: US-003
```
