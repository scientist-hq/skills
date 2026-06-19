---
description: Rules for executing PR test plans interactively, including step-by-step pacing, reconstructing missing seed scripts, and running the preflight first.
args: Optional GitHub PR URL to test
---

# PR Test Execution Rules

## Resolving What to Test

When invoked, determine the target PR in this order:

1. **URL provided as args** — use it directly.
2. **No URL** — check context: run `git branch --show-current` and look up the open PR for that branch with `gh pr view --json url`.
3. **No open PR found** — ask the user: "Which PR URL should I run tests for?"

Once the PR URL is resolved, fetch the test plan from the PR description before starting.

## Always Run Steps One at a Time

**NEVER run all test steps in a single pass. Always execute one step, pause, and wait for the user to confirm before moving to the next.**

This is the default mode for all PR test plans, even if the user doesn't ask for it explicitly.

The pattern for each step:
1. Announce which step you're running
2. Execute it (console commands, seed scripts, browser automation, etc.)
3. Report the result clearly — what you saw, what passed, what was unexpected
4. For browser steps: take a screenshot and tell the user the path
5. Wait for the user to say "okay" / "next" / "step N" before continuing

Do not proceed to the next step on your own.

## Reconstructing Missing Seed Scripts

PR test plans sometimes reference local scripts that aren't committed (e.g. `lib/local/some_seed.rb` — "not committed; uploaded separately"). Do not treat this as a blocker.

When a seed script is missing:
1. Read the test plan to understand what the script is supposed to do
2. Read the relevant service/model code to understand the data requirements
3. Reconstruct the seed inline as a `bundle exec rails runner` one-liner or short script
4. Note that you reconstructed it so the user knows it wasn't the original

## Preflight First

Always run `/pr-test-preflight` before starting any test steps.

## Playwright

Before executing any browser step, invoke `Skill(playwright-qa-rules)`.
