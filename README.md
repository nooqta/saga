# SAGA - Structured Agile Governance Agent

**"From idea to implementation with full traceability - without the paperwork."**

A Claude Code plugin that extends [Ralf](https://github.com/anis-marrouchi/ralf)'s autonomous execution loop with enterprise-grade requirements management, traceability, and PM tool integration.

## Part of Claude Plugins Marketplace

SAGA is designed for the Claude Code plugin marketplace ecosystem - install it directly into your Claude Code environment to enhance your development workflow.

## What SAGA Inherits from Ralf

- Autonomous story execution loop
- Story-executor, evaluator, and code-reviewer agents
- Lifecycle hooks (on-task-start, on-task-completed, on-task-blocked)
- Progress tracking and metrics
- TDD-driven implementation

## What SAGA Adds

| Feature | Description |
|---------|-------------|
| **SRS Generation** | Generate structured Software Requirements Specifications |
| **Epic → Feature → Story** | Full hierarchy instead of flat stories |
| **Traceability Matrix** | Auto-link requirements → features → stories → code |
| **Gap Detection** | Identify uncovered requirements automatically |
| **UML Diagrams** | Generate Mermaid class, sequence, and flow diagrams |
| **Change Requests** | Log CRs with impact analysis |
| **PM Integration** | Native GitHub/GitLab sync with configurable workflows |

## Quick Start

```bash
# Initialize a new SAGA project
/saga init

# Generate Software Requirements Specification
/saga spec

# Create Epic/Feature/Story hierarchy
/saga plan

# Start autonomous execution
/saga execute

# Check progress
/saga status
```

## Commands

| Command | Purpose | Output |
|---------|---------|--------|
| `/saga init` | Initialize project with PM config | `.saga/project.json` |
| `/saga spec` | Generate SRS document | `.saga/srs.md` |
| `/saga plan` | Create Epic/Feature/Story hierarchy | `.saga/plan.json` |
| `/saga trace` | Show traceability matrix | Terminal + `.saga/trace.md` |
| `/saga diagram [type]` | Generate UML (class/sequence/flow) | `.saga/diagrams/*.mmd` |
| `/saga execute` | Run stories autonomously | Loop with PM sync |
| `/saga status` | Dashboard with coverage/progress | Terminal output |
| `/saga cr "desc"` | Log change request | `.saga/changes/CR-XXX.md` |
| `/saga gaps` | Show uncovered requirements | Terminal output |
| `/saga sync` | Manual PM tool sync | Updates issues/MRs |
| `/saga cancel` | Stop execution loop | Cleanup |

## User Journey

```
/saga init          → "What are we building?" (guided questions)
     ↓
/saga spec          → Generates SRS from conversation
     ↓
/saga plan          → Creates Epics → Features → Stories hierarchy
     ↓
/saga trace         → Shows traceability matrix + gaps
     ↓
/saga diagram       → Generates UML (class, sequence, flow)
     ↓
/saga execute       → Runs stories (inherits Ralf's loop)
     ↓
/saga status        → Progress dashboard
     ↓
/saga cr "change"   → Logs change request, shows impact
```

## PM Tool Integration

SAGA integrates with GitHub and GitLab to automatically:
- Create issues when stories start
- Update labels during execution
- Close issues when stories complete
- Create PRs/MRs for completed work
- Add blocked labels and comments when stuck

### Configuration

During `/saga init`, you configure:
```json
{
  "pm": {
    "platform": "github",
    "project": "org/repo",
    "workflow": {
      "on_story_start": {
        "create_issue": true,
        "add_labels": ["in-progress", "saga"]
      },
      "on_story_complete": {
        "close_issue": true,
        "create_mr": true
      }
    }
  }
}
```

## Data Structure

```
.saga/
├── project.json        # Project metadata + PM config
├── srs.md              # Software Requirements Specification
├── plan.json           # Epics → Features → Stories hierarchy
├── trace.md            # Traceability matrix (auto-generated)
├── diagrams/
│   ├── class.mmd       # Mermaid class diagram
│   ├── sequence.mmd    # Mermaid sequence diagram
│   └── flow.mmd        # Mermaid flowchart
├── changes/
│   ├── CR-001.md       # Change request 1
│   └── CR-002.md       # Change request 2
├── progress.txt        # Execution log
└── hooks/              # Lifecycle hooks
    ├── on-task-start.sh
    ├── on-task-completed.sh
    └── on-task-blocked.sh
```

## Hierarchy Model

```
Epic (E-001)
  └── Feature (F-001)
        └── User Story (US-001)
              └── Acceptance Criteria
                    └── Links to: FR-XXX (from SRS)
```

## Traceability Matrix

Auto-generated mapping of requirements to implementation:

```
| Requirement | Feature | Story | Status | Test |
|-------------|---------|-------|--------|------|
| FR-001      | F-001   | US-001| ✅ Done | ✅   |
| FR-002      | F-001   | US-002| 🔄 WIP | ❌   |
| FR-003      | F-002   | -     | ⚠️ Gap | -    |
```

## Comparison with Ralf

| Aspect | Ralf | SAGA |
|--------|------|------|
| Starting point | PRD (informal) | SRS (structured) |
| Hierarchy | Flat stories | Epic → Feature → Story |
| Traceability | None | FR → Story → Code |
| Diagrams | None | Mermaid UML |
| Change mgmt | None | CR workflow |
| Gap detection | None | Built-in |
| PM integration | Manual hooks | Built-in GitHub/GitLab sync |
| Workflow | Hardcoded | Configurable per-project |

## Installation

```bash
# Coming soon to Claude Plugins Marketplace
claude plugin install saga
```

Or manually clone to your plugins directory:
```bash
cd ~/.claude/plugins/marketplaces/local/
git clone https://github.com/nooqta/saga.git
```

## Requirements

- Claude Code CLI
- `jq` for JSON processing (used by scripts)
- GitHub CLI (`gh`) or GitLab CLI (`glab`) for PM integration (optional)

## Skills

SAGA includes specialized skills for expert guidance:

- **pm-workflow**: GitHub/GitLab integration patterns
- **srs-generation**: SRS document best practices
- **diagram-generation**: UML/Mermaid patterns
- **story-execution**: Implementation guidance
- **rlm-processing**: Large codebase analysis

## Lifecycle Hooks

Customize SAGA behavior with hooks in `.saga/hooks/`:

- `on-task-start.sh` - Before story execution
- `on-task-completed.sh` - After story passes
- `on-task-blocked.sh` - When max retries exceeded

Hooks receive JSON context via stdin and can perform custom actions (notifications, metrics, etc.).

## Contributing

Contributions are welcome! Please see our contributing guidelines.

## License

MIT

## Credits

- Built on top of [Ralf](https://github.com/anis-marrouchi/ralf) by Anis Marrouchi
- Developed by [Nooqta](https://github.com/nooqta)
