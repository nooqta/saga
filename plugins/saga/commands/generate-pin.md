---
description: "Generate a codebase Pin (searchable index) for SAGA context"
argument-hint: "[output path]"
---

# Generate Pin Command

Creates a searchable codebase index ("Pin") that provides context for SAGA spec, plan, and execution.

## What is a Pin?

A Pin is a condensed, searchable summary of your codebase that helps SAGA:
- Understand project structure without loading entire codebase
- Find relevant files for each story
- Identify existing patterns to follow
- Avoid duplicating existing functionality

## IMPORTANT: Working Directory

**All file operations are relative to the user's current working directory, NOT the plugin directory.**

- `.saga/pin.md` means `$CWD/.saga/pin.md`
- Always verify the working directory before file operations

## The Job

1. Scan the codebase structure
2. Extract key information from each file type
3. Generate a searchable index at `.saga/pin.md`
4. Include patterns, APIs, components, and conventions

## Scan Strategy

### Directory Structure
```
- Map all directories and their purposes
- Identify key folders: src/, lib/, components/, pages/, api/, etc.
- Note test directories and configuration files
```

### File Analysis

**For TypeScript/JavaScript:**
- Extract exports (functions, classes, types, interfaces)
- Identify API endpoints
- Map component hierarchy
- Note state management patterns

**For Python:**
- Extract classes and functions
- Identify entry points
- Map module structure

**For Config Files:**
- Package.json dependencies
- Build configuration
- Environment variables (names only, not values)

## Integration with Compounding Knowledge

When generating the pin, **incorporate learnings from `.saga/knowledge/`** if they exist:

1. **Read `patterns.jsonl`** - Extract successful patterns and their key files
2. **Read `blockers.jsonl`** - Note problematic areas and their resolutions
3. **Read `decisions.jsonl`** - Include architectural decisions

This creates a **unified context** where:
- Static codebase structure (from scanning)
- Dynamic learnings (from execution history)
- Are combined into a single reference document

### Knowledge Integration Process

```javascript
// Pseudo-code for knowledge integration
const patterns = readJsonl('.saga/knowledge/patterns.jsonl');
const blockers = readJsonl('.saga/knowledge/blockers.jsonl');

// Group patterns by file/component
const patternsByFile = groupBy(patterns, p => p.keyFiles[0]);

// Identify problematic areas
const problematicAreas = blockers.map(b => ({
  area: b.title,
  issue: b.blockedReason,
  resolution: b.rootCause
}));
```

## Output Format

Generate `.saga/pin.md` (or custom path from arguments) with this structure:

```markdown
# [Project Name] - Codebase Pin

Generated: [timestamp]
Files scanned: [count]
Total lines: [count]

## Project Overview

[Brief description from package.json, README, or inference]

## Directory Structure

```
src/
├── components/     # React components
├── pages/          # Next.js pages
├── lib/            # Utility functions
├── api/            # API routes
└── types/          # TypeScript types
```

## Key Patterns

### State Management
- [Pattern description]
- Key files: [list]

### API Layer
- [Pattern description]
- Endpoints defined in: [list]

### Component Architecture
- [Pattern description]
- Base components: [list]

## Public API

### Exports from src/index.ts
- `functionName(args)` - Description
- `ClassName` - Description
- `TypeName` - Description

### API Endpoints
- `GET /api/users` - List users
- `POST /api/auth/login` - Authenticate

## Types & Interfaces

### Core Types
```typescript
interface User { ... }
type AuthState = { ... }
```

## Dependencies

### Production
- react: ^18.0.0
- next: ^14.0.0

### Development
- typescript: ^5.0.0
- jest: ^29.0.0

## Conventions

### Naming
- Components: PascalCase
- Functions: camelCase
- Files: kebab-case

### File Organization
- One component per file
- Tests co-located with source

## Environment Variables

Required (names only):
- DATABASE_URL
- API_KEY
- NEXT_PUBLIC_*

## Build & Run

```bash
npm run dev      # Development
npm run build    # Production build
npm test         # Run tests
```

## Notes for Implementation

- [Key gotchas discovered]
- [Patterns to follow]
- [Areas to avoid modifying]

## Learned Patterns (from Knowledge Base)

> This section is auto-populated from `.saga/knowledge/patterns.jsonl` during pin generation.
> If no knowledge exists yet, this section will be empty.

### Successful Patterns
| Story | Pattern | Key Files |
|-------|---------|-----------|
| US-001 | Service layer for business logic | src/services/*.ts |
| US-003 | Form validation with Zod | src/components/forms/*.tsx |

### Known Issues & Resolutions
| Area | Issue | Resolution |
|------|-------|------------|
| Auth middleware | Token refresh race condition | Use mutex lock in refreshToken() |
| Database queries | N+1 query in user list | Added DataLoader for batching |

### Architectural Decisions
| Decision | Rationale | Date |
|----------|-----------|------|
| Use Zustand over Redux | Simpler API, smaller bundle | 2024-01-15 |
| PostgreSQL over MongoDB | Relational data model needed | 2024-01-10 |
```

