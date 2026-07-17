---
description: Fetches actionable review comments on a PR from all authors — human and automated — skipping resolved and outdated ones, and addresses them one at a time.
args: Optional GitHub PR URL
---

# PR Comment Check

Same as `pr-copilot-check`, but covers review comments from **every** author — humans and other automations (Copilot, linters, security bots, etc.) — not just Copilot.

## Resolving What to Check

Determine the target PR in this order:

1. **URL provided as args** — use it directly.
2. **No URL** — check context: run `git branch --show-current` and look up the open PR for that branch with `gh pr view --json url`.
3. **No open PR found** — ask the user: "Which PR URL should I check for comments?"

## Fetching Actionable Comments

Only actionable comments are in scope. A comment is actionable when its thread is **neither resolved nor outdated** — skip anything already resolved (someone acted on it) and anything outdated (the code it pointed at has since changed). Neither state is exposed by the REST `pulls/{number}/comments` endpoint; both live on GraphQL review threads (`isResolved`, `isOutdated`). Fetch review threads with both flags:

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

Keep every thread where **`isResolved` is `false` and `isOutdated` is `false`**, regardless of who authored it. Do **not** filter by author — human reviewers and automations are all in scope. Ignore resolved or outdated threads entirely.

This covers inline review-thread comments — resolve/outdated state exists only on those.

### Top-Level Conversation Comments

Also include top-level PR conversation comments (issue comments), which have no resolution state. The rule here: **include them only when you (Mike) were not the last person to respond.** If your most recent comment is the newest one in the conversation, you've already replied to everything — treat the top-level thread as fully handled and include nothing from it.

1. Get your own GitHub login: `gh api user --jq '.login'`.
2. Fetch top-level comments in chronological order: `gh pr view {url} --json comments`.
3. Find your most recent comment (latest `createdAt` where `author.login` is your login).
4. Include every top-level comment posted **after** your last one. If you never commented, include all of them. If your comment is the newest, include none.

Merge these into the actionable set alongside the unresolved/non-outdated review threads.

**If no actionable comments are found** — tell the user: "No actionable comments found on this PR." Stop there.

## Addressing Comments

Present the first actionable comment and start a conversation:

1. Show a progress marker: **Comment 1/N** (where N is the total count of actionable comments found)
2. Show the comment: author, the file path and line for inline review comments (omit for top-level conversation comments), and the comment body
3. Share a brief read on what the comment is flagging — no fixes yet
4. Wait for the user to respond — they may agree, disagree, want to discuss, or propose an alternative
5. Once the user confirms a solution, implement it
6. Then ask: "Ready for the next comment?" and repeat, incrementing the counter each time (e.g. **Comment 2/N**)

Never apply a fix before the user has explicitly agreed to it.
