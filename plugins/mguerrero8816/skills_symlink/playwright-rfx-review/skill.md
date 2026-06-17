---
description: Advances an RFX project to Supplier Review and opens the Review & Compare page. Use when the user wants to view the RFI comparison, review supplier responses, or reach the review phase of an RFX project.
tools: Bash, Read, mcp__playwright__browser_navigate, mcp__playwright__browser_click, mcp__playwright__browser_wait_for, mcp__playwright__browser_snapshot
model: sonnet
---

## Base: RFX Add Suppliers

Invoke `Skill(playwright-rfx-add-suppliers)` before proceeding.

---

## Rails Models

- `Rfx::Project` — must be in `supplier_identification` status to advance to `supplier_review`
- `Rfx::Provider` — suppliers with `status: "submitted"` appear in the comparison tables
- `Rfx::RfiComparisonPresenter` — drives the RFI answers table on the review page
- `Rfx::PricingComparisonPresenter` — drives the pricing table on the review page

## Task: Open the Review & Compare Page

Continuing from the providers page (`/rfx/:uuid/providers`) after suppliers have been added:

### 1. Advance to Supplier Review

In the Quick Actions sidebar, click **Proceed to Review & Compare →** — selector: `button[type=submit]`

This submits a PATCH advancing the project status to `supplier_review` and redirects to `/rfx/:uuid/review`.

If the project is already in `supplier_review` or later, the sidebar shows a link instead: `a[href*="/review"]`.

### 2. Confirm the Review Page

Wait for the page to load:

```
browser_wait_for(selector=".rfx-comparison-wrapper, .alert-info")
```

The page shows one of two states:
- **Suppliers have submitted**: comparison tables with RFI answers and pricing side-by-side
- **No submissions yet**: info alert "No suppliers have submitted yet"

Take a targeted snapshot and report which state you see. If suppliers are shown, list their names from the comparison table headers.

### Note on Supplier Submissions

The comparison tables only show data after suppliers submit their RFI responses. To get backoffice invitation URLs for manual submission:

```
bundle exec rails runner "
  p = Rfx::Project.find_by(uuid: 'PROJECT_UUID')
  p.rfx_providers.each { |rp| puts \"#{rp.provider.name}: https://backoffice.test/providers/#{rp.provider.to_param}/rfx/invitations/#{rp.uuid}/edit\" }
"
```
