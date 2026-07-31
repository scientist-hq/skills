> **Profile first.** Before anything project-specific, read the dev-suite
> profile ([PROFILE.md](../PROFILE.md)): `<project>/.claude/dev-suite.json`,
> then `~/.claude/dev-suite.json`. Backticked keys (`repo.slug`,
> `commands.test`, …) and `{{placeholders}}` below refer to it. Detect from
> `git`/`gh` what the profile doesn't set; if an optional command is unset,
> skip that step and say so — never guess a stack-specific command.

Clean up a feature-branch worktree after its PR has been merged on GitHub.

**Arguments:** $ARGUMENTS
Optional: a branch name, worktree path, or PR number. If omitted, infer from the current branch.

This command targets the worktree case from `/rranauro:start-ticket`, which creates worktrees under `{{repo.worktree_root}}/{{repo.worktree_prefix}}-<branch-name>/` (e.g. `{{repo.worktree_root}}/{{repo.worktree_prefix}}-34500-add-bulk-export-button/`). If the branch was bundled onto an existing worktree instead of getting its own, only Step 6's branch deletion applies — no worktree to remove.

**Step 1 — Resolve the target:**
- If `$ARGUMENTS` is a PR number: `gh pr view <num> --json headRefName,state,mergedAt` and take `headRefName` as the branch.
- If `$ARGUMENTS` is a branch name: use it directly.
- If `$ARGUMENTS` is a path: derive the branch from `git worktree list`.
- If empty: use the current branch (`git branch --show-current`). If that's `main`, ask the user which worktree to clean up.

Confirm the worktree path via `git worktree list` — it should be under `{{repo.worktree_root}}/{{repo.worktree_prefix}}-<branch-name>/`. If it isn't listed there, surface what you found and ask the user before proceeding.

**Step 2 — Verify the PR is merged:**
- `gh pr view <branch-name> --json state,mergedAt,url,number`
- If state is not `MERGED`, STOP and warn the user. Do not clean up unmerged work.
- If no PR exists for the branch, STOP and ask the user before proceeding — the work may not be intended for cleanup.

**Step 3 — Verify the worktree has no uncommitted work:**
- `git -C {{repo.worktree_root}}/{{repo.worktree_prefix}}-<branch-name> status --porcelain`
- If output is non-empty, STOP and report what's outstanding. Do NOT pass `--force` to `git worktree remove`; ask the user how to handle the leftovers.

**Step 4 — Confirm the branch isn't active elsewhere:**
- Ask the user explicitly: "Is `<branch-name>` checked out in another terminal, IDE, or worktree?"
- If yes, STOP. Leave the worktree and branch alone — the user has live work there.

**Step 5 — Remove the worktree (run from the main checkout):**
- `git worktree remove {{repo.worktree_root}}/{{repo.worktree_prefix}}-<branch-name>`
- If the user is currently `cd`'d into the worktree being removed, ask them to switch to the main checkout first; otherwise the remove will fail.
- `git worktree remove` deletes the tracked tree but leaves untracked paths (build output, `tmp/`, copied `Procfile`) behind, and `git worktree prune` never touches directories. So verify and clear the residue:
  - `ls {{repo.worktree_root}}/{{repo.worktree_prefix}}-<branch-name>` — if the directory still exists, `rm -rf` it.
  - Report the removal either way; a silent leftover is what makes these accumulate.

**Step 6 — Sync local main and delete the branch:**
- `git fetch origin main`
- `git branch -d <branch-name>` — `-d` (safe). If git refuses because the branch isn't merged into local main, run `git pull --ff-only origin main` from `main` and retry.
- If git still refuses after pulling, STOP and surface the error. Do NOT auto-escalate to `-D`; that's destructive and requires explicit user approval.

**Step 7 — Prune stale refs:**
- `git worktree prune`
- `git remote prune origin` — cleans up remote-tracking refs for branches GitHub already deleted on merge.

**Step 8 — Report:**
- Summarize for the user: worktree path removed, branch deleted, PR URL and number.
