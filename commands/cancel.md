---
description: "Cancel the active SAGA execution loop"
---

# Cancel SAGA Loop

Stop the currently running SAGA execution loop.

## Process

### 1. Check Loop State

Read `.saga/state.json`:
- If not exists: "No active SAGA loop to cancel."
- If exists: Proceed with cancellation

### 2. Display Current State

```
SAGA Loop Status
================

Project: [Project Name]
Started: [timestamp]
Current Iteration: [N]
Stories Completed: [X/Y]

Are you sure you want to cancel? (y/n)
```

### 3. Perform Cancellation

If confirmed:

1. **Remove state file:**
   ```bash
   rm .saga/state.json
   ```

2. **Log cancellation in progress.txt:**
   ```
   ## [Date/Time] - Loop Cancelled
   - Cancelled at iteration [N]
   - Stories completed: [X/Y]
   - Reason: User requested
   ---
   ```

3. **Update any in-progress stories:**
   - If a story was mid-execution, note it in plan.json
   - Don't mark as blocked (user can resume later)

4. **PM Integration:**
   - If PM configured, optionally update in-progress issues
   - Add comment: "SAGA loop cancelled by user"

### 4. Output Confirmation

```
SAGA Loop Cancelled
===================

Progress saved:
- Iteration: [N]
- Stories completed: [X/Y] (saved in plan.json)
- Progress log: .saga/progress.txt

The loop has been stopped. Your progress is preserved.

To resume:
  /saga execute    - Continue from where you left off

To start fresh:
  /saga plan       - Regenerate the plan
  /saga execute    - Start new execution
```

## Force Cancel

If the loop is stuck or unresponsive:

```
/saga cancel --force
```

This removes state.json without confirmation and without updating PM tool.

## Notes

- Cancelling does NOT reset story pass/fail status
- Cancelling does NOT delete progress.txt entries
- You can always resume with `/saga execute`
- Mid-execution stories will be retried on next run
