# Linked-Issue Check Exemption for Dependabot

## Problem

Both rx and benchmate enforce that every PR has a linked GitHub Issue via `hattan/verify-linked-issue-action@v1.1.5`. Dependabot PRs don't create Issues — the security advisory IS the issue.

## Solution

Add a job-level `if` condition to skip the check for Dependabot branches:

```yaml
# .github/workflows/pr_verify_linked_issue.yml
jobs:
  verify_linked_issue:
    # Skip for Dependabot — the security advisory is the issue
    if: ${{ !startsWith(github.head_ref, 'dependabot/') }}
    runs-on: ubuntu-latest
    name: Ensure Pull Request has a linked issue.
    steps:
      - name: Verify Linked Issue
        uses: hattan/verify-linked-issue-action@v1.1.5
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

If there's already an `if` condition, append with `&&`:

```yaml
    if: ${{ !contains(fromJson('[\"main\", \"staging\", \"production\"]'), github.head_ref) && !startsWith(github.head_ref, 'dependabot/') }}
```

## Why NOT Other Approaches

| Approach | Problem |
|----------|---------|
| Single umbrella issue ("fix security alerts") | Meaningless busywork — adds no info the advisory doesn't have |
| Individual issue per Dependabot PR | Too noisy — Dependabot already links the CVE in the PR body |
| `no-issue` label on each PR | Manual step per PR, defeats automation |

## Applied At

- **rx:** PR #36594 — added condition to existing `if`
- **benchmate:** PR #995 — added new `if` condition
- Both use `hattan/verify-linked-issue-action@v1.1.5`
