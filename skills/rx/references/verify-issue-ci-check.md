# VerifyIssue CI Check

## Rule

Every PR in the RX repo must be linked to either:
1. **A GitHub issue** describing the problem/feature, OR
2. **A preceding PR** that provides context for the change

The `VerifyIssue` CI check enforces this and will fail if neither is present.

## Why

PRs need context for reviewers and future archaeology. A linked issue or parent PR explains *what* is being fixed and *why*, not just *how*.

## How to Link

### Linking to an issue
Add `Closes #NNNN` or `Fixes #NNNN` in the PR body. This also auto-closes the issue on merge.

### Linking to a preceding PR
Reference the parent PR with `#NNNN` in the PR body.

## Workflow

When creating a PR:
1. Check if an existing issue covers the work — link to it
2. If no issue exists, create one first describing the problem/change
3. Include the `Closes #NNNN` link in the PR body before opening

## Common Mistake

Opening a PR for a quick fix (dependency sync, typo, config change) without creating an issue first. Even trivial changes need an issue for the VerifyIssue check to pass.
