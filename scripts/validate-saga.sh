#!/bin/bash

# SAGA Validation Script
# Validates all SAGA artifacts for correctness
#
# Usage: validate-saga.sh [--verbose]

set -euo pipefail

VERBOSE=false
if [[ "${1:-}" == "--verbose" ]]; then
  VERBOSE=true
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

log_pass() { echo -e "${GREEN}✓${NC} $1"; }
log_fail() { echo -e "${RED}✗${NC} $1"; ((++ERRORS)) || true; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; ((++WARNINGS)) || true; }
log_info() { [[ "$VERBOSE" == "true" ]] && echo "  $1" || true; }

echo "SAGA Artifact Validation"
echo "========================"
echo ""

# Check if .saga exists
if [[ ! -d ".saga" ]]; then
  log_fail ".saga directory not found. Run /saga init first."
  exit 1
fi
log_pass ".saga directory exists"

# Validate project.json
echo ""
echo "Validating project.json..."
if [[ -f ".saga/project.json" ]]; then
  log_pass "project.json exists"

  # Check JSON validity
  if jq empty .saga/project.json 2>/dev/null; then
    log_pass "project.json is valid JSON"

    # Check required fields
    NAME=$(jq -r '.name // empty' .saga/project.json)
    if [[ -n "$NAME" ]]; then
      log_pass "project.json has 'name' field: $NAME"
    else
      log_fail "project.json missing 'name' field"
    fi

    CREATED=$(jq -r '.createdAt // empty' .saga/project.json)
    if [[ -n "$CREATED" ]]; then
      log_pass "project.json has 'createdAt' field"
    else
      log_warn "project.json missing 'createdAt' field"
    fi

    PM_PLATFORM=$(jq -r '.pm.platform // empty' .saga/project.json)
    if [[ -n "$PM_PLATFORM" ]]; then
      log_pass "project.json has PM platform: $PM_PLATFORM"
    else
      log_warn "project.json missing PM configuration"
    fi

    SETTINGS=$(jq -r '.settings // empty' .saga/project.json)
    if [[ -n "$SETTINGS" && "$SETTINGS" != "null" ]]; then
      log_pass "project.json has settings"
    else
      log_warn "project.json missing settings"
    fi
  else
    log_fail "project.json is not valid JSON"
  fi
else
  log_fail "project.json not found"
fi

# Validate srs.md
echo ""
echo "Validating srs.md..."
if [[ -f ".saga/srs.md" ]]; then
  log_pass "srs.md exists"

  # Check for functional requirements
  FR_COUNT=$(grep -c "^### FR-[0-9]" .saga/srs.md 2>/dev/null || true)
  FR_COUNT=$((FR_COUNT + 0))  # Ensure it's a number
  if [[ "$FR_COUNT" -gt 0 ]]; then
    log_pass "srs.md has $FR_COUNT functional requirements"
  else
    log_warn "srs.md has no functional requirements (FR-XXX)"
  fi

  # Check for non-functional requirements
  NFR_COUNT=$(grep -c "^#### NFR-[0-9]" .saga/srs.md 2>/dev/null || true)
  NFR_COUNT=$((NFR_COUNT + 0))  # Ensure it's a number
  if [[ "$NFR_COUNT" -gt 0 ]]; then
    log_pass "srs.md has $NFR_COUNT non-functional requirements"
  else
    log_warn "srs.md has no non-functional requirements (NFR-XXX)"
  fi

  # Check for required sections
  if grep -q "## 1. Introduction" .saga/srs.md; then
    log_pass "srs.md has Introduction section"
  else
    log_warn "srs.md missing Introduction section"
  fi

  if grep -q "## 3. Functional Requirements" .saga/srs.md; then
    log_pass "srs.md has Functional Requirements section"
  else
    log_warn "srs.md missing Functional Requirements section"
  fi
else
  log_warn "srs.md not found (run /saga spec)"
fi

