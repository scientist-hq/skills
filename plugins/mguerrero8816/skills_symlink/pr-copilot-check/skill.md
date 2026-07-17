---
description: Fetches actionable GitHub Copilot review comments on a PR — skipping resolved and outdated ones — and addresses them one at a time.
args: Optional GitHub PR URL
---

# PR Copilot Check

## Resolving What to Check

Determine the target PR in this order:

1. **URL provided as args** — use it directly.
2. **No URL** — check context: run `git branch --show-current` and look up the open PR for that branch with `gh pr view --json url`.
3. **No open PR found** — ask the user: "Which PR URL should I check for Copilot comments?"

## Fetching Actionable Copilot Comments

Only actionable Copilot comments are in scope. A comment is actionable when its thread is **neither resolved nor outdated** — skip anything already resolved (the author acted on it) and anything outdated (the code it pointed at has since changed). Neither state is exposed by the REST `pulls/{number}/comments` endpoint; both live on GraphQL review threads (`isResolved`, `isOutdated`). Fetch review threads with both flags:

```
gh api graphql -f query='
{
  repository(owner: "{owner}", name: "{repo}") {
    pullRequest(number: {number}) {
      reviewThreads(first: 100) {
        nodes {
          isResolved
          isOutdated
          comments(first: 100) {
            nodes {
              author { login }
              body
              path
              line
            }
          }
        }
      }
    }
  }
}'
```

Keep only threads where **`isResolved` is `false` and `isOutdated` is `false`** and at least one comment's `author.login` matches `copilot-pull-request-reviewer[bot]` or contains `copilot`. Ignore resolved or outdated threads entirely, even if Copilot authored them.

**If no actionable Copilot comments are found** — tell the user: "No actionable Copilot comments found on this PR." Stop there.

## Addressing Comments

Present the first actionable Copilot comment and start a conversation:

1. Show a progress marker: **Comment 1/N** (where N is the total count of actionable Copilot comments found)
2. Show the comment: file path, line, and the comment body
3. Share a brief read on what Copilot is flagging — no fixes yet
3. Wait for the user to respond — they may agree, disagree, want to discuss, or propose an alternative
4. Once the user confirms a solution, implement it
5. Then ask: "Ready for the next comment?" and repeat, incrementing the counter each time (e.g. **Comment 2/N**)

Never apply a fix before the user has explicitly agreed to it.
