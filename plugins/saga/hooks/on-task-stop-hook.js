#!/usr/bin/env node
/**
 * SAGA Hook: on-task-stop (Default/Fallback)
 *
 * Triggered by SubagentStop event when a story-executor agent completes.
 *
 * Execution order:
 * 1. Determine outcome (completed/blocked) from state
 * 2. Check for project-level hook at .saga/hooks/on-task-completed.js or on-task-blocked.js
 * 3. If exists, execute it with context
 * 4. If not, run minimal default behavior
 */

const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

// Environment variables from Claude Code hook context
const hookEvent = process.env.CLAUDE_HOOK_EVENT || 'SubagentStop';
const agentType = process.env.CLAUDE_SUBAGENT_TYPE || '';
const workingDir = process.env.CLAUDE_WORKING_DIR || process.cwd();

// Project-level paths
const sagaDir = path.join(workingDir, '.saga');
const stateFile = path.join(sagaDir, 'state.json');
const planFile = path.join(sagaDir, 'plan.json');
const progressFile = path.join(sagaDir, 'progress.txt');
const logFile = path.join(sagaDir, 'hooks.log');

// Project hook paths
const completedHookJs = path.join(sagaDir, 'hooks', 'on-task-completed.js');
const completedHookSh = path.join(sagaDir, 'hooks', 'on-task-completed.sh');
const blockedHookJs = path.join(sagaDir, 'hooks', 'on-task-blocked.js');
const blockedHookSh = path.join(sagaDir, 'hooks', 'on-task-blocked.sh');

/**
 * Append a log entry
 */
function log(message) {
  const timestamp = new Date().toISOString();
  const entry = `[${timestamp}] [on-task-stop] ${message}\n`;

  try {
    if (fs.existsSync(sagaDir)) {
      fs.appendFileSync(logFile, entry);
    }
  } catch (e) {
    // Ignore logging errors
  }

  console.error(entry.trim());
}

/**
 * Read JSON file safely
 */
function readJson(filePath) {
  try {
    if (fs.existsSync(filePath)) {
      return JSON.parse(fs.readFileSync(filePath, 'utf8'));
    }
  } catch (e) {
    log(`Error reading ${filePath}: ${e.message}`);
  }
  return null;
}

/**
 * Write JSON file safely
 */
function writeJson(filePath, data) {
  try {
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
    return true;
  } catch (e) {
    log(`Error writing ${filePath}: ${e.message}`);
    return false;
  }
}

/**
 * Find story by ID in plan
 */
function findStory(plan, storyId) {
  if (!plan || !plan.stories || !storyId) return null;
  return plan.stories.find(s => s.id === storyId);
}

/**
 * Format duration from timestamps
 */
function formatDuration(startedAt, completedAt) {
  const start = new Date(startedAt);
  const end = new Date(completedAt);
  const durationMs = end - start;

  const hours = Math.floor(durationMs / 3600000);
  const minutes = Math.floor((durationMs % 3600000) / 60000);
  const seconds = Math.floor((durationMs % 60000) / 1000);

  if (hours > 0) return `${hours}h ${minutes}m`;
  if (minutes > 0) return `${minutes}m ${seconds}s`;
  return `${seconds}s`;
}

/**
 * Build context object for completed hook
 */
function buildCompletedContext(story, state, plan) {
  const currentIteration = state?.iterations?.[state.iterations.length - 1];
  const startedAt = currentIteration?.startedAt || state?.startedAt;
  const completedAt = new Date().toISOString();

  return {
    storyId: story?.id || null,
    title: story?.title || null,
    commitHash: state?.lastCommit || null,
    filesChanged: state?.filesChanged || [],
    linkedRequirements: story?.linkedRequirements || [],
    branch: plan?.branch || 'main',
    metrics: {
      startedAt,
      completedAt,
      durationMs: startedAt ? (new Date(completedAt) - new Date(startedAt)) : 0
    },
    timestamp: completedAt
  };
}

/**
 * Build context object for blocked hook
 */
function buildBlockedContext(story, state, plan) {
  const currentIteration = state?.iterations?.[state.iterations.length - 1];

  return {
    storyId: story?.id || null,
    title: story?.title || null,
    blockedReason: state?.blockedReason || 'Unknown error',
    retryCount: state?.retryCount || state?.iterations?.length || 1,
    errors: state?.errors || [],
    linkedRequirements: story?.linkedRequirements || [],
    branch: plan?.branch || 'main',
    lastAttempt: {
      startedAt: currentIteration?.startedAt,
      completedAt: new Date().toISOString(),
      error: state?.lastError || state?.blockedReason
    },
    timestamp: new Date().toISOString()
  };
}

/**
 * Execute project-level hook
 */
