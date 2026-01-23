#!/bin/bash

# SAGA Setup Script
# Initializes state for SAGA loop execution

set -euo pipefail

# Default values
PLAN_PATH=".saga/plan.json"
MAX_ITERATIONS=0
COMPLETION_PROMISE="COMPLETE"
EXECUTION_MODE="sequential"

# Help message
show_help() {
  cat << 'HELP_EOF'
SAGA - Structured Agile Governance Agent

USAGE:
  /saga execute [PLAN_PATH] [OPTIONS]

ARGUMENTS:
  PLAN_PATH    Path to plan.json file (default: .saga/plan.json)

OPTIONS:
  --max-iterations <n>           Maximum iterations before auto-stop (default: unlimited)
  --mode <mode>                  Execution mode: sequential|parallel|full-parallel (default: sequential)
  --completion-promise '<text>'  Custom completion phrase (default: COMPLETE)
  -h, --help                     Show this help message

DESCRIPTION:
  Starts SAGA autonomous execution. SAGA will:
  1. Read the .saga/plan.json file
  2. Pick the highest priority story with passes: false
  3. Spawn story-executor agent to implement the story
  4. Update .saga/plan.json and .saga/progress.txt
  5. Sync with PM tool (GitHub/GitLab) if configured
  6. Loop until all stories pass or max iterations reached

ARTIFACTS:
  All SAGA artifacts are stored in .saga/:
  - .saga/project.json   # Project metadata + PM config
  - .saga/srs.md         # Software Requirements Specification
  - .saga/plan.json      # Epic/Feature/Story hierarchy
  - .saga/trace.md       # Traceability matrix
  - .saga/progress.txt   # Progress log and patterns
  - .saga/state.json     # Loop state (gitignored)
  - .saga/diagrams/      # UML diagrams
  - .saga/changes/       # Change requests
  - .saga/hooks/         # Lifecycle hooks

COMPLETION:
  The loop ends when:
  - All stories in plan.json have passes: true (auto-complete)
  - Claude outputs <promise>COMPLETE</promise> (explicit complete)
  - Max iterations reached (if set)

EXAMPLES:
  /saga execute                              # Use default .saga/plan.json
  /saga execute .saga/plan.json              # Explicit path
  /saga execute --max-iterations 20          # Limit iterations
  /saga execute --mode parallel              # Parallel execution

MONITORING:
  /saga status     Show current progress
  /saga cancel     Stop the loop

WORKFLOW:
  1. /saga init            # Initialize project + PM config
  2. /saga spec            # Generate SRS
  3. /saga plan            # Create Epic/Feature/Story hierarchy
  4. /saga trace           # View traceability matrix
  5. /saga execute         # Start execution
  6. /saga status          # Check progress
HELP_EOF
  exit 0
}

# Parse arguments
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      ;;
    --max-iterations)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --max-iterations requires a positive integer" >&2
        exit 1
      fi
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --mode)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --mode requires an argument (sequential|parallel|full-parallel)" >&2
        exit 1
      fi
      EXECUTION_MODE="$2"
      shift 2
      ;;
    --completion-promise)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --completion-promise requires a text argument" >&2
        exit 1
      fi
      COMPLETION_PROMISE="$2"
      shift 2
      ;;
    -*)
      echo "Error: Unknown option: $1" >&2
      echo "Run '/saga execute --help' for usage" >&2
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

