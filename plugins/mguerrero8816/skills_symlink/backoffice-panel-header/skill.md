---
description: Canonical markup for backoffice card/panel headers (title + action buttons). Always load and follow when creating or editing a panel header in a backoffice view.
---

## Canonical Panel Header

Every backoffice card/panel header (a `.card-header` with a title and optional action buttons) must follow this structure:

```haml
.card.p-0
  .card-header.d-flex.gap-3.justify-content-between.align-items-center
    %h4.m-0 Panel Title
    .btn-group
      = link_to "Primary Action", some_path, class: "btn btn-primary"
      = link_to "Secondary Action", other_path, class: "btn btn-info"
```

Reference implementation to match: `app/views/backoffice/provider_inventory/index.haml` (the Inventory Catalogs header).

## Rules

- **Header row:** `.card-header.d-flex.gap-3.justify-content-between.align-items-center` — flex row, `gap-3` between items, title left / actions right, vertically centered.
- **Title:** `%h4.m-0` — always an `h4` with `m-0`. Never `%h2.h5.mb-0` or other heading sizes/utility combos.
- **Actions:** wrap all header buttons in a single `.btn-group`, even when there is only one button.
- **Button size:** full-size `btn btn-primary` (or `btn-info`, `btn-secondary`, etc.). Never `btn-sm` in a panel header.
- **No actions:** if the panel has no header buttons, use just the header row with the `%h4.m-0` title.
- Icons inside a button are fine (e.g. `%i.fa-solid.fa-plus.me-1` before the label) — the rules above govern the header/title/button structure, not whether a button carries an icon.

**Examples:**
- ❌ BAD: `%h2.h5.mb-0 Title` — wrong heading size/utilities
- ✅ GOOD: `%h4.m-0 Title`
- ❌ BAD: `= link_to "Add", path, class: "btn btn-sm btn-primary"` directly in the header — small button, not grouped
- ✅ GOOD: `.btn-group` wrapping a full-size `= link_to "Add", path, class: "btn btn-primary"`
- ❌ BAD: `.card-header.d-flex.justify-content-between.align-items-center` — missing `gap-3`
- ✅ GOOD: `.card-header.d-flex.gap-3.justify-content-between.align-items-center`
