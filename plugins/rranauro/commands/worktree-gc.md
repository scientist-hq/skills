# Garbage Collect Merged Worktrees

This command removes git worktrees whose branches have already been merged into main,
and sweeps directories git no longer tracks.

**Usage:** `/rranauro:worktree-gc`

All worktrees live under `{{repo.worktree_root}}/`. That directory holds nothing else,
so anything in it that git doesn't list is garbage (Step 6).

## Step 1: List All Worktrees

```bash
git worktree list
ls -1 {{repo.worktree_root}}/
```

Identify all worktrees that are not the main worktree (the primary checkout). Note the path and branch for each. Keep the `ls` output — Step 6 diffs it against `git worktree list`.

## Step 2: Find Merged Branches

```bash
git fetch origin main
git branch --merged origin/main
```

Cross-reference the worktree list against branches already merged into `origin/main`.

## Step 3: Present Candidates for Removal

Show the user a table of worktrees eligible for removal:

```
Path                                    Branch                        Status
-------------------------------         ----------------------------  --------
worktrees/<repo>-123-fix-search         123-fix-search                merged
worktrees/<repo>-456-update-exports     456-update-exports            merged
```

Also list any worktrees whose branches are **not** merged, so the user has a full picture:

```
Path                                    Branch                        Status
-------------------------------         ----------------------------  --------
worktrees/<repo>-789-new-feature        789-new-feature               unmerged
```

**Ask the user to confirm** before removing anything:

> "Found N worktree(s) with merged branches. Remove all of them, or would you like to choose individually?"

## Step 4: Remove Confirmed Worktrees

For each worktree the user approves, run:

```bash
git worktree remove <path>
git branch -D <branch>
```

- Use `git worktree remove` (not `rm -rf`) so git updates its internal tracking
- Use `git branch -D` (force delete — `-d` almost never succeeds in practice due to tracking ref mismatches)
- Report success or any errors for each removal

## Step 5: Prune Stale References

After removals, clean up any stale worktree admin files:

```bash
git worktree prune
```

## Step 6: Sweep Orphan Directories

`git worktree remove` deletes only tracked files — untracked paths (`tmp/`, build
output, a copied `Procfile`, `node_modules`) survive, and `git worktree prune` cleans
git's admin files without touching directories. So a removed worktree routinely leaves
a husk on disk that nothing ever notices. Same for worktrees removed by hand with
`rm -rf` outside this command.

Re-list both sides and diff them:

```bash
git worktree list
ls -1 {{repo.worktree_root}}/
```

Any directory in `{{repo.worktree_root}}/` that `git worktree list` does **not** name is
an orphan. For each, show the user the path and its size (`du -sh <path>`), then ask
before deleting:

> "Found N orphan director(ies) in `{{repo.worktree_root}}/` that git no longer tracks. Delete them?"

On approval:

```bash
rm -rf {{repo.worktree_root}}/<orphan>
```

Never skip this step because Steps 1–5 found nothing to remove — orphans accumulate
from *past* runs and from manual cleanups, so the sweep is the point of the command as
much as the merged-branch check is.

Report a final summary: worktrees removed, branches deleted, orphans swept (with
reclaimed size).

## Important Notes

- **Never remove the main worktree** (the primary repo directory)
- **Always confirm with the user** before deleting — don't auto-delete even if all are merged
- **`-D` for branch delete** — `-d` rarely succeeds due to tracking ref mismatches even on merged branches
- If `git worktree remove` fails because the worktree has uncommitted changes, report it and skip rather than forcing
- **Only `rm -rf` inside `{{repo.worktree_root}}/`** — that directory holds nothing but worktrees, which is what makes the Step 6 diff safe. Never extend the sweep to `{{repo.workspace_root}}/`, where real tracked directories share the worktree naming prefix
