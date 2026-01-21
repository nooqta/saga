---
description: "Initialize SAGA lifecycle hooks with compounding knowledge and PM integration"
argument-hint: "[--force]"
---

# Initialize SAGA Hooks

Create the `.saga/hooks/` directory with JavaScript hook scripts that use the Claude Agent SDK for intelligent lifecycle event handling, **compounding knowledge**, and **PM tool integration**.

## The Job

1. Create `.saga/` directory structure if it doesn't exist
2. Create `.saga/knowledge/` for compounding knowledge storage
3. Generate `.saga/.gitignore` to exclude runtime artifacts
4. Generate boilerplate for each lifecycle hook (JavaScript using Claude Agent SDK)
5. Create shared `knowledge.js` utility module
6. Create shared `pm-integration.js` utility module
7. Create `package.json` with SDK dependency
8. Install dependencies
9. Make scripts executable
10. Skip existing files unless `--force` is passed

## Compounding Knowledge System

The hooks implement a knowledge capture system that compounds learnings across task executions:

| Hook | Captures | Future Benefit |
|------|----------|----------------|
| `on-task-completed` | Patterns used, decisions made, files touched | Similar tasks get context from past solutions |
| `on-task-blocked` | Error types, root causes, resolutions | Proactive warnings when similar patterns detected |
| `on-task-start` | Queries knowledge base | Injects relevant learnings into executor context |

## PM Integration

The hooks also handle PM tool integration based on `.saga/project.json` workflow configuration:

| Hook | PM Action |
|------|-----------|
| `on-task-start` | Create issue, add labels |
| `on-task-completed` | Close issue, create MR, update labels |
| `on-task-blocked` | Add blocked label, comment with errors |

## Execute

```bash
mkdir -p .saga/hooks .saga/knowledge
```

## Create .gitignore

Create `.saga/.gitignore` to exclude runtime state:

```gitignore
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
# knowledge/
# diagrams/
# changes/
```

## Hook Files to Create

Create the following files:

### 1. `.saga/hooks/package.json`

```json
{
  "name": "saga-hooks",
  "type": "module",
  "private": true,
  "dependencies": {
    "@anthropic-ai/claude-agent-sdk": "^0.1.0"
  }
}
```

### 2. `.saga/hooks/knowledge.js`

Shared utility module for knowledge operations:

```javascript
#!/usr/bin/env node
/**
 * SAGA Knowledge System
 * Captures and retrieves learnings across task executions
 */

import { readFile, appendFile, mkdir } from "fs/promises";
import { existsSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const KNOWLEDGE_DIR = join(__dirname, "..", "knowledge");

// Ensure knowledge directory exists
async function ensureKnowledgeDir() {
  if (!existsSync(KNOWLEDGE_DIR)) {
    await mkdir(KNOWLEDGE_DIR, { recursive: true });
  }
}

/**
 * Append an entry to a JSONL knowledge file
 */
export async function appendKnowledge(filename, entry) {
  await ensureKnowledgeDir();
  const filepath = join(KNOWLEDGE_DIR, filename);
  const line = JSON.stringify({
    ...entry,
    timestamp: new Date().toISOString(),
  }) + "\n";
  await appendFile(filepath, line);
}

/**
 * Read all entries from a JSONL knowledge file
 */
export async function readKnowledge(filename) {
  const filepath = join(KNOWLEDGE_DIR, filename);
  if (!existsSync(filepath)) {
    return [];
  }
  const content = await readFile(filepath, "utf-8");
  return content
    .split("\n")
    .filter((line) => line.trim())
    .map((line) => JSON.parse(line));
}

/**
 * Find relevant knowledge entries based on keywords
 */
export async function findRelevantKnowledge(keywords, options = {}) {
  const { maxResults = 5, files = ["patterns.jsonl", "blockers.jsonl", "decisions.jsonl"] } = options;

  const allEntries = [];

  for (const file of files) {
    const entries = await readKnowledge(file);
    allEntries.push(...entries.map((e) => ({ ...e, source: file })));
  }

  // Score entries by keyword relevance
  const scored = allEntries.map((entry) => {
    const text = JSON.stringify(entry).toLowerCase();
    const score = keywords.reduce((acc, kw) => {
      return acc + (text.includes(kw.toLowerCase()) ? 1 : 0);
    }, 0);
    return { entry, score };
  });

  return scored
    .filter((s) => s.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, maxResults)
    .map((s) => s.entry);
}

/**
 * Extract keywords from task context for knowledge matching
 */
export function extractKeywords(context) {
  const keywords = [];

  // From title
  if (context.title) {
    keywords.push(...context.title.toLowerCase().split(/\s+/).filter((w) => w.length > 3));
  }

  // From files changed
  if (context.filesChanged) {
    context.filesChanged.forEach((file) => {
      const parts = file.split("/");
      parts.forEach((part) => {
        const stem = part.replace(/\.[^.]+$/, "");
        if (stem.length > 2) keywords.push(stem.toLowerCase());
      });
    });
  }

  // From acceptance criteria
  if (context.acceptanceCriteria) {
    context.acceptanceCriteria.forEach((ac) => {
      keywords.push(...ac.toLowerCase().split(/\s+/).filter((w) => w.length > 3));
    });
  }

  // From linked requirements
  if (context.linkedRequirements) {
    keywords.push(...context.linkedRequirements.map((r) => r.toLowerCase()));
  }

  // Deduplicate
  return [...new Set(keywords)];
}
```