function executeProjectHook(hookPath, context) {
  return new Promise((resolve, reject) => {
    const isJs = hookPath.endsWith('.js');
    const cmd = isJs ? 'node' : 'bash';

    log(`Executing project hook: ${hookPath}`);

    const child = spawn(cmd, [hookPath], {
      cwd: workingDir,
      env: {
        ...process.env,
        SAGA_CONTEXT: JSON.stringify(context)
      },
      stdio: ['pipe', 'pipe', 'pipe']
    });

    // Send context via stdin
    child.stdin.write(JSON.stringify(context));
    child.stdin.end();

    let stdout = '';
    let stderr = '';

    child.stdout.on('data', (data) => { stdout += data; });
    child.stderr.on('data', (data) => { stderr += data; });

    child.on('close', (code) => {
      if (stderr) console.error(stderr);
      if (stdout) console.log(stdout);

      if (code === 0) {
        resolve({ success: true, stdout, stderr });
      } else {
        resolve({ success: false, code, stdout, stderr });
      }
    });

    child.on('error', (err) => {
      reject(err);
    });
  });
}

/**
 * Append entry to progress.txt
 */
function appendProgress(storyId, status, context) {
  const date = new Date().toISOString().split('T')[0];
  const duration = context.metrics?.durationMs
    ? formatDuration(context.metrics.startedAt, context.metrics.completedAt)
    : 'N/A';

  const entry = `
## ${date} - ${storyId}
- **Status:** ${status}
- **Duration:** ${duration}
- **Requirements:** ${context.linkedRequirements?.join(', ') || 'N/A'}
---
`;

  try {
    fs.appendFileSync(progressFile, entry);
    log(`Progress entry added for ${storyId}`);
  } catch (e) {
    log(`Error appending progress: ${e.message}`);
  }
}

/**
 * Run default completed behavior
 */
function runDefaultCompletedBehavior(story, state, context) {
  log(`Running default completed behavior for story: ${story?.id || 'unknown'}`);

  // Update iteration record
  const currentIteration = state.iterations?.[state.iterations.length - 1];
  if (currentIteration) {
    currentIteration.completedAt = new Date().toISOString();
    currentIteration.status = 'completed';
  }

  // Update state
  state.status = 'completed';
  state.lastUpdated = new Date().toISOString();
  state.currentStory = null;

  writeJson(stateFile, state);
  appendProgress(story?.id, 'Completed', context);

  log(`Story ${story?.id} marked as completed`);
}

/**
 * Run default blocked behavior
 */
function runDefaultBlockedBehavior(story, state, context) {
  log(`Running default blocked behavior for story: ${story?.id || 'unknown'}`);

  // Update iteration record
  const currentIteration = state.iterations?.[state.iterations.length - 1];
  if (currentIteration) {
    currentIteration.completedAt = new Date().toISOString();
    currentIteration.status = 'blocked';
    currentIteration.errors = context.errors;
  }

  // Update state
  state.status = 'blocked';
  state.blockedReason = context.blockedReason;
  state.lastUpdated = new Date().toISOString();
  state.currentStory = null;

  writeJson(stateFile, state);
  appendProgress(story?.id, `Blocked: ${context.blockedReason}`, context);

  log(`Story ${story?.id} marked as blocked`);
}

/**
 * Main hook execution
 */
async function main() {
  log(`Hook triggered: event=${hookEvent}, agentType=${agentType}`);

  // Check if we're in a SAGA project
  if (!fs.existsSync(sagaDir)) {
    log('No .saga directory found, skipping');
    process.exit(0);
  }

  // Read current state
  const state = readJson(stateFile);
  if (!state || !state.currentStory) {
    log('No active story in state.json');
    process.exit(0);
  }

  // Read plan to get story details
  const plan = readJson(planFile);
  const story = findStory(plan, state.currentStory);

  if (!story) {
    log(`Story ${state.currentStory} not found in plan.json`);
    process.exit(0);
  }

  log(`Processing story completion: ${story.id}`);

  // Determine outcome by checking if story.passes is now true
  const isCompleted = story.passes === true;

  if (isCompleted) {
    // COMPLETED FLOW
    const context = buildCompletedContext(story, state, plan);

    // Check for project-level completed hook
    if (fs.existsSync(completedHookJs)) {
      try {
        await executeProjectHook(completedHookJs, context);
        log('Project completed hook (JS) executed');
        process.exit(0);
      } catch (err) {
        log(`Project hook failed: ${err.message}, using default`);
      }
    } else if (fs.existsSync(completedHookSh)) {
      try {
        await executeProjectHook(completedHookSh, context);
        log('Project completed hook (SH) executed');
        process.exit(0);
      } catch (err) {
        log(`Project hook failed: ${err.message}, using default`);
      }
    }

    // Default completed behavior
    runDefaultCompletedBehavior(story, state, context);

  } else {
    // BLOCKED FLOW
    const context = buildBlockedContext(story, state, plan);

    // Check for project-level blocked hook
    if (fs.existsSync(blockedHookJs)) {
      try {
        await executeProjectHook(blockedHookJs, context);
        log('Project blocked hook (JS) executed');
        process.exit(0);
      } catch (err) {
        log(`Project hook failed: ${err.message}, using default`);
      }
    } else if (fs.existsSync(blockedHookSh)) {
      try {
        await executeProjectHook(blockedHookSh, context);
        log('Project blocked hook (SH) executed');
        process.exit(0);
      } catch (err) {
        log(`Project hook failed: ${err.message}, using default`);
      }
    }

    // Default blocked behavior
    runDefaultBlockedBehavior(story, state, context);
  }

  log('Hook completed');
  process.exit(0);
}

// Run the hook
main().catch((error) => {
  log(`Hook error: ${error.message}`);
  process.exit(1);
});
