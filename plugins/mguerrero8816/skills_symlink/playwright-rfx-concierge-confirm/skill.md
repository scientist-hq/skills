---
description: Confirms submitted RFX responses on behalf of Scientist.com (concierge finalization). Use when the user wants to approve supplier responses so the "Select this supplier" buttons become active on the review page.
tools: Bash, Read, mcp__playwright__browser_navigate, mcp__playwright__browser_click, mcp__playwright__browser_snapshot
model: sonnet
---

## Base: RFX Submit Invitation

Invoke `Skill(playwright-rfx-submit-invitation)` before proceeding.

---

## Rails Models

- `Rfx::Provider` — `concierge_finalized_at` is set by this action; both `provider_finalized_at` AND `concierge_finalized_at` must be present for "Select this supplier" to become active on the review page
- `Rfx::Project` — must be in `supplier_review` status

## Task: Concierge-Confirm All Submitted Suppliers

After suppliers have submitted, Scientist.com must confirm each response before the client can select a supplier. The review page shows "Awaiting review" buttons until this step is done.

### Step 0: Get supplier page URLs

```
bundle exec rails runner "
  p = Rfx::Project.find_by(uuid: 'PROJECT_UUID')
  p.rfx_providers.where(status: 'submitted').each { |rp|
    puts \"#{rp.provider.name}: https://#{p.organization.host}/rfx/#{p.uuid}/suppliers/#{rp.uuid}\"
  }
"
```

### Steps (repeat for each submitted supplier)

1. Navigate to the supplier page: `https://az.test/rfx/{project_uuid}/suppliers/{rfx_provider_uuid}`

2. Click **Confirm on behalf of Scientist.com** — it's inside a `button_to` form:
   ```
   form[action*='concierge_finalize'] button
   ```

3. Confirm the status changes — the page should now show "Awaiting client selection" and the "Select this supplier" button should be visible.

### Verify on the review page

After confirming all suppliers, navigate to the review page and check that all columns show active "Select this supplier" links (not disabled "Awaiting review" buttons):

```
https://az.test/rfx/{project_uuid}/review
```

Snapshot `tr.rfx-action-row` — each supplier column should have a link, not a disabled button.
