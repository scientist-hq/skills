# Git Defaults

## Never Put `cd` Before a Git Command

Git works on the current tree, and `cd … &&` adds a permission prompt. For another directory, use `git -C /path`.

## Verify the Current Branch Live

The git status at the start of the conversation can be out of date. Run `git branch --show-current` before any decision that depends on the branch.

## Check Before You State Commit or Working-Tree State

Mike commits and pushes during the session, and you cannot see it. Never say that something is committed, uncommitted, staged, stashed, pushed, or clean unless you ran `git status` or `git log` in the same turn.

- This includes indirect forms, such as "your changes are still local" or "you'll need to commit this".
- If the state does not matter to the answer, leave it out.
- Before you suggest a commit, stash, or branch move, run `git status --short`.

- ❌ BAD: "The fix is sitting on `p3`, uncommitted." (no check run)
- ✅ GOOD: run `git status --short; git log --oneline -1`, then "`7c241b9e15 preventing early db writes` is committed and the tree is clean."
