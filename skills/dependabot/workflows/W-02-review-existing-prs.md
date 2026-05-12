# W-02: Review Existing Dependabot PRs

Before creating new branches, check for PRs Dependabot already created. These are free wins.

## Step 1: List open Dependabot PRs

```bash
gh pr list --repo ORG/REPO --author app/dependabot --state open \
  --json number,title,url --limit 50
```

## Step 2: Verify CI status on each

Don't just list them — check actual CI status:

```bash
gh pr view <number> --repo ORG/REPO \
  --json title,mergeable,statusCheckRollup,additions,deletions,files,reviews \
  | jq '{title, mergeable, additions, deletions,
    files: [.files[].path],
    failing: [.statusCheckRollup[]? | select(.conclusion != "SKIPPED" and .conclusion != "SUCCESS") | {name, conclusion}],
    passing: [.statusCheckRollup[]? | select(.conclusion == "SUCCESS") | .name] | length,
    reviews: [.reviews[]? | {state, author: .author.login}]}'
```

## Step 3: Classify failures

| Failure Type | Action |
|-------------|--------|
| Linked-issue check | CI config gap, not a code problem → fix per references/linked-issue-exemption.md |
| RSpec / test failures | Real problem — investigate before merge |
| Brakeman | May be obsolete ignore entries → see workflows/W-05-ci-fix-patterns.md |
| sdk-validate / unrelated checks | Pre-existing failure, not from this PR |

## Step 4: Merge safe PRs

If CI is green (or only failing on policy checks you've exempted), merge them:

```bash
gh pr merge <number> --repo ORG/REPO --squash
```

## Pitfalls

- **Always verify CI before recommending merge.** A "safe" PR still needs green on the checks that matter (RSpec, JS tests, brakeman).
- **Dependabot PRs may conflict with each other.** If two PRs touch the same lockfile, merge one, wait for CI, then rebase the other.
- **Auto-merge Dependabot PRs may have gone stale.** If a PR was opened weeks ago, the lockfile may have drifted. Check that `mergeable` is not `CONFLICTING`.
