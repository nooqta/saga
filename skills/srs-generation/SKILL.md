---
description: "Expert guidance for generating Software Requirements Specifications. Use when creating SRS documents."
capabilities: ["requirements-writing", "IEEE-830-standard", "acceptance-criteria", "traceability", "prioritization"]
---

# SRS Generation Skill

Expert guidance for creating comprehensive Software Requirements Specifications.

## When to Use

- During `/saga spec` command
- When user asks about requirements
- When refining existing SRS

## SRS Structure

A complete SRS follows IEEE 830 standard with adaptations for agile:

### 1. Introduction
- **Purpose**: Why this document exists
- **Scope**: What the system will and won't do
- **Definitions**: Technical terms and acronyms
- **References**: Related documents
- **Overview**: Document structure guide

### 2. Overall Description
- **Product Perspective**: System context and interfaces
- **Product Functions**: High-level capability summary
- **User Characteristics**: Target user profiles
- **Constraints**: Technical and business limitations
- **Assumptions**: What we're assuming to be true

### 3. Functional Requirements (FR)
Each requirement should include:
- **ID**: FR-XXX format
- **Title**: Short descriptive name
- **Priority**: High/Medium/Low
- **Description**: Detailed explanation
- **Rationale**: Why this requirement exists
- **Acceptance Criteria**: How to verify it's met
- **Dependencies**: Other requirements this depends on

### 4. Non-Functional Requirements (NFR)
Categories:
- **Performance**: Response times, throughput, capacity
- **Security**: Authentication, authorization, data protection
- **Usability**: Accessibility, ease of use, learnability
- **Reliability**: Uptime, error handling, recovery
- **Scalability**: Growth capacity
- **Maintainability**: Code quality, documentation

### 5. Interface Requirements
- **User Interfaces**: UI/UX requirements
- **Hardware Interfaces**: Device requirements
- **Software Interfaces**: API and integration requirements
- **Communication Interfaces**: Protocols, data formats

### 6. System Features
Group related requirements into features for easier tracking.

## Writing Good Requirements

### SMART Criteria
- **Specific**: Clear and unambiguous
- **Measurable**: Can be verified
- **Achievable**: Technically feasible
- **Relevant**: Supports project goals
- **Traceable**: Can be linked to stories

### Language Guidelines

**DO use:**
- "The system shall..."
- "Users must be able to..."
- "The application will..."

**DON'T use:**
- "The system should..." (ambiguous)
- "It would be nice if..." (not a requirement)
- "The system might..." (uncertain)

### Acceptance Criteria Format

Use Given/When/Then or checklist format:

**Given/When/Then:**
```
Given a registered user
When they enter valid credentials
Then they are logged in and redirected to dashboard
```

**Checklist:**
```
- [ ] User can enter email and password
- [ ] Invalid credentials show error message
- [ ] Successful login redirects to dashboard
- [ ] Session persists for 24 hours
```

## Requirement Prioritization

### MoSCoW Method
- **Must Have**: Critical for MVP
- **Should Have**: Important but not critical
- **Could Have**: Nice to have
- **Won't Have**: Out of scope for now

### Priority Matrix

| Priority | Criteria |
|----------|----------|
| High | Core functionality, security, compliance |
| Medium | Important features, user experience |
| Low | Enhancements, optimizations |

## Traceability Preparation

Write requirements with traceability in mind:

1. **Unique IDs**: FR-001, NFR-001 format
2. **Clear scope**: One requirement, one concern
3. **Testable**: Each has acceptance criteria
4. **Atomic**: Can map to single story or small group

## Common Patterns

### Authentication Requirements
```
FR-001: User Registration
FR-002: User Login
FR-003: Password Reset
FR-004: Session Management
NFR-001: Password Complexity (min 8 chars, special char)
NFR-002: Session Timeout (30 min inactivity)
```

### CRUD Requirements
```
FR-010: Create [Entity]
FR-011: Read [Entity]
FR-012: Update [Entity]
FR-013: Delete [Entity]
FR-014: List [Entities] with pagination
FR-015: Search [Entities]
```

### API Requirements
```
FR-020: RESTful API endpoints
FR-021: API authentication (JWT)
FR-022: Rate limiting
NFR-010: API response time < 200ms
NFR-011: API documentation (OpenAPI)
```

## Validation Checklist

Before finalizing SRS:

- [ ] All requirements have unique IDs
- [ ] No duplicate requirements
- [ ] Each requirement is testable
- [ ] Priorities are assigned
- [ ] Dependencies are noted
- [ ] Acceptance criteria are specific
- [ ] No implementation details (HOW, not WHAT)
- [ ] Stakeholder review completed

## Iterative Refinement

SRS is a living document:

1. **Initial Draft**: Capture main requirements
2. **Review**: Stakeholder feedback
3. **Refine**: Add details, clarify ambiguity
4. **Approve**: Baseline the version
5. **Update**: Via change requests (CR)

Use `/saga cr` to log changes after baseline.
