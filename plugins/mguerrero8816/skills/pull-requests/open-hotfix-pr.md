# Open Hotfix Pull Request

This command creates a pull request for hotfix work (urgent production fixes).

## Step 1: Load Universal PR Rules

**CRITICAL: You MUST run `base-rules.md` immediately before doing anything else.** This loads all universal PR creation rules including:
- Draft mode requirement (ALL PRs must be created in draft mode)
- Branch checks
- Context gathering
- URL generation
- And other essential rules

**Run `base-rules.md` now before continuing with Step 2.**

## Step 2: Apply Hotfix Specific Rules

### PR Title Format

Use this format: **"HOTFIX: [Brief description of the fix]"**

Examples:
- "HOTFIX: Allow supplier requests to see the obsoleted PPOs again"
- "HOTFIX: Fix null pointer exception in invoice calculation"
- "HOTFIX: Restore missing purchase order display"

**IMPORTANT**: The title must start with "HOTFIX:" in all caps

### Issue Reference
- Always reference the original issue that caused the problem
- If the hotfix is a followup to another PR, reference that PR as well
- Format: "Part of #[issue_number]" and "Followup to #[pr_number]" (if applicable)

### Slack Link
- **CRITICAL**: If the issue was reported in Slack, include a link to the Slack message in the description
- Format: `This was [reported in slack](https://assaydepot.slack.com/archives/CHANNEL_ID/pMESSAGE_ID)`
- The Slack link provides important context about when/how the issue was discovered

### Labels
- **MUST use**: "Hotfix", "Type: Fix"
- **Add capability labels** if the hotfix affects specific capabilities (e.g., "Cap:ClinicalLabs", "Cap:ProductHub")
- **Add area label**: "Backoffice" or "Storefront" based on where the changes are

### Base Branch
- **CRITICAL**: Hotfixes ALWAYS target the `production` branch
- Use `--base production` when creating the PR
- This is NOT negotiable - hotfixes are urgent production fixes and must go directly to production

### PR Template

Use this template format:

```markdown
**Description**
Part of #[issue_number]
Followup to #[pr_number] (if applicable)

[Explain what broke and why. Include technical details about the root cause.]

This was [reported in slack](SLACK_URL_HERE) (if applicable)

**User Impact**
[Describe which users are affected and what they cannot do because of this bug]

**Instructions**
1. [Step-by-step reproduction of the original bug]
2. [Steps to verify the fix works]
3. [Include URLs to visit with correct base URL]
4. [What to verify after the fix]

**Screenshots** (if applicable)
<table>
<tr>
<th>Before (Bug)</th>
<th>After (Fixed)</th>
</tr>
<tr>
<td>

</td>
<td>

</td>
</tr>
</table>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### CRITICAL: Description Section Requirements

**Hotfix descriptions MUST include:**
1. ✅ Issue reference (Part of #XXXXX)
2. ✅ Followup reference if this fixes a recently merged PR (Followup to #XXXXX)
3. ✅ Slack link if the bug was reported there
4. ✅ Clear explanation of what broke and the root cause
5. ✅ Technical details about why the original code caused the problem

**Example Description:**
```markdown
**Description**
Part of #33683
Followup to #33768

Because active also looks at the existence of the obsoleted boolean #33768 actually modified existing behavior on supplier requests so that the obsoleted PPOs were no longer visible. This was [reported in slack](https://assaydepot.slack.com/archives/CF6490Y80/p1768505245360399) and so we'll continue hiding any POs that have been superseded but display the obsoleted PPOs like we were doing before.
```

### Important Notes

- **Urgency**: Hotfixes are urgent by nature - create the PR quickly but thoroughly
- **Test thoroughly**: Include detailed reproduction steps in the instructions
- **Screenshots**: Always include before/after screenshots showing the bug and the fix
- **Root cause**: Explain WHY the bug happened, not just what the fix is
- **Slack context**: The Slack link is valuable for understanding user impact and urgency

## Example Label Combinations

- **Backoffice hotfix**: "Backoffice", "Hotfix", "Type: Fix"
- **Storefront hotfix with capability**: "Storefront", "Hotfix", "Type: Fix", "Cap:ClinicalLabs"
- **General hotfix**: "Hotfix", "Type: Fix"

## Workflow Summary

1. Run `base-rules.md` first (MANDATORY)
2. Verify you're on the correct branch with `git branch --show-current`
3. Gather context (commits, diff, files changed)
4. Create draft PR with `--draft` flag and `--base production`
5. Add labels: "Hotfix", "Type: Fix", and area/capability labels
6. Include Slack link if applicable
7. Explain root cause in description
8. Provide detailed reproduction steps
