---
name: W-03 Spawn investigation in a git worktree
description: Set up a git worktree of the affected repo, spawn the investigator agent, and based on its returned confidence and significant_decisions, optionally chain test-writer and fix-author agents to produce a draft PR.
---

# W-03 — Spawn Investigation

The top-level orchestrates the chain; each agent runs in the same worktree.

## Step 1 — Worktree setup

Find the affected repo's checkout. If unknown, ask the user where it is.

Create a worktree:

```
cd <repo-checkout>
git fetch origin
git worktree add ../<repo>-sentry-<issue-id> origin/main -b sentry/<issue-id>
```

Branch name convention: `sentry/<sentry-issue-short-id>`. The branch is local until the fix-author opens a draft PR.

If the repo's main branch isn't `main` (e.g., `master`, `develop`), use whatever the repo uses.

## Step 2 — Spawn investigator

Use the `Agent` tool with `subagent_type: general-purpose` (or a project-specific agent if defined). Prompt the agent per `agents/investigator.md`. Pass:

- Sentry issue summary and stack trace (top 20 in-app frames).
- The worktree path as the working directory.
- Explicit reminder: read-only, do not modify files.

Wait for the agent's structured return. Expected fields:

- `likely_cause` (paragraph)
- `confidence` (low / medium / high)
- `proposed_approach` (test strategy, fix sketch, scope)
- `significant_decisions` (array of R-05 flags, possibly empty)
- `files_of_interest` (paths the user should look at if they want to dig in)

## Step 3 — Decide whether to chain

Apply the decision rule from R-05 / WORKFLOW.md step 6:

| Confidence | Significant decisions | Action |
|-----------|----------------------|--------|
| high | empty | auto-chain to test-writer (Step 4) |
| high | non-empty | stop, present, ask |
| medium | any | stop, present, ask |
| low | any | stop, present, ask |

When stopping, present the investigator's full return to the user and ask what they'd like to do (proceed anyway, refine, escalate to human investigation, abandon).

## Step 4 — Spawn test-writer

Per `agents/test-writer.md`. Working dir = worktree. The agent writes a failing test that reproduces the error from the Sentry stack trace.

On return, show the diff to the user. On approval, the test is committed in the worktree.

If the test-writer can't reproduce (e.g., needs prod data per R-04, or the error isn't deterministic), it returns that finding and the chain stops.

## Step 5 — Spawn fix-author

Per `agents/fix-author.md`. Working dir = worktree. The agent writes the minimal change that turns the failing test green.

On return, the agent has produced commits and pushed the branch, then opened a **draft** PR. Show the PR URL to the user. Never opens a non-draft PR.

## Step 6 — Cleanup

The worktree stays until the user merges or abandons the PR. Do not auto-clean. If the user explicitly says "abandon", run:

```
git worktree remove ../<repo>-sentry-<issue-id>
git branch -D sentry/<issue-id>
```

Confirm before running destructive cleanup.

## Errors and stops

If any agent reports a hard error (compile fail, test infra broken, can't find the file), stop the chain and surface to the user. Don't escalate or retry blindly.