## Scan Commands

Use these to gather information:

```bash
# Directory structure
find . -type d -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/.saga/*' | head -50

# TypeScript exports
grep -r "^export" --include="*.ts" --include="*.tsx" src/ 2>/dev/null | head -100

# Package dependencies
cat package.json 2>/dev/null | jq '.dependencies, .devDependencies' 2>/dev/null

# API routes (Next.js)
find . -path '*/api/*' -name '*.ts' 2>/dev/null | head -20

# React components
find . -name '*.tsx' -path '*/components/*' 2>/dev/null | head -30

# Python modules
find . -name '*.py' -not -path '*/.venv/*' -not -path '*/venv/*' 2>/dev/null | head -50

# Python exports
grep -r "^def \|^class " --include="*.py" . 2>/dev/null | head -100
```

## Generation Process

1. **Check for existing project context**:
   - Read `.saga/project.json` if it exists for project name and type
   - Fall back to package.json, setup.py, or directory name

2. **Scan the codebase**:
   - Use Glob and Grep tools to discover structure
   - Read key files (package.json, tsconfig.json, etc.)
   - Extract exports and patterns

3. **Integrate knowledge (if exists)**:
   - Read `.saga/knowledge/patterns.jsonl` for successful patterns
   - Read `.saga/knowledge/blockers.jsonl` for known issues
   - Read `.saga/knowledge/decisions.jsonl` for architectural decisions
   - Group and summarize for the "Learned Patterns" section

4. **Generate the pin**:
   - Create `.saga/pin.md` with the structured format
   - Include timestamp and file counts
   - Include knowledge-derived sections

5. **Display summary**:
   ```
   Pin Generated: .saga/pin.md

   Summary:
   - Files scanned: X
   - Exports found: Y
   - API endpoints: Z
   - Components: W
   - Patterns from knowledge: P
   - Known issues documented: I

   The pin will be automatically loaded by:
   - /saga spec (for requirement context)
   - /saga plan (for implementation planning)
   - /saga execute (for story execution context)
   ```

### Knowledge File Processing

When reading knowledge files, extract and summarize:

```bash
# Read patterns.jsonl and extract key info
if [ -f .saga/knowledge/patterns.jsonl ]; then
  # Get unique patterns grouped by area
  cat .saga/knowledge/patterns.jsonl | jq -s 'group_by(.keyFiles[0] // "unknown") | map({file: .[0].keyFiles[0], patterns: map(.pattern)})'
fi

# Read blockers.jsonl for known issues
if [ -f .saga/knowledge/blockers.jsonl ]; then
  # Get blockers with resolutions
  cat .saga/knowledge/blockers.jsonl | jq -s 'map({area: .title, issue: .blockedReason, category: .category})'
fi
```

## Output Location

Save to: `.saga/pin.md` (default) or custom path from arguments

## Regeneration Modes

### Automatic (During Execute)

When `autoPinRegeneration: true` in settings, the pin is automatically regenerated during `/saga execute`:

- **Interval**: Every `pinRegenerationInterval` iterations (default: 5)
- **Trigger**: After story completion, before evaluator runs
- **Content**: Incorporates all knowledge accumulated since last generation

Settings in `project.json` or `plan.json`:
```json
{
  "settings": {
    "autoPinRegeneration": true,
    "pinRegenerationInterval": 5
  }
}
```

### Manual (On Demand)

Run `/saga generate-pin` anytime to force regeneration:

- After major refactoring
- When adding new modules
- Before starting a new SRS
- When SAGA struggles to find patterns
- After completing an epic
- When you want immediate knowledge consolidation

### Knowledge Consolidation Cycle

```
Initial Pin (no knowledge)
        ↓
Execute stories → Knowledge accumulates in JSONL
        ↓
Auto-regenerate (every N iterations) OR Manual regenerate
        ↓
Pin now includes "Learned Patterns" section
        ↓
Future executions benefit from consolidated context
        ↓
Repeat...
```

**The feedback loop ensures:**
- Agents always have fresh, consolidated context
- Knowledge doesn't fragment across files
- Patterns discovered early benefit later stories

## Integration with SAGA

The Pin is automatically loaded by:
1. **spec** - When generating SRS, to understand existing capabilities
2. **plan** - When creating stories, to identify implementation patterns
3. **execute** - When story-executor needs codebase context

## Checklist

- [ ] Scanned all source directories
- [ ] Extracted public API
- [ ] Documented patterns
- [ ] Listed dependencies
- [ ] Noted environment variables (names only!)
- [ ] Included build commands
- [ ] Integrated knowledge from `.saga/knowledge/` (if exists)
- [ ] Added "Learned Patterns" section with patterns, issues, decisions
- [ ] Saved to .saga/pin.md
