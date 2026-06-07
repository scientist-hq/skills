---
description: Reviews a pull request — dispatches parallel security and general review subagents, plus formatting check for your own PRs.
---

## Step 1: Determine PR Ownership

Run `gh pr view [PR_NUMBER_OR_URL]` and check the author against:
- Email: `michael@scientist.com`
- Names: `Michael`, `Mike`, `Michael Gorsuch`

## Step 2: Dispatch Review Agents

Dispatch 2 agents in parallel using the Agent tool:

1. **Security review** — prompt: `"Review PR [URL] for security and data safety issues. Invoke Skill(review-security) for your full instructions."`
2. **General review** — prompt: `"Review PR [URL] for general code quality. Invoke Skill(review-general) for your full instructions."`

Collect both results and present them grouped by agent, with a rolled-up summary table at the end sorted by severity.

## Step 3: Formatting Review (Own PRs Only)

If the PR is authored by Michael/Mike, invoke `Skill(pr-base-rules)` and check:
- Is it a draft PR?
- Does it have the correct title format?
- Does it have appropriate labels?
- Does the description follow the required sections?
- Are test instructions complete?
- Are URLs using the correct base domain?
- Is the screenshot table present?

Skip formatting review entirely for PRs authored by others.
