# Batch PR RuboCop Fix Workflow

## Context

This workflow is used when a cron job scans `scientist-hq/rx` and `scientist-hq/benchmate` (or other repos) hourly for PRs with failing rubocop checks, then fixes them automatically.

## Cron Job Setup

```
Schedule: every 1h
Repos: scientist-hq/rx, scientist-hq/benchmate
Skill dependencies: fix-rubocop, claude-code, github-pr-workflow
Toolsets: terminal, file, web
Deliver: origin (same channel that triggered it)
```

## Repo Checkout Locations

| Repo | Local path | RuboCop root |
|------|-----------|--------------|
| scientist-hq/rx | ~/src/rx | ~/src/rx/rx/ (monorepo — Rails app is in rx/ subdir) |
| scientist-hq/benchmate | ~/src/benchmate | ~/src/benchmate/ (repo root) |

## Identifying Failing PRs

```bash
# List open PRs with check status
gh pr list --repo scientist-hq/rx --state open \
  --json number,headRefName,statusCheckRollup,author

# Filter for rubocop failures (jq)
... | jq '[.[] | select(.statusCheckRollup[]? | 
  (.name | test("rubocop|lint"; "i")) and .conclusion == "FAILURE")]'
```

### Skip conditions
- `conclusion` is empty or `status` is `IN_PROGRESS` → CI still running
- `statusCheckRollup` is `[]` → CI not triggered; can't determine failure
- `conclusion` is `SUCCESS` → already passing

## Worktree Pattern

```bash
cd ~/src/<repo>
git fetch origin <branch> <base_branch>
git worktree add /tmp/<repo>-<pr_number> origin/<branch>
cd /tmp/<repo>-<pr_number>
git checkout -b <branch> origin/<branch>
# ... do fixes ...
git push origin <branch>
cd ~/src/<repo>
git worktree remove /tmp/<repo>-<pr_number>
```

## Commit Attribution

- Author: `BigMac <57731843+scientist-service@users.noreply.github.com>`
- Co-author trailer: the PR author's GitHub noreply email
- Message format: `Fix RuboCop offenses in <brief description of area>`

## Lessons Learned (2026-05)

1. **Metrics offenses on `def` lines**: When a branch adds lines inside a method body pushing it over `Metrics/MethodLength` or `Metrics/AbcSize`, the offense reports on the `def` line which the branch may not have literally changed. Still treat as in-scope — the branch caused it.

2. **Fix strategy for Metrics**: Extract a well-named private helper method. The extracted method should have a descriptive comment and carry the block/yield pattern through if the original used one.

3. **Pre-existing offenses**: Always document them in the summary so the PR author or reviewer knows they exist but were deliberately left alone.
