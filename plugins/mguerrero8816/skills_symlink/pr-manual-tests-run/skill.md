---
description: Rules for executing PR test plans end-to-end, running the preflight first and then all steps without pausing, and reconstructing missing seed scripts.
args: Optional GitHub PR URL to test
---

# PR Test Execution Rules

## Resolving What to Test

When invoked, determine the target PR in this order:

1. **URL provided as args** — use it directly.
2. **No URL** — check context: run `git branch --show-current` and look up the open PR for that branch with `gh pr view --json url`.
3. **No open PR found** — ask the user: "Which PR URL should I run tests for?"

Once the PR URL is resolved, fetch the test plan from the PR description before starting.

## Run All Steps Once Preflight Passes

**Run the full test plan end-to-end without pausing for confirmation.** Once `/pr-test-preflight` passes, execute every step in sequence on your own — do not stop to ask "okay" / "next" between steps.

The pattern for each step:
1. Announce which step you're running
2. Execute it (console commands, seed scripts, browser automation, etc.)
3. Report the result clearly — what you saw, what passed, what was unexpected
4. For browser steps: take a screenshot and tell the user the path
5. Move straight to the next step

**When to stop and surface to the user instead of continuing:**
- The preflight fails — report why and stop; do not run any test steps.
- A step fails or produces an unexpected result — report it and stop rather than pressing on through dependent steps.
- A step needs a decision only the user can make (ambiguous data, destructive action, missing prerequisite you can't reconstruct).

At the end, give a summary of all steps: what passed, what failed, and any screenshot paths.

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
