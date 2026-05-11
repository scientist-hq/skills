# Garbage Collect Merged Worktrees

This command removes git worktrees whose branches have already been merged into main.

**Usage:** `/worktree-gc`

## Step 1: List All Worktrees

```bash
git worktree list
```

Identify all worktrees that are not the main worktree (the primary checkout). Note the path and branch for each.

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
../<repo>-123-fix-search                123-fix-search                merged
../<repo>-456-update-exports            456-update-exports            merged
```

Also list any worktrees whose branches are **not** merged, so the user has a full picture:

```
Path                                    Branch                        Status
-------------------------------         ----------------------------  --------
../<repo>-789-new-feature               789-new-feature               unmerged
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

Report a final summary of what was removed.

## Important Notes

- **Never remove the main worktree** (the primary repo directory)
- **Always confirm with the user** before deleting — don't auto-delete even if all are merged
- **`-D` for branch delete** — `-d` rarely succeeds due to tracking ref mismatches even on merged branches
- If `git worktree remove` fails because the worktree has uncommitted changes, report it and skip rather than forcing
