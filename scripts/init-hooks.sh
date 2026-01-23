#!/bin/bash

# SAGA Hooks Initialization Script
# Creates lifecycle hooks with bash fallbacks
#
# Usage: init-hooks.sh [--force]

set -euo pipefail

FORCE=false
if [[ "${1:-}" == "--force" ]]; then
  FORCE=true
fi

# Check if .saga exists
if [[ ! -d ".saga" ]]; then
  echo "Error: .saga directory not found. Run /saga init first."
  exit 1
fi

# Check if hooks already exist
if [[ -f ".saga/hooks/on-task-start.js" && "$FORCE" != "true" ]]; then
  echo "Hooks already initialized. Use --force to overwrite."
  exit 0
fi

echo "Initializing SAGA lifecycle hooks..."

# Create directories
mkdir -p .saga/hooks .saga/knowledge

# Create package.json
cat > .saga/hooks/package.json << 'EOF'
{
  "name": "saga-hooks",
  "type": "module",
  "private": true,
  "dependencies": {}
}
EOF

# Create knowledge.js
cat > .saga/hooks/knowledge.js << 'JSEOF'
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

async function ensureKnowledgeDir() {
  if (!existsSync(KNOWLEDGE_DIR)) {
    await mkdir(KNOWLEDGE_DIR, { recursive: true });
  }
}

export async function appendKnowledge(filename, entry) {
  await ensureKnowledgeDir();
  const filepath = join(KNOWLEDGE_DIR, filename);
  const line = JSON.stringify({ ...entry, timestamp: new Date().toISOString() }) + "\n";
  await appendFile(filepath, line);
}

export async function readKnowledge(filename) {
  const filepath = join(KNOWLEDGE_DIR, filename);
  if (!existsSync(filepath)) return [];
  const content = await readFile(filepath, "utf-8");
  return content.split("\n").filter(l => l.trim()).map(l => JSON.parse(l));
}

export async function findRelevantKnowledge(keywords, options = {}) {
  const { maxResults = 5, files = ["patterns.jsonl", "blockers.jsonl"] } = options;
  const allEntries = [];
  for (const file of files) {
    const entries = await readKnowledge(file);
    allEntries.push(...entries.map(e => ({ ...e, source: file })));
  }
  const scored = allEntries.map(entry => {
    const text = JSON.stringify(entry).toLowerCase();
    const score = keywords.reduce((acc, kw) => acc + (text.includes(kw.toLowerCase()) ? 1 : 0), 0);
    return { entry, score };
  });
  return scored.filter(s => s.score > 0).sort((a, b) => b.score - a.score).slice(0, maxResults).map(s => s.entry);
}

export function extractKeywords(context) {
  const keywords = [];
  if (context.title) keywords.push(...context.title.toLowerCase().split(/\s+/).filter(w => w.length > 3));
  if (context.linkedRequirements) keywords.push(...context.linkedRequirements.map(r => r.toLowerCase()));
  return [...new Set(keywords)];
}
JSEOF

# Create pm-integration.js (simplified)
cat > .saga/hooks/pm-integration.js << 'JSEOF'
#!/usr/bin/env node
/**
 * SAGA PM Integration (Simplified)
 * Stubs for PM tool integration - actual calls handled by fire-hook.sh or orchestrator
 */

