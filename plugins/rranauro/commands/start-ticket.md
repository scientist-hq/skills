# Start Work on a Ticket (Worktree-First)


> **Profile first.** Before anything project-specific, read the dev-suite
> profile ([PROFILE.md](../PROFILE.md)): `<project>/.claude/dev-suite.json`,
> then `~/.claude/dev-suite.json`. Backticked keys (`repo.slug`,
> `commands.test`, …) and `{{placeholders}}` below refer to it. Detect from
> `git`/`gh` what the profile doesn't set; if an optional command is unset,
> skip that step and say so — never guess a stack-specific command.

`/rranauro:start-ticket`: always creates a git worktree of the project's main checkout
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

Then tell the user:
- Worktree is at `{{repo.worktree_root}}/{{repo.worktree_prefix}}-<issue>-<slug>/`
- To work there: open a new terminal, `cd {{repo.worktree_root}}/{{repo.worktree_prefix}}-<issue>-<slug>/{{repo.app_subdir}}`, run `claude`
- To boot the app: `{{commands.serve}} start` from the worktree root (not the {{repo.app_subdir}} subdir). It will prompt if a server is already running in another worktree and show any migrations that differ.
- The current session is for planning only — hand off implementation to the new session.

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

**Present the plan and wait for confirmation before any implementation work.**

## Important Notes

- **Do NOT start coding** until the user confirms the plan
- **Search the project's docs directory** for relevant documentation before writing the plan
- **Search the codebase** for existing patterns
- **Keep the plan focused** — avoid scope creep beyond the ticket
- **One server at a time**: `{{commands.serve}}` enforces this across worktrees. If switching to a worktree that lacks migrations the running server has applied, it will warn and prompt.
