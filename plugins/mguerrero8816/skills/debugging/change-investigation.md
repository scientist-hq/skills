# Investigating Unexpected Behavior After a Change

Rules for when a user reports that something broke after making a change.

## Step 1: Always check what changed first

Before reading any code or running any tests, run:
- `git log --oneline` to orient to recent commits
- `git show HEAD` (or the relevant commit) to see the exact diff

This applies whether the change came from the user, Copilot, another AI, a teammate, or a script.

## Step 2: Assess the diff size

- **Small diff (< ~20 lines):** The diff IS the investigation. Read it, understand it, recommend reverting if the root cause isn't immediately clear.
- **Large diff:** Then broader investigation (spec runs, code tracing) is justified.

## Step 3: Revert-first threshold

If the diff is small and the root cause isn't clear after 2–3 tool calls, recommend reverting before investigating further. Reverting is almost always cheaper than diagnosing, and the user can re-apply the change once the cause is understood.