import { readFile, writeFile } from "fs/promises";
import { existsSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PROJECT_CONFIG = join(__dirname, "..", "project.json");
const PM_LINKS = join(__dirname, "..", "pm-links.json");

export async function loadProjectConfig() {
  if (!existsSync(PROJECT_CONFIG)) return null;
  return JSON.parse(await readFile(PROJECT_CONFIG, "utf-8"));
}

export async function loadPmLinks() {
  if (!existsSync(PM_LINKS)) return { stories: {}, changeRequests: {} };
  return JSON.parse(await readFile(PM_LINKS, "utf-8"));
}

export async function savePmLinks(links) {
  await writeFile(PM_LINKS, JSON.stringify(links, null, 2));
}

export async function handleStoryStart(context, config) {
  if (!config?.pm || config.pm.platform === "none") return { skipped: true };
  console.error(`  PM: Would create/update issue for ${context.storyId}`);
  return { skipped: true, reason: "PM integration handled by orchestrator" };
}

export async function handleStoryComplete(context, config) {
  if (!config?.pm || config.pm.platform === "none") return { skipped: true };
  console.error(`  PM: Would close issue for ${context.storyId}`);
  return { skipped: true, reason: "PM integration handled by orchestrator" };
}

export async function handleStoryBlocked(context, config) {
  if (!config?.pm || config.pm.platform === "none") return { skipped: true };
  console.error(`  PM: Would mark issue blocked for ${context.storyId}`);
  return { skipped: true, reason: "PM integration handled by orchestrator" };
}
JSEOF

# Create on-task-start.js
cat > .saga/hooks/on-task-start.js << 'JSEOF'
#!/usr/bin/env node
/**
 * SAGA Lifecycle Hook: on_task_start
 */

import { findRelevantKnowledge, extractKeywords } from "./knowledge.js";
import { loadProjectConfig, handleStoryStart } from "./pm-integration.js";

async function main() {
  const chunks = [];
  for await (const chunk of process.stdin) chunks.push(chunk);
  const context = JSON.parse(Buffer.concat(chunks).toString());

  const { storyId, title, branch, iteration, linkedRequirements } = context;

  console.error(`[on_task_start] ${storyId}: ${title}`);
  console.error(`  Branch: ${branch || "N/A"}`);
  console.error(`  Iteration: ${iteration || 1}`);
  console.error(`  Requirements: ${linkedRequirements?.join(", ") || "N/A"}`);

  const config = await loadProjectConfig();
  if (config?.pm?.platform && config.pm.platform !== "none") {
    await handleStoryStart(context, config);
  }

  const keywords = extractKeywords(context);
  const relevantKnowledge = await findRelevantKnowledge(keywords);

  if (relevantKnowledge.length > 0) {
    console.error(`  Found ${relevantKnowledge.length} relevant knowledge entries`);
    console.log(JSON.stringify({ additionalContext: relevantKnowledge.map(k => k.pattern || k.rootCause).join("; ") }));
  }
}

main().catch(err => { console.error("[on_task_start] Error:", err.message); process.exit(1); });
JSEOF

# Create on-task-completed.js
cat > .saga/hooks/on-task-completed.js << 'JSEOF'
#!/usr/bin/env node
/**
 * SAGA Lifecycle Hook: on_task_completed
 * - Stores knowledge patterns
 * - Updates progress.txt
 */

import { appendFile } from "fs/promises";
import { dirname, join } from "path";
import { fileURLToPath } from "url";
import { appendKnowledge, extractKeywords } from "./knowledge.js";
import { loadProjectConfig, handleStoryComplete } from "./pm-integration.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PROGRESS_FILE = join(__dirname, "..", "progress.txt");

async function updateProgress(context) {
  const { storyId, title, commitHash, filesChanged, linkedRequirements, metrics } = context;
  const timestamp = new Date().toISOString();
  const durationMin = metrics?.durationMs ? Math.round(metrics.durationMs / 60000) : "?";

  const entry = `
## ${timestamp.split("T")[0]} - ${storyId}: ${title}
- **Commit:** ${commitHash || "pending"}
- **Files:** ${filesChanged?.join(", ") || "none"}
- **Duration:** ${durationMin} min
- **Requirements:** ${linkedRequirements?.join(", ") || "N/A"}
---
`;

  await appendFile(PROGRESS_FILE, entry);
}

async function main() {
  const chunks = [];
  for await (const chunk of process.stdin) chunks.push(chunk);
  const context = JSON.parse(Buffer.concat(chunks).toString());

  const { storyId, title, commitHash, filesChanged, linkedRequirements, metrics } = context;

  console.error(`[on_task_completed] ${storyId}: ${title}`);
  console.error(`  Commit: ${commitHash || "N/A"}`);
  console.error(`  Files: ${filesChanged?.length || 0}`);
  console.error(`  Requirements: ${linkedRequirements?.join(", ") || "N/A"}`);

  const config = await loadProjectConfig();
  if (config?.pm?.platform && config.pm.platform !== "none") {
    await handleStoryComplete(context, config);
  }

  // Store knowledge
  const keywords = extractKeywords(context);
  await appendKnowledge("patterns.jsonl", {
    storyId, title, linkedRequirements,
    pattern: `Completed: ${title}`,
    keyFiles: filesChanged?.slice(0, 5) || [],
    keywords
  });
  console.error(`  Knowledge: Stored pattern for ${storyId}`);

  // Update progress.txt
  await updateProgress(context);
  console.error(`  Progress: Updated progress.txt`);
}

main().catch(err => { console.error("[on_task_completed] Error:", err.message); process.exit(1); });
JSEOF

# Create on-task-blocked.js
cat > .saga/hooks/on-task-blocked.js << 'JSEOF'
#!/usr/bin/env node
/**
 * SAGA Lifecycle Hook: on_task_blocked
 */

import { appendKnowledge, extractKeywords } from "./knowledge.js";
import { loadProjectConfig, handleStoryBlocked } from "./pm-integration.js";

async function main() {
  const chunks = [];
  for await (const chunk of process.stdin) chunks.push(chunk);
  const context = JSON.parse(Buffer.concat(chunks).toString());

  const { storyId, title, blockedReason, retryCount, errors, linkedRequirements } = context;

  console.error(`[on_task_blocked] ${storyId}: ${title}`);
  console.error(`  Reason: ${blockedReason || "Unknown"}`);
  console.error(`  Attempts: ${retryCount || 0}`);
  console.error(`  Requirements: ${linkedRequirements?.join(", ") || "N/A"}`);

  const config = await loadProjectConfig();
  if (config?.pm?.platform && config.pm.platform !== "none") {
    await handleStoryBlocked(context, config);
  }

  const keywords = extractKeywords(context);
  await appendKnowledge("blockers.jsonl", {
    storyId, title, blockedReason, linkedRequirements,
    category: "other",
    rootCause: blockedReason,
    errors: errors?.slice(0, 5),
    keywords
  });

  console.error(`  Knowledge: Stored blocker for ${storyId}`);
}

main().catch(err => { console.error("[on_task_blocked] Error:", err.message); process.exit(1); });
JSEOF

# Make scripts executable
chmod +x .saga/hooks/*.js

echo ""
echo "SAGA Hooks Initialized"
echo ""
echo "Created:"
echo "  .saga/hooks/knowledge.js        - Knowledge system utilities"
echo "  .saga/hooks/pm-integration.js   - PM tool stubs"
echo "  .saga/hooks/on-task-start.js    - Pre-execution hook"
echo "  .saga/hooks/on-task-completed.js - Post-success hook"
echo "  .saga/hooks/on-task-blocked.js  - Failure hook"
echo ""
echo "Note: Bash fallback (fire-hook.sh) is also available."