### 3. `.saga/hooks/pm-integration.js`

Shared utility module for PM tool integration:

```javascript
#!/usr/bin/env node
/**
 * SAGA PM Integration
 * Handles GitHub/GitLab operations based on project.json workflow config
 */

import { readFile, writeFile } from "fs/promises";
import { existsSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";
import { execSync } from "child_process";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PROJECT_CONFIG = join(__dirname, "..", "project.json");
const PM_LINKS = join(__dirname, "..", "pm-links.json");

/**
 * Load project configuration
 */
export async function loadProjectConfig() {
  if (!existsSync(PROJECT_CONFIG)) {
    return null;
  }
  const content = await readFile(PROJECT_CONFIG, "utf-8");
  return JSON.parse(content);
}

/**
 * Load PM links mapping
 */
export async function loadPmLinks() {
  if (!existsSync(PM_LINKS)) {
    return { stories: {}, changeRequests: {} };
  }
  const content = await readFile(PM_LINKS, "utf-8");
  return JSON.parse(content);
}

/**
 * Save PM links mapping
 */
export async function savePmLinks(links) {
  await writeFile(PM_LINKS, JSON.stringify(links, null, 2));
}

/**
 * Execute GitHub CLI command
 */
function ghCommand(args) {
  try {
    const result = execSync(`gh ${args}`, { encoding: "utf-8", stdio: ["pipe", "pipe", "pipe"] });
    return { success: true, output: result.trim() };
  } catch (err) {
    return { success: false, error: err.message };
  }
}

/**
 * Execute GitLab CLI command
 */
function glabCommand(args) {
  try {
    const result = execSync(`glab ${args}`, { encoding: "utf-8", stdio: ["pipe", "pipe", "pipe"] });
    return { success: true, output: result.trim() };
  } catch (err) {
    return { success: false, error: err.message };
  }
}

/**
 * Create or update issue for story
 */
export async function handleStoryStart(context, config) {
  const { pm } = config;
  if (!pm || pm.platform === "none") return { skipped: true };

  const workflow = pm.workflow?.on_story_start || {};
  if (!workflow.create_issue && !workflow.add_labels) {
    return { skipped: true, reason: "No actions configured" };
  }

  const links = await loadPmLinks();
  const existingIssue = links.stories[context.storyId];

  if (pm.platform === "github") {
    const [owner, repo] = pm.project.split("/");

    if (existingIssue) {
      // Update existing issue
      if (workflow.add_labels) {
        const labels = workflow.add_labels.join(",");
        const result = ghCommand(`issue edit ${existingIssue.issueNumber} --add-label "${labels}" -R ${pm.project}`);
        return { updated: true, issueNumber: existingIssue.issueNumber, result };
      }
      return { skipped: true, reason: "Issue exists" };
    }

    if (workflow.create_issue) {
      const labels = workflow.add_labels ? `--label "${workflow.add_labels.join(",")}"` : "";
      const body = `## Story Details
**ID:** ${context.storyId}
**Branch:** \`${context.branch}\`
**Requirements:** ${context.linkedRequirements?.join(", ") || "N/A"}

## Description
${context.description || context.title}

## Acceptance Criteria
${context.acceptanceCriteria?.map((ac) => `- [ ] ${ac}`).join("\n") || "- [ ] TBD"}

---
*Managed by SAGA*`;

      const result = ghCommand(`issue create --title "[${context.storyId}] ${context.title}" --body "${body.replace(/"/g, '\\"')}" ${labels} -R ${pm.project}`);

      if (result.success) {
        const issueUrl = result.output;
        const issueNumber = issueUrl.split("/").pop();
        links.stories[context.storyId] = { issueNumber, issueUrl };
        await savePmLinks(links);
        return { created: true, issueNumber, issueUrl };
      }
      return { error: result.error };
    }
  }

  if (pm.platform === "gitlab") {
    // Similar implementation for GitLab using glab CLI
    // ...
  }

  return { skipped: true };
}

