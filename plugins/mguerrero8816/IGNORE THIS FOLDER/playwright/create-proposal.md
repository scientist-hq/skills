---
description: Creates and submits a proposal in backoffice using the admin flow. Use when the user wants to create a proposal, fill in and submit a proposal form, or complete the full proposal creation workflow. Builds on open-proposal-form.
tools: Bash, Read, mcp__playwright__browser_navigate, mcp__playwright__browser_click, mcp__playwright__browser_type, mcp__playwright__browser_wait_for, mcp__playwright__browser_snapshot, mcp__playwright__browser_select_option, mcp__playwright__browser_evaluate
model: sonnet
---

## Base: Open Proposal Form

!`cat ~/skills/plugins/mguerrero8816/skills/playwright/open-proposal-form.md`

---

## Rails Models

- `Pg::Proposal` — the proposal record created by this flow; has a UUID visible in the form URL
- `Pg::ProviderLegalEntity` — used for the billing legal entity dropdown; query by `netsuite_status: 'Sent Successfully'`
- `TaxItem` — tax items referenced by `netsuite_item_id`; used to verify correct NetSuite routing after submission

## Task: Fill and Submit the Proposal

Continuing from the open proposal form:

### 1. Proposal type — SOW

Click the SOW radio using its stable id:
```
#proposal_proposal_type_sow
```
Do NOT use `input[value="sow"]` — the value attribute is capitalized `"SOW"`.

### 2. Transaction fee

The fee assignment field is a **Select2 widget** — `browser_select_option` and `browser_click` on the container are both unreliable. Use `browser_evaluate` with jQuery instead:

```js
$('.proposal-fee-assignment-select').val('supplier').trigger('change')
```

This sets "Supplier Pays" and fires the JS change event that unlocks line item price and quantity fields. Use a reasonable default of 10% supplier pays if not specified.

### 3. Billing legal entity

Select the legal entity with `netsuite_status: Sent Successfully`. The correct selector is:
```
select.select-supplier-address[data-address-type="billing"]
```
If the dropdown doesn't show it, query:
```
bundle exec rails runner "puts Pg::ProviderLegalEntity.where(netsuite_status: 'Sent Successfully').first&.companyname"
```

### 4. Tax category

A tax category selection is required. It is also a **Select2 widget**:
1. Click the container to open it: `.proposal-tax-category-select + .select2-container`
2. Click the first non-blank option: `.select2-results__option:nth-child(2)` (e.g. "Provision of a Good/Product")

### 5. Tax ID field

The `proposal_provider_tax_id_number` select is often empty in dev environments but is marked `required`. Before every submit attempt, remove the required attribute:
```js
document.getElementById('proposal_provider_tax_id_number').removeAttribute('required')
```
This must be repeated before each submit because server re-renders reset the DOM.

### 6. Line items

Fill in at least one line item. Stable selectors:
- Description: `#proposal_milestones_attributes_0_description` — **required**, must not be blank
- Quantity: `#proposal_milestones_attributes_0_quantity`
- Price: `#proposal_milestones_attributes_0_base_unit_price` — **not** `wholesale_unit_price` (that is a hidden field). Must be filled via `browser_type`, not JS evaluate — the Stimulus controller needs real input events to populate `wholesale_unit_price`
- Turnaround time: `#proposal_milestones_attributes_0_min_turnaround_time` and `#proposal_milestones_attributes_0_max_turnaround_time` — both have `min="1"` in HTML. **Must be set to ≥ 1.** A value of `0` causes `rangeUnderflow` native validation which silently blocks form submission with no visible error.
- Turnaround time units dropdown: `select[id$="_units"]` — set to `weeks`
- Expiration date: `input[id*="expires"]`

### 7. Shipping section

The shipping section resets on every server round-trip. Set these fields immediately before each submit attempt:

- **Client shipment radio** (required): click `#international_shipping_no` (or `#international_shipping_yes` if applicable)
- **Free shipping checkbox** (required if shipping cost is 0): click `#proposal_shipping_attributes_free_shipping`
- **Supplier shipping address organization name** (required): `#proposal_provider_shipping_address_attributes_organization_name` — not always pre-populated; set via `browser_evaluate` if blank
- **Supplier shipping address street**: `#proposal_provider_shipping_address_attributes_street`

If address fields are not pre-populated, use `browser_evaluate` to set them directly before submitting.

### 8. Submit

The submit button is `<input type="submit">`, **not** a `<button>`. Use:
```
input[value="Proceed to Proposal Review"]
```

Immediately before clicking submit, always:
1. Click `#international_shipping_no`
2. Click `#proposal_shipping_attributes_free_shipping` (if cost is 0)
3. Remove required from `proposal_provider_tax_id_number` via evaluate

### 9. After submission

Report the URL you land on and confirm the proposal was created successfully.

### Proposal description (TinyMCE)

The proposal description field is a TinyMCE editor. If you set it via `browser_evaluate`:
```js
tinymce.editors[0].setContent('your text here')
```
you **must** also call:
```js
tinymce.editors[0].save()
```
`save()` syncs the editor content back to the underlying `<textarea>`. Without it, the textarea stays empty and the saved proposal will have a blank description — with no error or warning.

### Debugging: submit button does nothing

If clicking the submit button produces no navigation and no visible error, a native HTML5 validation failure is silently blocking it. Run this to identify the culprit fields:

```js
Array.from(document.querySelectorAll(':invalid')).map(el => ({ id: el.id, validity: JSON.stringify(el.validity) }))
```

Common causes: turnaround time field with value `0` (`rangeUnderflow`), blank required field (`valueMissing`).
