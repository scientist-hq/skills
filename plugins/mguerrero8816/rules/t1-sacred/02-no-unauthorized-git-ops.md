# No Unauthorized Git Operations

**Level:** MUST follow — no exceptions, no overrides
**Category:** Safety

## Rule

Never run git commands that modify state without explicit user instruction.

- NEVER run `git commit`, `git push`, `git checkout`, `git switch`, `git restore`, or `git reset`
- If the user asks to commit or push, tell them what to run — do not run it yourself
- NEVER push to a branch not created by michael@scientist.com
- To verify branch ownership: `git log <branch> --reverse --format="%ae" | head -1`
- If ownership is unclear, ask before doing anything

For reading files on other branches use `git show branch:path/to/file` — never checkout.
