---
description: "Execute a single user story from plan.json. Use during SAGA loop iterations to implement stories correctly."
capabilities: ["story-implementation", "acceptance-verification", "commit-management", "quality-gates", "error-recovery"]
---

# Story Execution Skill

Expert guidance for implementing a single user story in one SAGA iteration.

## When to Use

- During SAGA loop iterations
- When implementing a story from plan.json
- When you need to ensure proper execution flow

## Execution Flow

### 1. Pre-Implementation
- Read `.saga/plan.json` to get story details
- Read `.saga/progress.txt` for codebase patterns
- Read `.saga/srs.md` to understand requirement context
- Check you're on the correct branch
- Identify the target story (first with `passes: false`)

### 2. Implementation
- Implement ONLY the acceptance criteria listed
- Follow existing code patterns
- Keep changes minimal and focused
- Don't add extras not in acceptance criteria
- Maintain traceability (story links to requirement)

### 3. Verification
- Run typecheck (required for all stories)
- Run linter if configured
- Run tests if relevant
- For UI stories: verify visually if possible

### 4. Post-Implementation
- Commit with message: `feat: [US-XXX] - [Story Title]`
- Report result to orchestrator
- Document learnings

## Quality Gates

A story is only complete when:

- [ ] All acceptance criteria met
- [ ] Typecheck passes
- [ ] No linting errors
- [ ] Changes committed
- [ ] Learnings documented

## Common Mistakes to Avoid

1. **Scope Creep**: Implementing more than the acceptance criteria
2. **Skipping Verification**: Not running typecheck/tests
3. **Breaking Changes**: Changing code outside story scope
4. **Missing Commits**: Forgetting to commit before returning
5. **Ignoring Patterns**: Not following existing codebase conventions
6. **Over-Engineering**: Adding unnecessary abstraction

## Progress Entry Format

Document learnings for `.saga/progress.txt`:

```
## [Date] - [Story ID]
- What was implemented
- Files changed
- Linked requirements: FR-XXX
- **Learnings:**
  - Patterns discovered
  - Gotchas encountered
---
```

## Traceability

Always maintain traceability:
- Story → Requirement (via `linkedRequirements`)
- Code → Story (via commit message)
- Test → Story (via test naming)

## Commit Message Format

```
feat: [US-001] - Implement user authentication

- Add login endpoint
- Add session management
- Add password validation

Linked: FR-001, FR-002
```

## When to Ask for Help

Escalate to orchestrator if:
- Requirement is ambiguous
- Blocker discovered
- Story seems too large
- Dependency missing

## Verification Commands

Common verification:
```bash
# TypeScript
npm run typecheck
npx tsc --noEmit

# Linting
npm run lint
npx eslint .

# Tests
npm test
npm run test:unit

# Build
npm run build
```

## Error Recovery

If verification fails:
1. Read error message carefully
2. Make minimal fix
3. Re-run verification
4. If still failing after 3 attempts, report blocked

## Completion Check

After completing a story:

1. Check if ALL stories have `passes: true`
2. If yes: report COMPLETE to orchestrator
3. If no: end and let orchestrator pick next story
