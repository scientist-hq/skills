---
description: Entry point for all pull request creation. Loads base rules, then routes to a specialized skill if the PR type calls for one.
---

## Step 1: Load Base Rules

Invoke the `open-pr-base-rules` skill now. These apply to every PR regardless of type.

## Step 2: Determine PR Type

Use the current branch context and any stated intent to determine the PR type:

| Situation | Load skill |
|-----------|------------|
| Targeting the `production` branch or user says "hotfix" | `open-pr-hotfix` |
| Targeting the `staging` branch or user says "staging" | `open-pr-staging` |
| Removing unused/dead code | `open-pr-cleanup` |
| Standard feature/fix PR into `main` | No additional skill needed — base rules cover it |

## Step 3: Create the PR

Follow the rules from the loaded skill(s) to create the PR.