/**
 * Close issue and optionally create MR
 */
export async function handleStoryComplete(context, config) {
  const { pm } = config;
  if (!pm || pm.platform === "none") return { skipped: true };

  const workflow = pm.workflow?.on_story_complete || {};
  const links = await loadPmLinks();
  const existingIssue = links.stories[context.storyId];

  if (!existingIssue) {
    return { skipped: true, reason: "No linked issue" };
  }

  const results = {};

  if (pm.platform === "github") {
    // Close issue
    if (workflow.close_issue) {
      const closeResult = ghCommand(`issue close ${existingIssue.issueNumber} -R ${pm.project}`);
      results.closed = closeResult.success;
    }

    // Update labels
    if (workflow.add_labels) {
      const labels = workflow.add_labels.join(",");
      ghCommand(`issue edit ${existingIssue.issueNumber} --add-label "${labels}" --remove-label "in-progress" -R ${pm.project}`);
    }

    // Add completion comment
    const comment = `## Completed ✅

**Commit:** \`${context.commitHash}\`
**Duration:** ${Math.round((context.metrics?.durationMs || 0) / 60000)} minutes
**Files Changed:** ${context.filesChanged?.length || 0}

---
*Completed by SAGA*`;

    ghCommand(`issue comment ${existingIssue.issueNumber} --body "${comment.replace(/"/g, '\\"')}" -R ${pm.project}`);

    // Create PR if configured
    if (workflow.create_mr) {
      const prResult = ghCommand(`pr create --title "[${context.storyId}] ${context.title}" --body "Closes #${existingIssue.issueNumber}" --head ${context.branch} -R ${pm.project}`);
      if (prResult.success) {
        results.prUrl = prResult.output;
      }
    }
  }

  return results;
}

/**
 * Add blocked label and comment
 */
export async function handleStoryBlocked(context, config) {
  const { pm } = config;
  if (!pm || pm.platform === "none") return { skipped: true };

  const workflow = pm.workflow?.on_story_blocked || {};
  const links = await loadPmLinks();
  const existingIssue = links.stories[context.storyId];

  if (!existingIssue) {
    return { skipped: true, reason: "No linked issue" };
  }

  if (pm.platform === "github") {
    // Update labels
    if (workflow.add_labels) {
      const labels = workflow.add_labels.join(",");
      ghCommand(`issue edit ${existingIssue.issueNumber} --add-label "${labels}" --remove-label "in-progress" -R ${pm.project}`);
    }

    // Add blocked comment
    if (workflow.add_comment) {
      const comment = `## Blocked 🚫

**Reason:** ${context.blockedReason}
**Attempts:** ${context.retryCount}

### Errors
${context.errors?.slice(0, 5).map((e) => `- ${e}`).join("\n") || "No details"}

---
*Manual intervention required*`;

      ghCommand(`issue comment ${existingIssue.issueNumber} --body "${comment.replace(/"/g, '\\"')}" -R ${pm.project}`);
    }
  }

  return { updated: true };
}
```

### 4. `.saga/hooks/on-task-start.js`

```javascript
#!/usr/bin/env node
/**
 * SAGA Lifecycle Hook: on_task_start
 * Triggered: Before story-executor spawns
 *
 * Features:
 * - Queries compounding knowledge for relevant context
 * - Creates/updates PM issue based on workflow config
 */

import { query } from "@anthropic-ai/claude-agent-sdk";
import { findRelevantKnowledge, extractKeywords } from "./knowledge.js";
import { loadProjectConfig, handleStoryStart } from "./pm-integration.js";

async function askClaude(prompt) {
  let result = "";
  for await (const message of query({
    prompt,
    options: { allowedTools: [], maxTurns: 1 },
  })) {
    if (message.type === "result" && message.subtype === "success") {
      result = message.result;
    }
  }
  return result;
}

