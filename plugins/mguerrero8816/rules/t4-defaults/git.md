# Git Defaults

## Never Prepend cd to Git Commands

`git` operates on the current working tree — prepending `cd /some/path &&` is never needed and triggers a permission prompt for the compound command.

- ❌ `cd /Users/mike/rx && git diff main...HEAD`
- ✅ `git diff main...HEAD`

## Always Verify Current Branch Live

Never assume the current branch from the git status snapshot at conversation start — it is taken before the session begins and can be stale. Always run `git branch --show-current` to confirm before making any branch-based assumptions or decisions.
