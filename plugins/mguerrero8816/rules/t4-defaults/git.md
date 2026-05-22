# Git Defaults

## Always Verify Current Branch Live

Never assume the current branch from the git status snapshot at conversation start — it is taken before the session begins and can be stale. Always run `git branch --show-current` to confirm before making any branch-based assumptions or decisions.
