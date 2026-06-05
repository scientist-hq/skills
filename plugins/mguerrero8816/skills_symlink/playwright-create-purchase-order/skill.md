---
description: Creates a purchase order from a proposal using the storefront. Use when the user wants to create a purchase order, accept a proposal, or complete the purchase order workflow.
tools: Bash, Read, mcp__playwright__browser_navigate, mcp__playwright__browser_click, mcp__playwright__browser_type, mcp__playwright__browser_wait_for, mcp__playwright__browser_snapshot, mcp__playwright__browser_select_option, mcp__playwright__browser_evaluate
model: sonnet
---

## Base: Create Proposal

Invoke `Skill(playwright-create-proposal)` before proceeding.

---

## Base: Accept SOW

Invoke `Skill(playwright-accept-sow)` before proceeding.

---

## Rails Models

- `Pg::ProviderPurchaseOrder` — the PO record created by this flow (NOT `PurchaseOrder` or `Pg::PurchaseOrder`)
- `Pg::PurchaseRequisition` — the purchase requisition selected in the Add PO modal; its UUID is the option value in the select

## Task: Create a Purchase Order

Continuing after the proposal has been submitted:

### 1. Accept SOW

Navigate back to the storefront request detail page (use the URL from the request created earlier in the flow).

Use **Approach A** from the Accept SOW skill above (sidebar button: `a[href="#"][class*="accept"]`).

In the modal, select a reason for choosing this proposal. CSS selectors for the reason checkboxes are ambiguous — use `browser_evaluate` to check one by label text:

```js
const cbs = document.querySelectorAll('input[type=checkbox]');
for (const cb of cbs) {
  const label = cb.closest('label') || cb.parentElement;
  if (label && label.textContent.includes('Cost')) { cb.checked = true; break; }
}
```

Then click **Purchase** using `browser_evaluate`:
```js
Array.from(document.querySelectorAll('button')).find(b => b.textContent.trim() === 'Purchase').click()
```

Wait for the success toast:
```
browser_wait_for(text="awaiting PO")
```

### 2. Add PO

In the **Available Actions** sidebar, click Add PO using this selector — `text=Add PO` matches 4 elements and will fail:
```
a.add_po
```

### 3. Add PO Number modal

The modal is a Bootstrap modal (`#po_dialog`), **not** an HTML `<dialog>` element — do not use `dialog[open]` as a selector.

The purchase requisition select uses UUID option values, so `browser_select_option` will fail. Use `browser_evaluate` to set it directly:

```js
const modal = document.getElementById('po_dialog');
const sel = modal.querySelector('select[name=id]');
sel.value = sel.options[1].value;  // pick the first non-blank option
sel.dispatchEvent(new Event('change', { bubbles: true }));
```

Set the PO number (use `PO-TEST-001` if not specified):
```js
document.getElementById('purchase_po_number').value = 'PO-TEST-001';
```

Submit using:
```
#po_dialog input[type=submit]
```

### 4. Confirm

Confirm the request status has updated to "Work Started" and report the PO UUID:
```
bundle exec rails runner "puts Pg::ProviderPurchaseOrder.where(po_number: 'PO-TEST-001').last&.uuid"
```
