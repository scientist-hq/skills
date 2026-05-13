You are writing a brief daily recap entry for the team standup. Your goal is to capture what was accomplished in this session so it can be recalled the next morning.

## Output File

Determine the recap directory by running: `echo ~/.claude/projects/$(pwd | tr '/' '-')/recaps/`

Append to `<recap_directory>/YYYY-MM-DD.md` (using today's date). Create the directory and file with a header if they don't exist yet.

## Format

The file has three sections: a **summary list** at the top, a **pipeline tracker**, and **detailed entries** below.

```markdown
# Recap — YYYY-MM-DD

- One-line summary of entry 1
- One-line summary of entry 2
- ...

## Pipeline

| PR | Role | Status | main | staging | prod |
|----|------|--------|------|---------|------|
| repo#123 — short title | author | Merged | :white_check_mark: | :hourglass: | :hourglass: |
| repo#456 — short title | reviewer | Open PR | :x: | :x: | :x: |

---

### HH:MM — <short title>

**Status:** <Merged | Open PR | WIP | Blocked | Investigating>

<2-4 bullet points covering: what was done, key decisions, any blockers or handoffs>

**Links:** <PR URLs, issue URLs, or "n/a">
```

When appending a new entry:
1. Add a one-line summary bullet to the list between the `# Recap` header and the `## Pipeline` section
2. Update the Pipeline table if the entry involves a PR (add a new row or update an existing one)
3. Append the full detailed entry at the bottom of the file

### Pipeline Table Rules

The pipeline tracks PRs through the deployment stages: **main** → **staging** → **prod**.

- Use `:white_check_mark:` when the PR has reached that environment
- Use `:hourglass:` when the PR is waiting to reach that environment (a prior stage is complete)
- Use `:x:` when the PR hasn't reached that stage yet (prior stage not complete)
- When a PR is merged to main: `main` = :white_check_mark:, `staging` = :hourglass:, `prod` = :hourglass:
- When main is merged to staging: update `staging` = :white_check_mark:, `prod` = :hourglass:
- When staging is merged to prod: update `prod` = :white_check_mark:
- Non-PR entries (investigations, reviews, etc.) don't appear in the pipeline table
- Remove rows from the pipeline table once all three stages show :white_check_mark: AND 2+ days have passed

### Role Column

Track the user's role on each PR — this changes what actions matter:

- **author** — user wrote the PR. Action items: address review feedback, get approvals, track deployment
- **reviewer** — user is reviewing someone else's PR. Action items: re-review when author pushes fixes, approve/merge

To determine the role, check the PR author via `gh pr view --json author` and the current user via `gh api user --jq '.login'`. If the author matches the current user, role = "author". Otherwise, role = "reviewer".

Role affects status labels:
- **Author + CHANGES_REQUESTED (all threads resolved)**: "Awaiting re-approval" — ball is in reviewer's court
- **Author + CHANGES_REQUESTED (unresolved threads)**: "Changes requested" — ball is in your court
- **Reviewer + you submitted CHANGES_REQUESTED**: "Waiting on author" — ball is in their court until they push fixes
- **Reviewer + author pushed after your review**: "Needs re-review" — ball is back in your court

To check deployment status, use:
```
gh api repos/{owner}/{repo}/compare/{branch}...main --jq '.status' # check if merged to main
gh api repos/{owner}/{repo}/compare/staging...main --jq '.ahead_by' # check if main is ahead of staging
gh api repos/{owner}/{repo}/compare/production...staging --jq '.ahead_by' # check if staging is ahead of prod
```

Also check if the PR's merge commit exists on staging/production branches:
```
git ls-remote origin staging production # get branch SHAs
gh api repos/{owner}/{repo}/compare/{staging_sha}...{merge_commit_sha} --jq '.status' # "identical" or "behind" means it's deployed
```

## Update Mode

When `$ARGUMENTS` is `update` (i.e., `/recap update`):

**Do NOT add a new entry.** Instead, refresh and consolidate the existing file:

### Step 1: Consolidate duplicate entries

Before checking statuses, merge entries that represent continued work on the same PR or issue:

1. **Scan all detailed entries** — group by PR/issue identifier (e.g., `open-api#90`, `benchmate#687`) found in `**Links:**` sections and entry titles
2. **For entries sharing a PR/issue**, merge into one:
   - Use the **earliest timestamp** as the entry time
   - Combine the title to reflect the full scope (e.g., "QA + test coverage: open-api PR #90")
   - Merge bullet points from all entries, removing redundancy — preserve chronological order
   - Keep the **latest status** (most recent is most accurate)
   - Combine all Links, deduplicating
3. **Update the summary list** — one bullet per consolidated entry instead of multiple
4. **Only merge entries that represent continued work on the same thing** — a review and an unrelated investigation that happen to mention the same PR in passing should NOT be merged

### Step 2: Refresh statuses

1. Find all GitHub PR URLs in the file (in `**Links:**` sections)
2. Check each PR's current status with:
   ```
   gh pr view <number> --repo <owner/repo> --json state,mergedAt,mergedBy,reviews
   ```
3. **For `CHANGES_REQUESTED` reviews**, check if feedback was actually addressed using the GraphQL API:
   ```
   gh api graphql -f query='{
     repository(owner: "<owner>", name: "<repo>") {
       pullRequest(number: <number>) {
         reviewThreads(first: 50) {
           nodes {
             isResolved
             isOutdated
             comments(first: 1) {
               nodes { author { login } body }
             }
           }
         }
       }
     }
   }'
   ```
   - If **all threads** have `isResolved: true` → feedback addressed, just needs re-approval. Status = "Open (awaiting re-approval)"
   - If **any thread** has `isResolved: false` AND `isOutdated: false` → feedback still outstanding. Status = "Open (changes requested)"
   - `isOutdated: true` means the code under the comment changed (strong signal it was addressed)
   - **Do NOT say "changes requested" if all threads are resolved** — that implies the author hasn't acted on them
4. Update the **Status:** line in each detailed entry if the PR status has changed (e.g., "Open PR" → "Merged")
5. When a PR has been merged, note who merged it and who reviewed/approved it (e.g., "Merged by @mumenmusa, reviewed by @xrl")
6. **Update the Pipeline table** — check if merged PRs have reached staging and/or production using the deployment status commands above
7. Regenerate the summary bullet list at the top to reflect current statuses
8. Show the user what changed (including which entries were consolidated)

## Todo Mode

When `$ARGUMENTS` is `todo` (i.e., `/recap todo`):

**Do NOT add a new entry.** Instead, generate a focused next-day todo list.

1. **Read recent recap files** — today's and the previous 1-2 days (check what's still in-flight)
2. **Check all PR statuses** via `gh pr view` for every PR referenced in recent recaps
3. **Check the pipeline** — which PRs have been merged but haven't hit staging or prod yet?
4. **Generate the todo list** based on priority:

