# Start Work on an RX Ticket (Worktree-First)

RX-specific `/rranauro:start-ticket`: always creates a git worktree of the scientist
monorepo, symlinks personal/untracked files via the manifest, and hands off
to a new Claude session in the worktree.

**Usage:** `/rranauro:start-ticket <github_issue_url_or_number>`

## Step 1: Read the Ticket

Use the GitHub MCP tools or `gh` CLI to read the full issue. Extract:
- Issue number
- Title
- Full description (body)
- Labels
- Any linked issues or PRs

## Step 2: Clarify Requirements

Present a summary of the ticket to the user, then ask questions about anything:
- Ambiguous or underspecified
- Missing acceptance criteria
- Unclear in scope
- Potentially conflicting with existing behavior

**Wait for the user to answer before proceeding.**

## Step 3: Create the Worktree

The scientist repo root is `/Users/ron/dev/scientist/`. Worktrees are placed
as siblings to `rx/` inside it (the `rx-*` pattern is already in
`.git/info/exclude`).

```bash
cd /Users/ron/dev/scientist
git fetch origin main
git worktree add ./rx-<issue_number>-<short-description> \
  -b <issue_number>-<short-description> origin/main
~/bin/rx-worktree-init ./rx-<issue_number>-<short-description>
```

- Branch name: `<issue_number>-<short-description>` (kebab-case)
- Example: `rx-34500-add-bulk-export-button`

Then tell the user:
- Worktree is at `/Users/ron/dev/scientist/rx-<issue>-<slug>/`
- To work there: open a new terminal, `cd /Users/ron/dev/scientist/rx-<issue>-<slug>/rx`, run `claude`
- To boot the app: `~/bin/rx-serve start` from the worktree root (not the `rx/` subdir). It will prompt if a server is already running in another worktree and show any migrations that differ.
- The current session is for planning only — hand off implementation to the new session.

## Step 4: Create or Adopt a Plan

Because `rx/plans/` is symlinked across all worktrees via the manifest, plan
files are always visible from the home worktree and every active worktree.

**First check `rx/plans/`** for an existing file matching the issue number
(e.g. `rx/plans/34500-*.md`). `/rranauro:architect` may have written one already.

**If an existing plan file is found:**
1. Read it and present it to the user
2. Ask whether it needs updates (add `Resolves #<issue>`, testing strategy, etc.)
3. Rename to `rx/plans/<issue_number>-<short-description>.md` if it doesn't already follow the convention
4. Apply any agreed changes

**Otherwise create one** at `rx/plans/<issue_number>-<short-description>.md`:

```markdown
# <Issue Title>

Resolves #<issue_number>

## Context
[Brief summary of the problem and what needs to change]

## Approach
[High-level strategy]

## Steps
1. [ ] [First concrete step]
2. [ ] ...

## Files to Modify
- `path/to/file.rb` - [what changes]

## Testing Strategy
- [How to verify the changes work]
- [Key test cases to write]

## Open Questions
- [Any remaining uncertainties]
```

**Present the plan and wait for confirmation before any implementation work.**

## Important Notes

- **Do NOT start coding** until the user confirms the plan
- **Search `rx/docs/`** for relevant documentation before writing the plan
- **Search the codebase** for existing patterns
- **Keep the plan focused** — avoid scope creep beyond the ticket
- **One server at a time**: `rx-serve` enforces this across worktrees. If switching to a worktree that lacks migrations the running server has applied, it will warn and prompt.
