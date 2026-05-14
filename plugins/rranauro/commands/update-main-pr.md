# Update Main Pull Request

This command pushes new changes to an existing pull request and updates its description to reflect the latest state.

**Usage:** `/rranauro:update-main-pr <github_pr_url>`

## Step 1: Pre-Flight Checks

1. Run `git branch --show-current` to verify the current branch
2. Read the existing PR using the GitHub MCP tools or `gh` CLI to get:
   - PR number, title, current body, labels, milestone
   - Head branch name — confirm it matches the current local branch
   - If the branches don't match, STOP and alert the user
3. Check `git status` for uncommitted changes — if present, ask the user whether to commit them first

## Step 2: Run Checks Before Pushing

Run rubocop on changed Ruby files and specs on affected modules:

```bash
# Lint changed Ruby files
bundle exec rubocop $(git diff main...HEAD --name-only -- '*.rb')

# Run specs for affected modules
bundle exec rspec <spec files for changed models/services/controllers>
```

If either check fails, STOP and fix the issues before pushing. Do NOT push code that fails linting or specs.

## Step 3: Push Changes

```bash
git push origin <current_branch>
```

If the push fails (e.g., diverged history), alert the user rather than force-pushing.

## Step 4: Gather Updated Context

1. Commits on branch: `git log main..HEAD --oneline`
2. Files changed: `git diff main...HEAD --stat`
3. Full diff: `git diff main...HEAD`
4. Read the changed files to understand the full scope of changes

## Step 5: Add a Comment to the PR

Do NOT modify the PR description. Instead, add a comment summarizing what changed and any important context for the reviewer.

The comment should include:
- **What changed** — a concise summary of the new commits (what was added, modified, or removed)
- **Why** — context on what motivated the changes (e.g., reviewer feedback, bug found during testing)
- **Notes for reviewer** — anything the reviewer should pay attention to (e.g., "temporary alias that will be replaced by #35001", breaking changes, new dependencies)

```bash
gh pr comment <PR_NUMBER> --body "$(cat <<'EOF'
[Comment body]
EOF
)"
```

## Step 6: Update Labels and Title if Needed

- If the changes now touch new areas (e.g., added backoffice changes to a storefront-only PR), add the appropriate label
- If the PR title no longer accurately describes the work, update it with `gh pr edit <PR_NUMBER> --title "New title"`
- Do NOT remove existing labels unless they're clearly wrong

## Step 7: Summary

Present to the user:
1. Confirmation that changes were pushed
2. The comment that was added to the PR
3. A clickable link to the PR

## Important Notes

- **NEVER force push** — if push fails, alert the user
- **NEVER change the PR out of draft mode** — leave draft status as-is
- **NEVER close, merge, approve, or modify the PR description**
- **Do NOT rewrite the PR description** — use comments to communicate updates
