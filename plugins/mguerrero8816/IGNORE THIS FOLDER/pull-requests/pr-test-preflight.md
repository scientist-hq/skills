---
description: Pre-flight checklist to run before executing any PR test plan, covering branch verification, uncommitted changes, gem updates, and pending migrations.
---

# PR Test Pre-flight

Run these steps before executing any PR test plan. The goal is to ensure the environment matches what the PR expects without leaving the repo in a dirty state.

## Step 1 — Verify the branch

Check the current branch against the PR's head branch:

```bash
git branch --show-current
gh pr view <PR#> --json headRefName
```

**If the branch is wrong:**
- Tell the user which branch is needed and which branch is currently checked out
- Do NOT switch branches — the user may have uncommitted changes or staged work they need to deal with first
- Wait for the user to confirm they are ready before continuing

## Step 1b — Check for uncommitted changes

Before doing anything else, check if the working tree has uncommitted changes:

```bash
git status --short
```

**If there are uncommitted changes:**
- Show the user the list of modified files
- Ask how they want to handle them: stash, commit, or discard
- **Do NOT proceed to Step 2 until the user responds**
- **Do NOT run `git checkout .` to discard changes without explicit user confirmation**

**If the working tree is clean:** continue to Step 2.

## Step 2 — Update gems

```bash
bundle install
```

Report whether any gems were installed or updated. If bundle install fails, stop and report the error.

## Step 3 — Run pending migrations

First check what's pending:

```bash
bundle exec rake db:migrate:status 2>&1 | grep down
```

If there are pending migrations, run them:

```bash
bundle exec rake db:migrate
```

Report which migrations ran.

## Step 4 — Undo any codebase changes introduced by pre-flight

Migrations and bundle install can leave the working tree dirty (e.g. `db/schema.rb` updated). Revert all of it:

```bash
git checkout .
```

This undoes file changes only — database changes from migrations are kept.

## Done

Report a summary:
- Branch: correct / wrong (and what was needed)
- Gems: up to date / N gems updated
- Migrations: none pending / N migrations ran (list them)
- Working tree: clean / dirty (list any remaining changes)

Only proceed to the test steps once the user confirms.
