---
description: Rules for executing PR test plans end-to-end, running the preflight first and then all steps without pausing, skipping any spec step, and reconstructing missing seed scripts.
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

**Run the full test plan end-to-end without pausing for confirmation.** Once `/pr-test-preflight` passes, execute every step in sequence on your own — do not stop to ask "okay" / "next" between steps. Skip a spec step — see below.

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

## Never Run Specs — Skip Every Spec Step

**A test plan is a manual plan. Skip any step that tells you to run specs, rspec, jest, vitest or rubocop.**

GitHub runs the full suite and every linter on each push. A failure blocks the merge. A local run tells Mike nothing new. It also costs minutes and can fail for reasons that have nothing to do with the PR — a missing node package, a stale database, or a second rspec process on the same test database.

- Skip the step. Say which step you skipped and why.
- Report the branch state from GitHub instead: `gh pr checks <number> --repo scientist-hq/rx`.
- This covers a spec step written into the plan, and a spec run you were about to add on your own.
- Run the browser and console steps as normal. The rule covers specs and linters only.

- ❌ BAD: `bundle exec rspec spec/helpers/proposal_helper_spec.rb` because step 8 asks for it
- ❌ BAD: run the changed spec files at the end to confirm the PR is sound
- ✅ GOOD: "Step 8 asks for rspec. Skipped — GitHub runs the suite and blocks the merge on a failure."
- ✅ GOOD: `gh pr checks 41016 --repo scientist-hq/rx`

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
