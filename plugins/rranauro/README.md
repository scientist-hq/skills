# rranauro — Worktree-First RX Workflow

A two-terminal, worktree-based workflow for moving an RX ticket from "I have an issue number" to "human-ready PR" using Claude Code. Personal-share plugin, opt-in.

## Install

In a Claude Code session:

```
/plugin marketplace add scientist-hq/skills
/plugin install rranauro@scientist-hq-skills
/plugin install rx@scientist-hq-skills        # team plugin — needed for /rx:commit, /rx:pr below
/reload-plugins
```

Confirm install: type `/` and you should see `/rranauro:architect`, `/rranauro:start-ticket`, `/rranauro:start-review`, etc.

Edit any installed command in `~/.claude/plugins/rranauro/` to match your style — installs are local copies and yours to tinker with.

## The Workflow

### 1. Plan the work — `/rranauro:architect`

Open a fresh Claude session in the rx repo. Start the conversation naturally:

```
/rranauro:architect Let's discuss this ticket <issue-URL> before we get started.
```

Claude fetches the issue and walks Phase 1 (problem) → Phase 2 (approaches) → Phase 3 (converge). When the approach is settled, it saves a plan to:

```
rx/plans/<issue_number>-<short-description>.md
```

The plan is your contract with yourself for the rest of the workflow.

### 2. Set up the worktree — `/rranauro:start-ticket <ticket-URL-or-#>`

Reads the issue and the matching plan from `rx/plans/`. Confirms scope before doing anything. Creates a git worktree of the scientist monorepo and runs `~/bin/rx-worktree-init` to symlink personal/untracked files (.claude/, plans/, .env, lib/local, etc.) via the manifest. Hands off to a new Claude session in the worktree.

Worktree path: `/Users/<you>/dev/scientist/rx-<issue>-<slug>/`

### 3. Implement

Work through the plan in the worktree's Claude session:

- Write the code and the acceptance specs (RSpec) together.
- Use `/rx:commit` to break work into clean, single-concern commits.
- Run `bundle exec rspec spec/path/to/spec.rb` after each logical step.
- Lint as you go: `bundle exec rubocop` on touched Ruby files.

### 4. Open the PR — `/rx:pr`

`/rx:pr` is the team's canonical PR command from the `rx` plugin. Creates a draft PR with the right "Type:" and area labels and the standard body format (Description / User Impact / Instructions / Notes), using "Fixes #<n>" to close the issue.

### 5. Add an in-app verification script (optional)

If the change needs in-browser verification a reviewer should run, drop a script in:

```
rx/lib/local/<ticket>_test_in_app.rb
```

These files are untracked — upload the script as a comment on the PR rather than committing it. The convention keeps the PR clean and the scripts easy to iterate on.

### 6. Trigger Copilot review

Right after `/rx:pr` prints the URL:

```
/loop 90s /rranauro:wait-copilot <PR#>
```

Copilot's review takes 5–10 minutes. The loop polls every 90 seconds and fires a macOS notification when comments land — go work on something else in the meantime.

### 7. Independent review in a second terminal — `/rranauro:start-review <PR#>`

Open a NEW terminal, start a fresh Claude session, and run:

```
/rranauro:start-review <PR#>
```

Creates a separate worktree of the PR's head branch (so review state never collides with your dev branch), spawns the `claude-reviewer` subagent, and writes findings to:

```
rx/tmp/reviews/pr-<PR#>/claude-review.md
```

### 8. Apply review feedback in the dev terminal

Switch back to your DEV terminal:

```
Read rx/tmp/reviews/pr-<PR#>/claude-review.md and address the findings.
```

Claude reads the report, makes the fixes, and re-runs specs. Use `/rx:commit` per batch of fixes so each fix is a separate, reviewable commit.

### 9. Address Copilot — `/rranauro:review-copilot <PR#>`

Once the `/rranauro:wait-copilot` loop notifies you, run in the dev terminal:

```
/rranauro:review-copilot <PR#>
```

Walks Copilot's comments one by one — you decide which to apply, which to skip. Skipped comments are recorded in the eventual commit body so the "we considered this" trail is durable in git history.

### 10. Push and finalize — `/rranauro:update-main-pr <PR-URL>`

```
/rranauro:update-main-pr <PR-URL>
```

Runs rubocop on changed Ruby files, runs targeted RSpec, pushes the branch, and posts a "what changed" comment on the PR. Then:

- Restart `/loop 90s /rranauro:wait-copilot <PR#>` to wait for the next Copilot pass.
- Wait for CI to go green.
- `gh pr ready <PR#>` to flip out of draft for human review.

## Cleanup (after merge)

- `/rranauro:cleanup-worktree` from the dev worktree.
- `/rranauro:cleanup-worktree` from the review worktree.
- Periodically: `/rranauro:worktree-gc` to sweep merged-branch worktrees and delete their branches.

## Command map

**`rranauro` plugin (this one):**

| Command | Purpose |
|---------|---------|
| `/rranauro:architect` | Plan the work conversationally |
| `/rranauro:start-ticket` | Set up dev worktree from a ticket |
| `/rranauro:restart-ticket` | Resume an in-progress ticket — assess state, update plan |
| `/rranauro:new-pull-request` | Personal PR variant (Closes #N, auto-starts wait-copilot loop) |
| `/rranauro:wait-copilot` | Poll for Copilot's review |
| `/rranauro:start-review` | Independent review in a separate worktree |
| `/rranauro:review-copilot` | Walk Copilot comments and decide |
| `/rranauro:review-feedback` | Address human-reviewer feedback on a PR |
| `/rranauro:update-main-pr` | Lint, push, comment on the PR |
| `/rranauro:cleanup-worktree` | Remove a worktree after PR merges |
| `/rranauro:worktree-gc` | Sweep all merged-branch worktrees |

**`rx` plugin (team-shared, used in this workflow):**

| Command | Purpose |
|---------|---------|
| `/rx:commit` | Multi-commit splitting and message drafting |
| `/rx:pr` | Create the draft PR |

## Why two terminals + worktrees?

The dev terminal owns the feature branch; the review terminal owns a clean checkout of the same PR's head branch. Worktrees mean both sessions have a real working directory and an independent Rails server (via `rx-serve`). The review never fights with your in-progress edits, and applying review feedback is just file-paths-and-line-numbers from a known artifact.

## Tips

- Keep the dev terminal's working tree clean before starting `/rranauro:start-review` — uncommitted changes there make the review picture noisy.
- `/rranauro:architect` is conversational by design. If the approach changes mid-discussion, just say so — the plan file gets updated when you converge.
- The review file at `rx/tmp/reviews/pr-<PR#>/claude-review.md` is the cross-terminal handoff. If you change PR# (e.g., reopen as new PR), rename or rerun.