# First positional arg is plan path
if [[ ${#POSITIONAL_ARGS[@]} -gt 0 ]]; then
  PLAN_PATH="${POSITIONAL_ARGS[0]}"
fi

# Create .saga directory if it doesn't exist
mkdir -p .saga

# Validate plan file exists
if [[ ! -f "$PLAN_PATH" ]]; then
  echo "Error: Plan file not found: $PLAN_PATH" >&2
  echo "" >&2
  echo "Create a plan first:" >&2
  echo "  1. /saga init        # Initialize project" >&2
  echo "  2. /saga spec        # Generate SRS" >&2
  echo "  3. /saga plan        # Create plan.json" >&2
  echo "" >&2
  echo "Or specify a different path:" >&2
  echo "  /saga execute path/to/plan.json" >&2
  exit 1
fi

# Validate plan is valid JSON
if ! jq empty "$PLAN_PATH" 2>/dev/null; then
  echo "Error: Invalid JSON in $PLAN_PATH" >&2
  exit 1
fi

# Check for existing loop
if [[ -f ".saga/state.json" ]]; then
  echo "Warning: SAGA loop already active!" >&2
  echo "Run /saga cancel first to stop the existing loop" >&2
  exit 1
fi

# Read plan metadata
PROJECT=$(jq -r '.project // "Unknown"' "$PLAN_PATH")
BRANCH=$(jq -r '.branchName // "saga/feature"' "$PLAN_PATH")
DESCRIPTION=$(jq -r '.description // ""' "$PLAN_PATH")
# Support both flat userStories and nested features[].stories structures
TOTAL_STORIES=$(jq '
  if .userStories then
    .userStories | length
  elif .features then
    [.features[].stories // [] | .[]] | length
  else
    0
  end
' "$PLAN_PATH")
PASSING_STORIES=$(jq '
  if .userStories then
    [.userStories[] | select(.passes == true)] | length
  elif .features then
    [.features[].stories // [] | .[] | select(.passes == true or .status == "completed" or .status == "done")] | length
  else
    0
  end
' "$PLAN_PATH")
FAILING_STORIES=$((TOTAL_STORIES - PASSING_STORIES))

# Read PM config if exists
PM_PLATFORM="none"
if [[ -f ".saga/project.json" ]]; then
  PM_PLATFORM=$(jq -r '.pm.platform // "none"' ".saga/project.json")
fi

# Read settings from plan.json or config.json
if [[ -f ".saga/config.json" ]]; then
  CONFIG_MODE=$(jq -r '.settings.executionMode // "sequential"' ".saga/config.json")
  if [[ "$EXECUTION_MODE" == "sequential" ]]; then
    EXECUTION_MODE="$CONFIG_MODE"
  fi
fi

# Build the prompt for the loop
PROMPT="You are SAGA, an autonomous coding agent orchestrator with traceability. Execute the next incomplete story from $PLAN_PATH by SPAWNING the story-executor agent. Follow the SAGA workflow: read plan, check branch, spawn agent, track metrics, update status, fire hooks, sync PM tool. Work on ONE story per iteration."

# Create state file (JSON format)
cat > .saga/state.json << EOF
{
  "active": true,
  "iteration": 1,
  "maxIterations": $MAX_ITERATIONS,
  "executionMode": "$EXECUTION_MODE",
  "completionPromise": "$COMPLETION_PROMISE",
  "planPath": "$PLAN_PATH",
  "project": "$PROJECT",
  "branch": "$BRANCH",
  "pmPlatform": "$PM_PLATFORM",
  "startedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "prompt": $(echo "$PROMPT" | jq -Rs .)
}
EOF

# Create .gitignore if it doesn't exist
if [[ ! -f ".saga/.gitignore" ]]; then
  cat > .saga/.gitignore << 'GITIGNORE_EOF'
# SAGA runtime artifacts (should not be committed)
state.json
metrics.jsonl

# Keep these tracked:
# project.json
# srs.md
# plan.json
# trace.md
# progress.txt
# config.json
# hooks/
# diagrams/
# changes/
GITIGNORE_EOF
  echo "Created .saga/.gitignore"
fi

# Output setup message
cat << EOF
SAGA Autonomous Loop Activated

Project: $PROJECT
Branch: $BRANCH
Plan: $PLAN_PATH
Description: $DESCRIPTION
PM Integration: $PM_PLATFORM

Stories: $PASSING_STORIES/$TOTAL_STORIES passing ($FAILING_STORIES remaining)

Iteration: 1
Max iterations: $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)
Mode: $EXECUTION_MODE
Completion: Auto (all stories pass) OR <promise>$COMPLETION_PROMISE</promise>

The stop hook is now active. Each iteration will:
1. Pick the next incomplete story
2. Spawn story-executor agent
3. Track metrics and update .saga/plan.json
4. Fire lifecycle hooks
5. Sync with PM tool (if configured)
6. Continue until complete

Commands:
  /saga status   - Check progress
  /saga cancel   - Stop the loop

Starting execution...
EOF

# Create or update progress.txt if it doesn't exist
if [[ ! -f ".saga/progress.txt" ]]; then
  cat > .saga/progress.txt << EOF
# SAGA Progress Log

## Codebase Patterns
<!-- Add reusable patterns discovered during development -->

---

EOF
  echo ""
  echo "Created .saga/progress.txt for tracking"
fi

echo ""
echo "---"
echo ""
echo "$PROMPT"
