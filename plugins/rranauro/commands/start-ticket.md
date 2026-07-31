# Start Work on a Ticket (Worktree-First)


> **Profile first.** Before anything project-specific, read the dev-suite
> profile ([PROFILE.md](../PROFILE.md)): `<project>/.claude/dev-suite.json`,
> then `~/.claude/dev-suite.json`. Backticked keys (`repo.slug`,
> `commands.test`, …) and `{{placeholders}}` below refer to it. Detect from
> `git`/`gh` what the profile doesn't set; if an optional command is unset,
> skip that step and say so — never guess a stack-specific command.

`/rranauro:start-ticket`: creates a git worktree of the project's main checkout,
symlinks personal/untracked files via the manifest, then **plans and implements the
ticket in this session**, with every file change made under the worktree path.

**Usage:** `/rranauro:start-ticket <github_issue_url_or_number>`

## Step 0: Locate Yourself

Run `git rev-parse --show-toplevel` and `git branch --show-current` before anything
else. Three cases:

- **Home checkout** (`{{repo.workspace_root}}`) — the normal case. Proceed through
  every step below; Step 3 creates the worktree and the rest of this session
  operates on paths inside it.
- **Already in the worktree for this issue** (branch starts with `<issue_number>-`) —
  **skip Step 3 entirely.** Do not create a second worktree and do not hand off.
  Go to Step 4, adopt the existing plan, and continue the work here.
- **In a worktree for a different issue** — stop and say so. Ask whether to start the
  new ticket from the home checkout instead of nesting worktrees.

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

The main checkout root is your home monorepo checkout (default
`{{repo.workspace_root}}/`). Every worktree goes under `{{repo.worktree_root}}/` — one
dedicated directory, git-excluded, holding nothing but worktrees.

```bash
mkdir -p {{repo.worktree_root}}
cd {{repo.workspace_root}}
git fetch origin main
git worktree add {{repo.worktree_root}}/{{repo.worktree_prefix}}-<issue_number>-<short-description> \
  -b <issue_number>-<short-description> origin/main
{{commands.worktree_init}} {{repo.worktree_root}}/{{repo.worktree_prefix}}-<issue_number>-<short-description>
```

- Branch name: `<issue_number>-<short-description>` (kebab-case)
- Example: `{{repo.worktree_prefix}}-34500-add-bulk-export-button`

**Stay in this session.** The worktree is a filesystem location, not a reason to start
over somewhere else. From here on, every path you read, edit, or run a command in is
under `{{repo.worktree_root}}/{{repo.worktree_prefix}}-<issue>-<slug>/`. Never edit the
home checkout's working tree for this ticket.

Then tell the user:
- Worktree is at `{{repo.worktree_root}}/{{repo.worktree_prefix}}-<issue>-<slug>/`
- Implementation continues in this session, against that path
- To boot the app: `{{commands.serve}} start` from the worktree root (not the {{repo.app_subdir}} subdir). It will prompt if a server is already running in another worktree and show any migrations that differ.
- Optional: a second terminal (`cd <worktree>/{{repo.app_subdir}}`, `claude`) is only useful for parallel work — it is not required, and this session should not wait on one.

## Step 4: Create or Adopt a Plan

Because `{{paths.plans}}/` is symlinked across all worktrees via the manifest, plan
files are always visible from the home worktree and every active worktree.

**First check `{{paths.plans}}/`** for an existing file matching the issue number
(e.g. `{{paths.plans}}/34500-*.md`). `/rranauro:architect` may have written one already.

**If an existing plan file is found:**
1. Read it and present it to the user
2. Ask whether it needs updates (add `Resolves #<issue>`, testing strategy, etc.)
3. Rename to `{{paths.plans}}/<issue_number>-<short-description>.md` if it doesn't already follow the convention
4. Apply any agreed changes

**Otherwise create one** at `{{paths.plans}}/<issue_number>-<short-description>.md`:

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

**Present the plan and wait for confirmation.**

## Step 5: Implement

Once the user confirms the plan, **implement it in this session** — work the Steps in
order, against the worktree path from Step 3, committing as each step passes its
specs.

If the user's message already asked for implementation ("implement the plan", "go
ahead"), treat that as the confirmation for a plan they've already seen and start
here. Do not re-present a plan they wrote or approved in an earlier session, and do
not defer the work to another session or terminal.

## Important Notes

- **Do NOT start coding** until the user confirms the plan — this gates on *plan
  approval*, not on which session or terminal you're in
- **Search the project's docs directory** for relevant documentation before writing the plan
- **Search the codebase** for existing patterns
- **Keep the plan focused** — avoid scope creep beyond the ticket
- **One server at a time**: `{{commands.serve}}` enforces this across worktrees. If switching to a worktree that lacks migrations the running server has applied, it will warn and prompt.
