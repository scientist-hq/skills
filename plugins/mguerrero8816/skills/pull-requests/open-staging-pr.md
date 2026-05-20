# Open Staging Pull Request

This command creates a pull request targeting the `staging` branch.

## Step 1: Load Universal PR Rules

**CRITICAL: You MUST run `base-rules.md` immediately before doing anything else.**

Run `base-rules.md` now before continuing with Step 2.

## Step 2: Apply Staging-Specific Rules

### PR Title Format

Use this format: **"STAGING: [Brief description of the change]"**

Examples:
- "STAGING: Adds support for DocuSign signing workflows with non-system users"
- "STAGING: Add provider storefront URL to Third Party Approval Form"

**IMPORTANT**: The title must start with "STAGING:" in all caps.

### Base Branch

- **CRITICAL**: Staging PRs ALWAYS target the `staging` branch
- Use `--base staging` when creating the PR

### Labels

- Follow the same area label rules as standard PRs (Backoffice or Storefront, never both)
- Add capability labels if applicable

### PR Description

Follow the same description format as standard PRs from `base-rules.md`.

## Workflow Summary

1. Run `base-rules.md` first (MANDATORY)
2. Verify branch with `git branch --show-current`
3. Gather context (commits, diff, files changed)
4. Create draft PR with `--draft` and `--base staging`
5. Add area and capability labels as appropriate
