---
description: Update local main in one pass — pull, bundle install, db:migrate, then clean up schema.rb. Load when Mike runs /update-main or asks to update or pull main.
---

## Git Authorization for This Skill

Mike gave this skill a narrow exception to the git rule. The exception applies only while Mike runs this skill.

- You may run `git pull` on `main` without a question.
- You may run `git switch main` only after Mike says yes to the question in Step 2. Ask again each time.
- Every other git command that changes state stays forbidden: no `stash`, `commit`, `reset`, `checkout <branch>`, or `push`.

## Step 1 — Check the Branch and the Working Tree

Run these as two parallel calls:

```bash
git branch --show-current
```

```bash
git status --short
```

## Step 2 — If the Branch Is Not `main`, Ask

Tell Mike the current branch. Then ask: "Do you want me to switch to main?"

- If Mike says yes, run `git switch main`. If the switch fails, show the error and stop.
- If Mike says no, or the answer is unclear, stop. Do not run the other steps.

If the branch is `main`, go to Step 3 with no question.

## Step 3 — Stop on Uncommitted Changes Other Than `db/schema.rb`

A modified `db/schema.rb` is normal. Step 6 cleans it up. Continue.

If other files are modified, show the list to Mike and ask how to continue. Do not stash, commit, or discard them yourself.

## Step 4 — Pull

```bash
git pull
```

If the pull fails, show the error and stop. A common cause is a local `db/schema.rb` change that conflicts with the incoming one. Ask Mike before you discard it with `git checkout -- db/schema.rb`.

## Step 5 — Install Gems and Run Migrations

Run these one after the other, from the session CWD with no `cd`. See the `bundle` skill.

```bash
bundle install
```

```bash
bundle exec rake db:migrate
```

If either command fails, show the error and stop.

## Step 6 — Clean Up `db/schema.rb`

Load the `database-clean-schema` skill and follow it until `git diff -- db/schema.rb` shows no output.

## Step 7 — Report

Give Mike a short summary:

- Branch: `main` (and whether you switched to it)
- Pull: the commit range, or "already up to date"
- Gems: up to date, or the gems that changed
- Migrations: none, or the migrations that ran
- Schema: clean, or the diff that remains
