# Open Panel to Card Migration Pull Request

This command creates a pull request for migrating Bootstrap 3 `.panel` elements to Bootstrap 5 `.card` elements.

## Step 1: Load Universal PR Rules

**CRITICAL: You MUST run `base-rules.md` immediately before doing anything else.** This loads all universal PR creation rules including:
- Draft mode requirement (ALL PRs must be created in draft mode)
- Branch checks
- Context gathering
- URL generation
- And other essential rules

**Run `base-rules.md` now before continuing with Step 2.**

## Step 2: Apply Panel-to-Card Specific Rules

### PR Title Format

Use this format: **"Update [area] [feature] from panel to card"**

Examples:
- "Update backoffice Provider Sites from panel to card"
- "Update Configuration Rules from panel to card"
- "Update Organization Financial Settings from panel to card"

### Issue Reference
- Always reference issue #34357 in the PR description
- Link: https://github.com/scientist-hq/rx/issues/34357

### Labels
- **MUST use**: "Type: Improvement", "Style"
- **Add "Backoffice" label** if the PR modifies backoffice pages
- **Add "Storefront" label** if the PR modifies marketplace/storefront pages

### Milestone
- Set milestone: "Bootstrap 5"

### PR Template

Use this template format:

```markdown
**Description**
As part of #34357, this PR updates [area/feature] from Bootstrap 3 `.panel` elements to Bootstrap 5 `.card` elements.

Changes include:
- Updated HTML classes: `.panel` → `.card`, `.panel-heading` → `.card-header`, `.panel-body` → `.card-body`, `.panel-footer` → `.card-footer`
- Updated JavaScript selectors to target `.card` classes instead of `.panel`
- [Any other relevant changes]

**User Impact**
No external impact - this is a visual consistency update as part of the Bootstrap 5 migration. The functionality remains the same.

**Instructions**
1. [Step-by-step testing instructions - derive URLs from the modified controller/route, NOT from template PRs]
2. [Include URLs to visit with correct base URL (backoffice.test or az.test)]
3. Verify that all card-style elements render correctly with proper borders and spacing
4. [Test interactive features if JavaScript was updated]
5. [Test edge cases if applicable]

**Screenshots** (if applicable)

<table>
<tr>
<th>Before</th>
<th>After</th>
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

### What to Check

When creating a panel-to-card migration PR, verify the following changes:

**HTML/View Changes:**
- [ ] `.panel` → `.card`
- [ ] `.panel-heading` → `.card-header`
- [ ] `.panel-body` → `.card-body`
- [ ] `.panel-footer` → `.card-footer`
- [ ] `.panel-title` → `.card-title` (if present)

**JavaScript Changes:**
- [ ] Update jQuery selectors from `.panel` to `.card`
- [ ] Update selectors for `.panel-heading` → `.card-header`
- [ ] Update selectors for `.panel-body` → `.card-body`
- [ ] Update any dynamically created HTML that generates panel markup
- [ ] Update matchHeight or other jQuery plugins that target panel classes

**CSS/SCSS Changes (if applicable):**
- [ ] Update any custom CSS that targets `.panel` classes

### Important Notes

- **JavaScript Selectors**: Always update JavaScript files that select panel elements, including:
  - Direct selectors (`.panel`, `.panel-body`, etc.)
  - Dynamic HTML generation (`'<div class="panel">'`)
  - jQuery plugins targeting panels (matchHeight, sortable, etc.)
- **Screenshots**: Include before/after screenshots when possible to show visual consistency
- **GitHub Actions labeler bot**: The "Style" label may be removed by the bot if no stylesheet files were changed. The user will need to manually re-add it after each push.

### Files to Check

When doing a panel-to-card migration, commonly modified files include:
- **Views**: HAML/ERB files with panel markup
- **JavaScript**: Controllers in `app/assets/javascripts/` or `app/javascript/`
- **Stylesheets**: Custom SCSS that styles panels (less common)

## Example Label Combinations

- **Backoffice panel-to-card migration**: "Backoffice", "Type: Improvement", "Style"
- **Marketplace panel-to-card migration**: "Storefront", "Type: Improvement", "Style"
- **Admin panel-to-card migration**: "Storefront", "Type: Improvement", "Style" (admin pages are on marketplace)
