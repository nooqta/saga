#!/usr/bin/env node
/**
 * SAGA Hook: on-task-start (Default/Fallback)
 *
 * Triggered by SubagentStart event when a story-executor agent is spawned.
 *
 * Execution order:
 * 1. Check for project-level hook at .saga/hooks/on-task-start.js
 * 2. If exists, execute it with context
 * 3. If not, run minimal default behavior
 */

const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

// Environment variables from Claude Code hook context
const hookEvent = process.env.CLAUDE_HOOK_EVENT || 'SubagentStart';
const agentType = process.env.CLAUDE_SUBAGENT_TYPE || '';
const workingDir = process.env.CLAUDE_WORKING_DIR || process.cwd();

// Project-level paths
const sagaDir = path.join(workingDir, '.saga');
const projectHookJs = path.join(sagaDir, 'hooks', 'on-task-start.js');
const projectHookSh = path.join(sagaDir, 'hooks', 'on-task-start.sh');
const stateFile = path.join(sagaDir, 'state.json');
const planFile = path.join(sagaDir, 'plan.json');
const logFile = path.join(sagaDir, 'hooks.log');

/**
 * Append a log entry
 */
function log(message) {
  const timestamp = new Date().toISOString();
  const entry = `[${timestamp}] [on-task-start] ${message}\n`;

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
 * Find current story from plan.json
 */
function findCurrentStory(plan) {
  if (!plan || !plan.stories) return null;
  return plan.stories.find(s => s.passes === false);
}

/**
 * Build context object for project hooks
 */
function buildContext(story, plan, state) {
  return {
    storyId: story?.id || null,
    title: story?.title || null,
    description: story?.description || null,
    branch: plan?.branch || 'main',
    iteration: state?.iterations?.length || 1,
    priority: story?.priority || 0,
    acceptanceCriteria: story?.acceptanceCriteria || [],
    linkedRequirements: story?.linkedRequirements || [],
    featureId: story?.featureId || null,
    epicId: story?.epicId || null,
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
 * Run minimal default behavior
 */
function runDefaultBehavior(story, plan) {
  log(`Running default behavior for story: ${story?.id || 'unknown'}`);

  // Read or create state.json
  let state = readJson(stateFile) || {
    currentStory: null,
    status: 'idle',
    startedAt: null,
    iterations: []
  };

  // Update state with current story
  state.currentStory = story?.id || null;
  state.status = 'in_progress';
  state.startedAt = new Date().toISOString();
  state.lastUpdated = new Date().toISOString();

  // Add iteration record
  state.iterations = state.iterations || [];
  state.iterations.push({
    storyId: story?.id,
    startedAt: state.startedAt,
    completedAt: null,
    status: 'in_progress',
    agent: agentType
  });

  // Save updated state
  writeJson(stateFile, state);

  log(`State updated: story=${story?.id || 'none'}, status=in_progress`);
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

  // Read plan.json to find current story
  const plan = readJson(planFile);
  const currentStory = findCurrentStory(plan);
  const state = readJson(stateFile);

  if (!currentStory) {
    log('No pending story found in plan.json');
    process.exit(0);
  }

  log(`Starting story: ${currentStory.id} - ${currentStory.title}`);

  // Build context for hooks
  const context = buildContext(currentStory, plan, state);

  // Check for project-level hooks (JS preferred, then SH)
  if (fs.existsSync(projectHookJs)) {
    try {
      await executeProjectHook(projectHookJs, context);
      log('Project hook (JS) executed successfully');
      process.exit(0);
    } catch (err) {
      log(`Project hook (JS) failed: ${err.message}, falling back to default`);
    }
  } else if (fs.existsSync(projectHookSh)) {
    try {
      await executeProjectHook(projectHookSh, context);
      log('Project hook (SH) executed successfully');
      process.exit(0);
    } catch (err) {
      log(`Project hook (SH) failed: ${err.message}, falling back to default`);
    }
  } else {
    log('No project hook found, using default behavior');
  }

  // Run default behavior
  runDefaultBehavior(currentStory, plan);

  log('Hook completed');
  process.exit(0);
}

// Run the hook
main().catch((error) => {
  log(`Hook error: ${error.message}`);
  process.exit(1);
});