async function main() {
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const context = JSON.parse(Buffer.concat(chunks).toString());

  const { storyId, title, branch, iteration, linkedRequirements } = context;

  console.error(`[on_task_start] ${storyId}: ${title}`);
  console.error(`  Branch: ${branch}`);
  console.error(`  Iteration: ${iteration}`);
  console.error(`  Requirements: ${linkedRequirements?.join(", ") || "N/A"}`);

  // PM Integration
  const config = await loadProjectConfig();
  if (config?.pm?.platform !== "none") {
    console.error(`  PM Integration: ${config.pm.platform}`);
    const pmResult = await handleStoryStart(context, config);
    if (pmResult.created) {
      console.error(`    Created issue: ${pmResult.issueUrl}`);
    } else if (pmResult.updated) {
      console.error(`    Updated issue #${pmResult.issueNumber}`);
    } else if (pmResult.error) {
      console.error(`    PM Error: ${pmResult.error}`);
    }
  }

  // Query compounding knowledge
  const keywords = extractKeywords(context);
  const relevantKnowledge = await findRelevantKnowledge(keywords);

  let additionalContext = null;

  if (relevantKnowledge.length > 0) {
    console.error(`  Found ${relevantKnowledge.length} relevant knowledge entries`);

    try {
      const knowledgeSummary = relevantKnowledge
        .map((k) => `- [${k.source}] ${k.summary || k.pattern || k.resolution || JSON.stringify(k)}`)
        .join("\n");

      const prompt = `A development task is starting. Based on past learnings, provide brief context:

Task: ${storyId} - ${title}
Requirements: ${linkedRequirements?.join(", ") || "N/A"}
Acceptance Criteria: ${JSON.stringify(context.acceptanceCriteria)}

Past Learnings:
${knowledgeSummary}

Synthesize into 2-3 actionable sentences.`;

      additionalContext = await askClaude(prompt);
      console.error(`\n  Knowledge Context:\n${additionalContext.split("\n").map((l) => "    " + l).join("\n")}`);
    } catch (err) {
      console.error(`  Claude: (unavailable) ${err.message}`);
    }
  }

  if (additionalContext) {
    console.log(JSON.stringify({ additionalContext }));
  }
}

main().catch((err) => {
  console.error("[on_task_start] Error:", err.message);
  process.exit(1);
});
```

### 5. `.saga/hooks/on-task-completed.js`

```javascript
#!/usr/bin/env node
/**
 * SAGA Lifecycle Hook: on_task_completed
 * Triggered: After story passes all checks
 *
 * Features:
 * - Extracts and stores learnings for future tasks
 * - Closes PM issue, creates MR based on workflow config
 */

import { query } from "@anthropic-ai/claude-agent-sdk";
import { appendKnowledge, extractKeywords } from "./knowledge.js";
import { loadProjectConfig, handleStoryComplete } from "./pm-integration.js";

async function askClaude(prompt) {
  let result = "";
  for await (const message of query({
    prompt,
    options: { allowedTools: [], maxTurns: 1 },
  })) {
    if (message.type === "result" && message.subtype === "success") {
      result = message.result;
    }
  }
  return result;
}

async function main() {
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const context = JSON.parse(Buffer.concat(chunks).toString());

  const { storyId, title, commitHash, filesChanged, linkedRequirements, metrics } = context;
  const durationMinutes = Math.round((metrics?.durationMs || 0) / 60000);

  console.error(`[on_task_completed] ${storyId}: ${title}`);
  console.error(`  Commit: ${commitHash}`);
  console.error(`  Files: ${filesChanged?.length || 0}`);
  console.error(`  Duration: ${durationMinutes}m`);
  console.error(`  Requirements: ${linkedRequirements?.join(", ") || "N/A"}`);

  // PM Integration
  const config = await loadProjectConfig();
  if (config?.pm?.platform !== "none") {
    const pmResult = await handleStoryComplete(context, config);
    if (pmResult.closed) {
      console.error(`  PM: Issue closed`);
    }
    if (pmResult.prUrl) {
      console.error(`  PM: Created PR ${pmResult.prUrl}`);
    }
  }

  // Extract learnings
  try {
    const prompt = `Extract reusable learnings from this completed task:

Story: ${storyId} - ${title}
Files: ${JSON.stringify(filesChanged)}
Requirements: ${linkedRequirements?.join(", ") || "N/A"}

Respond with JSON:
{
  "pattern": "Implementation pattern used (1 sentence)",
  "keyFiles": ["key", "files"],
  "decisions": ["Technical decision 1"],
  "reusableFor": ["future task type"]
}`;

    const learningsJson = await askClaude(prompt);
    let learnings;
    try {
      learnings = JSON.parse(learningsJson.replace(/```json\n?|\n?```/g, "").trim());
    } catch {
      learnings = { pattern: `Completed: ${title}`, keyFiles: filesChanged?.slice(0, 5) || [] };
    }

    const keywords = extractKeywords(context);
    await appendKnowledge("patterns.jsonl", {
      storyId,
      title,
      linkedRequirements,
      pattern: learnings.pattern,
      keyFiles: learnings.keyFiles,
      keywords,
    });

    console.error(`  Knowledge: ${learnings.pattern}`);
  } catch (err) {
    console.error(`  Knowledge extraction failed: ${err.message}`);
  }
}