Priority order:
- **Blocked items** that may have been unblocked (check if the blocker has been resolved)
- **Open PRs** needing action — based on role:
  - **Author PRs**: address review comments, get approvals, rebase if needed
  - **Reviewer PRs**: re-review if author pushed fixes, otherwise skip (waiting on them)
- **Pipeline items** — PRs merged to main that need a staging deploy, or on staging that need prod deploy
- **Investigations** or threads that need follow-up (e.g., waiting on someone's response)
- **WIP items** that need to be finished

5. **Write the todo to the recap file** — append a `## Todo — YYYY-MM-DD` section at the bottom:

```markdown
## Todo — YYYY-MM-DD

### Must do
- [ ] Address review comments on open-api PR #90 (provider_name refactor)
- [ ] Follow up with @xrl on AWS permissions for infra PR #155

### Deploy tracking
- [ ] Verify rx#34961 (taxonomy related services) is on staging
- [ ] Push staging → prod if taxonomy services looks good

### Follow up
- [ ] Check if Diana responded on AI Insights supplier quality thread
```

6. **Show the user** — display the todo list so they can adjust priorities

### Todo Rules
- **Only actionable items** — no "keep an eye on" or "think about"
- **Group by urgency** — "Must do" (blocks others or is time-sensitive), "Deploy tracking" (pipeline items), "Follow up" (waiting on others)
- **Include context** — PR numbers, people's names, brief reason why
- **Skip completed items** — if a PR is fully deployed to prod, it doesn't need a todo
- **Be realistic** — aim for a list that fits in a morning, not an entire sprint

## Rules

- **Be concise** — the whole day's file should be readable in under 5 minutes
- **Focus on outcomes** — what changed, what's blocked, what needs follow-up
- **Include links** — PRs, issues, or commits so the team can find the work
- **Name people** — if something was handed off or is waiting on someone, say who
- **No filler** — skip boilerplate like "worked on" or "spent time on"
- **Multiple sessions** — each `/recap` call appends a new entry, never overwrites previous ones (except in update/todo mode)

## Workflow

### Default (new entry)
1. **Review the conversation** — look at what was discussed, coded, committed, or investigated
2. **Identify the key items** — group by topic if multiple things were done
3. **Check for PRs/commits** — run `git log --oneline -5` and check for any PR URLs mentioned in the conversation
4. **Write the entry** — append to the recap file, update the pipeline table if PRs are involved
5. **Show the user** — display what was written so they can adjust if needed

### Update mode (`/recap update`)
1. **Read today's recap file**
2. **Consolidate duplicate entries** — merge entries for the same PR/issue into one
3. **Check all PR statuses** via `gh pr view`
4. **Check pipeline deployment status** for merged PRs
5. **Update statuses** in both summary list, pipeline table, and detailed entries, including who reviewed and merged
6. **Show the user** what changed (including which entries were consolidated)

### Todo mode (`/recap todo`)
1. **Read recent recap files** (today + previous 1-2 days)
2. **Check all PR statuses** and pipeline positions
3. **Generate prioritized todo list**
4. **Append to today's recap file**
5. **Show the user** the todo list

## Getting Started

Context: $ARGUMENTS
