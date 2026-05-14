# Review Feedback

Address reviewer feedback on a pull request by understanding the PR context, the associated ticket, and the reviewer's comments, then proposing changes.

**Usage:** `/rranauro:review-feedback <github_pr_url>`

## Step 1: Read the PR and Associated Ticket

Use the GitHub MCP tools or `gh` CLI to get the PR details from the provided URL. Extract:
- Head branch name and base branch
- PR title, number, author, labels
- Full PR description (body)
- If the description references a closing issue (e.g., "Closes #1234", "Resolves #1234"), read that issue too to understand the original requirements and acceptance criteria

## Step 2: Read the Latest Review Comments

Fetch all review comments and conversation comments on the PR. Focus on:
- The most recent review round (latest comments from reviewers)
- Inline code comments with specific file/line references
- General PR-level comments with feedback or change requests
- The review verdict (approved, changes requested, commented)

Summarize the reviewer's feedback clearly.

## Step 3: Checkout the Branch Locally

First check for uncommitted changes — stash or warn if present.

```bash
git fetch origin
```

If the branch exists locally:
```bash
git checkout <head_branch>
git pull origin <head_branch>
```

If the branch does not exist locally:
```bash
git checkout -b <head_branch> origin/<head_branch>
```

Also fetch the latest base branch for diff context:
```bash
git fetch origin <base_branch>
```

## Step 4: Understand the Changes

- Get the diff: `git diff <base_branch>...HEAD`
- Get files changed: `git diff <base_branch>...HEAD --stat`
- Read the changed files in full to understand surrounding context (not just the diff lines)
- Cross-reference the changes with the original ticket requirements

## Step 5: Confirm Understanding

Present to the user:
1. **Ticket summary** — what was originally requested
2. **PR summary** — what the current changes do
3. **Reviewer feedback** — each piece of feedback summarized with file/line references where applicable
4. **Proposed approach** — for each piece of feedback, suggest how to address it (agree, disagree with rationale, or need clarification)

**Wait for the user to confirm or adjust the approach before making any code changes.**

## Important Notes

- Do NOT modify any code until the user confirms the approach
- Do NOT post comments on GitHub unless asked
- If reviewer feedback conflicts with the original ticket requirements, flag this for the user
- If feedback is ambiguous, present your interpretation and ask the user to confirm
- Focus on understanding intent — sometimes reviewer comments suggest one thing but mean another
