---
description: Advances an RFX project to Supplier Identification and adds suppliers via the providers page. Use when the user wants to add suppliers to an RFX project or complete the supplier identification phase.
tools: Bash, Read, mcp__playwright__browser_navigate, mcp__playwright__browser_click, mcp__playwright__browser_wait_for, mcp__playwright__browser_snapshot, mcp__playwright__browser_evaluate
model: sonnet
---

## Base: RFX Create Project

Invoke `Skill(playwright-rfx-create-project)` before proceeding.

---

## Rails Models

- `Rfx::Project` — the project; UUID in URLs; statuses: `draft → supplier_identification → supplier_review → supplier_selection → complete`
- `Rfx::Provider` — join record linking a `Pg::Provider` to the project; has its own `uuid` for supplier-facing URLs
- `Pg::Provider` — the actual supplier record

## Task: Add Suppliers to an RFX Project

Continuing after the project has been created and you are on the setup page (`/rfx/:uuid/setup`):

### 1. Advance to Supplier Identification

At the bottom of the setup page, click **Continue to Supplier Selection**. This submits a PATCH that advances the project status to `supplier_identification` and redirects to `/rfx/:uuid/providers`.

Selector: `button[type=submit]` inside the status-advance form (the button contains the text "Continue to Supplier Selection").

### 2. Open the Add Supplier Modal

On the providers page, click **+ Add Supplier**:

```
button[hx-get*="add_providers_modal"]
```

This HTMX request loads the modal content into `#add-providers-modal-placeholder`. Wait for the modal body to appear:

```
browser_wait_for(selector="#add-providers-modal .modal-body")
```

### 3. Select Suppliers

The modal has a native multi-select (`#provider_ids`, `multiple: true`). If the list is empty there are no eligible providers — stop and report.

Select the first 3 available providers using `browser_evaluate`:

```js
const sel = document.getElementById('provider_ids');
Array.from(sel.options).slice(0, 3).forEach(opt => { opt.selected = true; });
```

### 4. Submit

Click **Add Providers** — selector: `#add-providers-modal input[type=submit]`

The HTMX response swaps the providers table and fires a `closeAddModal` event to dismiss the modal. Wait for the table to update:

```
browser_wait_for(selector="#rfx-providers-table-card tbody tr")
```

### 5. Confirm

Take a targeted snapshot of `#rfx-providers-table-card` and report:
- How many suppliers were added
- Their names and RFI status (should show "Not Started" badges)

The project is now in `supplier_identification` status with suppliers invited.
