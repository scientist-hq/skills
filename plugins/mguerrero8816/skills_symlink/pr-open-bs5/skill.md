---
description: Command for creating a draft pull request for Bootstrap 5 migration work, with title format, labels, milestone, and PR template specific to BS5 migrations.
---

# Open Bootstrap 5 Migration Pull Request

## Step 1: Load Universal PR Rules

**CRITICAL: You MUST run `base-rules.md` immediately before doing anything else.** This loads all universal PR creation rules including:
- Draft mode requirement (ALL PRs must be created in draft mode)
- Branch checks
- Context gathering
- URL generation
- And other essential rules

**Run `base-rules.md` now before continuing with Step 2.**

## Step 2: Apply Bootstrap 5 Specific Rules

### PR Title Format

Use this format: **"Move [area] [feature] to Bootstrap 5"**

Examples:
- "Move backoffice Provider Invoices to Bootstrap 5"
- "Move Organization administration to Bootstrap 5"
- "Move Organization Shipping Addresses to Bootstrap 5"

### Issue Reference
- Always reference issue #32465 in the PR description

### Labels
- **MUST use**: "Type: Improvement", "Style"
- **Add "Backoffice" label** if the PR modifies backoffice pages

### Milestone
- Set milestone: "Bootstrap 5"

### PR Template

Use this template format:

```markdown
**Description**
As part of #32465, [describe what this PR does and which area it affects].

**User Impact**
[Describe the user-facing impact - often "no external impact" for internal/admin changes]

**Instructions**
1. [Step-by-step testing instructions - derive URLs from the modified controller/route, NOT from template PRs]
2. [Include URLs to visit with correct base URL (backoffice.test or az.test)]
3. [What to verify/check]
4. [Test edge cases if applicable]
5. [Do NOT include "testing responsive behavior" - it's IMPLICIT for all Bootstrap migrations]

**Screenshots** (if applicable)
| [Feature] (Before) | [Feature] (Now) |
| - | - |
| [Screenshot] | [Screenshot] |

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### CRITICAL: Description Section Rules

**DO NOT include the dynamic forms warning in Bootstrap 5 PR descriptions:**
- ❌ NEVER add: "Remember to ensure that these changes do not break any scripts, configuration rules, or dynamic forms..."
- This warning is implicit for ALL PRs and should NOT be included in BS5 migration PRs
- The BS5 PR description should ONLY contain: issue reference (#32465) and what the PR does

### Important Notes

- **Screenshots**: Include before/after screenshots when possible
- **Responsive behavior**: Testing is IMPLICIT - do NOT include it in test instructions
- **GitHub Actions labeler bot**: The "Style" label may be removed by the bot if no stylesheet files were changed. The user will need to manually re-add it after each push.

## Example Label Combinations

- **Backoffice BS5 migration**: "Backoffice", "Type: Improvement", "Style"
- **Marketplace BS5 migration**: "Type: Improvement", "Style"
