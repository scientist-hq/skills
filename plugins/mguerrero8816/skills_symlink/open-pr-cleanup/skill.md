---
description: Command for creating a draft pull request for removing unused code as part of Bootstrap 5 migration cleanup, with title format, labels, and PR template.
---

# Open Code Cleanup Pull Request

## Code Cleanup Specific Rules

### PR Title Format

Use this format: **"Remove unneeded [what] from [where]"**

Examples:
- "Remove unneeded `layout` from `TicketCommentsController`"
- "Remove unused method from UserService"
- "Remove deprecated helper from ApplicationHelper"

### Issue Reference
- Always reference issue #32465 in the PR description (these are typically part of BS5 migration cleanup)

### Labels
- **MUST use**: "Type: Cleanup"
- **Add "Backoffice" label** if the PR modifies backoffice code

### Milestone
- Set milestone: "Bootstrap 5"

### PR Template

Use this template format:

```markdown
**Description**
This is part of #32465. It removes [describe what is being removed and why it's unused/unneeded].

**User Impact**
This has no external impact.

**Instructions**
To confirm that [feature] is still functional:
1. [Step-by-step testing instructions to verify the feature still works]
2. [Include URLs to visit with correct base URL (backoffice.test, backoffice.scientist.dev, az.test, etc.)]
3. [What to verify/check]
4. [Test the specific functionality that might have been affected]

**Screenshots** (if applicable)
[Include screenshots if relevant]

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Important Notes

- **User Impact**: Almost always "This has no external impact." for cleanup PRs
- **Instructions**: Focus on testing the feature that the removed code was associated with to prove it still works
- **Explanation**: Clearly explain WHY the code is unused (e.g., "solely perform redirects, and no rendering")

## Example Label Combinations

- **Backoffice cleanup**: "Backoffice", "Type: Cleanup"
- **General cleanup**: "Type: Cleanup"