main().catch((err) => {
  console.error("[on_task_completed] Error:", err.message);
  process.exit(1);
});
```

### 6. `.saga/hooks/on-task-blocked.js`

```javascript
#!/usr/bin/env node
/**
 * SAGA Lifecycle Hook: on_task_blocked
 * Triggered: After max retries exceeded
 *
 * Features:
 * - Records blockers for future prevention
 * - Updates PM issue with blocked status
 */

import { query } from "@anthropic-ai/claude-agent-sdk";
import { appendKnowledge, findRelevantKnowledge, extractKeywords } from "./knowledge.js";
import { loadProjectConfig, handleStoryBlocked } from "./pm-integration.js";

async function askClaude(prompt) {
  let result = "";
  for await (const message of query({
    prompt,
    options: { allowedTools: [], maxTurns: 1 },
  })) {
    if (message.type === "result" && message.subtype === "success") {
      result = message.result;
    }
  }
  return result;
}

async function main() {
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const context = JSON.parse(Buffer.concat(chunks).toString());

  const { storyId, title, blockedReason, retryCount, errors, linkedRequirements } = context;

  console.error(`[on_task_blocked] ${storyId}: ${title}`);
  console.error(`  Reason: ${blockedReason}`);
  console.error(`  Attempts: ${retryCount}`);
  console.error(`  Requirements: ${linkedRequirements?.join(", ") || "N/A"}`);

  // PM Integration
  const config = await loadProjectConfig();
  if (config?.pm?.platform !== "none") {
    const pmResult = await handleStoryBlocked(context, config);
    if (pmResult.updated) {
      console.error(`  PM: Issue updated with blocked status`);
    }
  }

  // Analyze and store blocker
  const keywords = extractKeywords(context);

  try {
    const prompt = `Analyze this blocked task:

Story: ${storyId} - ${title}
Reason: ${blockedReason}
Errors: ${JSON.stringify(errors?.slice(0, 5))}

Respond with JSON:
{
  "rootCause": "Likely root cause",
  "category": "dependency|type-error|test-failure|build-error|environment|logic-error|other",
  "suggestedActions": ["Action 1", "Action 2"],
  "preventionTip": "How to prevent this"
}`;

    const analysisJson = await askClaude(prompt);
    let analysis;
    try {
      analysis = JSON.parse(analysisJson.replace(/```json\n?|\n?```/g, "").trim());
    } catch {
      analysis = { rootCause: blockedReason, category: "other" };
    }

    await appendKnowledge("blockers.jsonl", {
      storyId,
      title,
      blockedReason,
      linkedRequirements,
      category: analysis.category,
      rootCause: analysis.rootCause,
      errors: errors?.slice(0, 5),
      keywords,
    });

    console.error(`  Analysis: ${analysis.rootCause} (${analysis.category})`);
  } catch (err) {
    console.error(`  Analysis failed: ${err.message}`);
  }
}

main().catch((err) => {
  console.error("[on_task_blocked] Error:", err.message);
  process.exit(1);
});
```

## After Creating

Install dependencies and make hooks executable:

```bash
cd .saga/hooks && npm install && chmod +x *.js
```

## Output

After creating hooks, inform the user:

```
Created .saga/ structure with Compounding Knowledge + PM Integration:
  .saga/
  ├── .gitignore
  ├── knowledge/
  │   ├── patterns.jsonl
  │   ├── decisions.jsonl
  │   └── blockers.jsonl
  └── hooks/
      ├── package.json
      ├── node_modules/
      ├── knowledge.js
      ├── pm-integration.js
      ├── on-task-start.js
      ├── on-task-completed.js
      └── on-task-blocked.js

Features:
- Compounding knowledge across task executions
- Automatic PM tool sync (GitHub/GitLab)
- Traceability through linked requirements

Uses Claude Agent SDK - no separate API key required.
```
