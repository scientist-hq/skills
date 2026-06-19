---
description: Fetches GitHub Copilot review comments on a PR and addresses them one at a time.
args: Optional GitHub PR URL
---

# PR Copilot Check

## Resolving What to Check

Determine the target PR in this order:

1. **URL provided as args** — use it directly.
2. **No URL** — check context: run `git branch --show-current` and look up the open PR for that branch with `gh pr view --json url`.
3. **No open PR found** — ask the user: "Which PR URL should I check for Copilot comments?"

## Fetching Copilot Comments

Once the PR is resolved, fetch all review comments and filter to those authored by Copilot:

```
gh api repos/{owner}/{repo}/pulls/{number}/comments --paginate
```

Filter results where `user.login` matches `copilot-pull-request-reviewer[bot]` or contains `copilot`.

Also check top-level reviews:

```
gh pr view {url} --json reviews
```

Filter reviews where the author login matches the same pattern.

**If no Copilot comments are found** — tell the user: "No Copilot comments found on this PR." Stop there.

## Addressing Comments

Present the first Copilot comment and start a conversation:

1. Show a progress marker: **Comment 1/N** (where N is the total count of Copilot comments found)
2. Show the comment: file path, line, and the comment body
3. Share a brief read on what Copilot is flagging — no fixes yet
3. Wait for the user to respond — they may agree, disagree, want to discuss, or propose an alternative
4. Once the user confirms a solution, implement it
5. Then ask: "Ready for the next comment?" and repeat, incrementing the counter each time (e.g. **Comment 2/N**)

Never apply a fix before the user has explicitly agreed to it.