# Validate plan.json
echo ""
echo "Validating plan.json..."
if [[ -f ".saga/plan.json" ]]; then
  log_pass "plan.json exists"

  # Check JSON validity
  if jq empty .saga/plan.json 2>/dev/null; then
    log_pass "plan.json is valid JSON"

    # Check structure
    EPIC_COUNT=$(jq '.epics | length' .saga/plan.json 2>/dev/null || echo "0")
    if [[ "$EPIC_COUNT" -gt 0 ]]; then
      log_pass "plan.json has $EPIC_COUNT epics"
    else
      log_fail "plan.json has no epics"
    fi

    STORY_COUNT=$(jq '.userStories | length' .saga/plan.json 2>/dev/null || echo "0")
    if [[ "$STORY_COUNT" -gt 0 ]]; then
      log_pass "plan.json has $STORY_COUNT user stories"
    else
      log_fail "plan.json has no user stories"
    fi

    # Check story structure
    STORIES_WITH_AC=$(jq '[.userStories[] | select(.acceptanceCriteria | length > 0)] | length' .saga/plan.json 2>/dev/null || echo "0")
    if [[ "$STORIES_WITH_AC" == "$STORY_COUNT" ]]; then
      log_pass "All stories have acceptance criteria"
    else
      log_warn "Only $STORIES_WITH_AC/$STORY_COUNT stories have acceptance criteria"
    fi

    STORIES_WITH_REQS=$(jq '[.userStories[] | select(.linkedRequirements | length > 0)] | length' .saga/plan.json 2>/dev/null || echo "0")
    if [[ "$STORIES_WITH_REQS" == "$STORY_COUNT" ]]; then
      log_pass "All stories have linked requirements"
    else
      log_warn "Only $STORIES_WITH_REQS/$STORY_COUNT stories have linked requirements"
    fi

    # Check for duplicate IDs
    UNIQUE_IDS=$(jq '[.userStories[].id] | unique | length' .saga/plan.json 2>/dev/null || echo "0")
    if [[ "$UNIQUE_IDS" == "$STORY_COUNT" ]]; then
      log_pass "All story IDs are unique"
    else
      log_fail "Duplicate story IDs detected"
    fi

    # Check settings
    TDD=$(jq -r '.settings.tddRequired // empty' .saga/plan.json)
    if [[ -n "$TDD" ]]; then
      log_pass "plan.json has TDD setting: $TDD"
    fi
  else
    log_fail "plan.json is not valid JSON"
  fi
else
  log_warn "plan.json not found (run /saga plan)"
fi

# Validate trace.md
echo ""
echo "Validating trace.md..."
if [[ -f ".saga/trace.md" ]]; then
  log_pass "trace.md exists"

  # Check for table structure
  if grep -q "| Requirement | " .saga/trace.md; then
    log_pass "trace.md has requirement-to-story matrix"
  else
    log_warn "trace.md missing requirement-to-story matrix"
  fi

  # Check coverage summary
  if grep -q "## Coverage Summary" .saga/trace.md; then
    log_pass "trace.md has coverage summary"
  else
    log_warn "trace.md missing coverage summary"
  fi
else
  log_warn "trace.md not found (generated with /saga plan or /saga trace)"
fi

# Validate hooks
echo ""
echo "Validating hooks..."
if [[ -d ".saga/hooks" ]]; then
  log_pass ".saga/hooks directory exists"

  for hook in on-task-start on-task-completed on-task-blocked; do
    if [[ -f ".saga/hooks/${hook}.js" ]]; then
      log_pass "${hook}.js exists"
      if [[ -x ".saga/hooks/${hook}.js" ]]; then
        log_pass "${hook}.js is executable"
      else
        log_warn "${hook}.js is not executable"
      fi
    else
      log_warn "${hook}.js not found"
    fi
  done

  if [[ -f ".saga/hooks/knowledge.js" ]]; then
    log_pass "knowledge.js utility exists"
  else
    log_warn "knowledge.js utility not found"
  fi
else
  log_warn ".saga/hooks directory not found (run /saga init-hooks)"
fi

# Validate knowledge directory
echo ""
echo "Validating knowledge..."
if [[ -d ".saga/knowledge" ]]; then
  log_pass ".saga/knowledge directory exists"

  # Check for knowledge files
  KNOWLEDGE_FILES=$(find .saga/knowledge -name "*.jsonl" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$KNOWLEDGE_FILES" -gt 0 ]]; then
    log_pass "Found $KNOWLEDGE_FILES knowledge files"

    # Validate JSONL format
    for kfile in .saga/knowledge/*.jsonl; do
      if [[ -f "$kfile" ]]; then
        INVALID_LINES=$(while read -r line; do
          [[ -z "$line" ]] && continue
          echo "$line" | jq empty 2>/dev/null || echo "invalid"
        done < "$kfile" | grep -c "invalid" || echo "0")

        if [[ "$INVALID_LINES" -eq 0 ]]; then
          log_pass "$(basename "$kfile") has valid JSONL format"
        else
          log_warn "$(basename "$kfile") has $INVALID_LINES invalid lines"
        fi
      fi
    done
  else
    log_info "No knowledge files yet (populated during execution)"
  fi
else
  log_warn ".saga/knowledge directory not found"
fi

# Summary
echo ""
echo "========================"
echo "Validation Summary"
echo "========================"
echo -e "Errors:   ${RED}$ERRORS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"

if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
  echo -e "${GREEN}All validations passed!${NC}"
  exit 0
elif [[ $ERRORS -eq 0 ]]; then
  echo -e "${YELLOW}Passed with warnings${NC}"
  exit 0
else
  echo -e "${RED}Validation failed${NC}"
  exit 1
fi
