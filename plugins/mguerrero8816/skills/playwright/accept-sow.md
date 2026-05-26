---
description: Opens the Accept SOW (or Submit for Approval) purchase modal on a quote group page. Use when a test plan says "accept the SOW", "open the purchase form", or "confirm the purchase modal renders". Two approaches documented — sidebar shortcut (simpler) and proposal panel flow (needed when verifying DocuSign gating or loading the panel explicitly).
---

## Rails Models

- `Pg::QuoteGroup` — use `uuid` in the URL: `/quote_groups/{uuid}`
- `Pg::ProposalBase` — use `uuid` for the proposal panel dropdown selector
- `Pg::DocusignEnvelope` — relevant when verifying DocuSign gating in the modal

## Button Label

The button label is computed by `accept_proposal_button_text`:
- **"Accept SOW"** — when `quote_group.compliant_sows?` is true
- **"Submit for Approval"** — when compliance is still pending (same button, same modal)

Check in console if unsure:
```ruby
Pg::QuoteGroup.find_by(uuid: "...").compliant_sows?
```

## Pre-conditions

Before running this flow, confirm in the Rails console:
```ruby
qg = Pg::QuoteGroup.find_by(uuid: "...")
p  = Pg::ProposalBase.find_by(uuid: "...")
puts qg.could?(:accept_sow)   # must be true
puts p.purchasable?            # must be true
puts p.selectable?             # must be true
```

If any return false, the button will not render.

## Approach A — Sidebar button (simpler)

Use this when the quote group page is already loaded and you just need the modal open.

From the quote group page, click the Accept SOW link in the **Available Actions** sidebar. Do not match by text — it's ambiguous:
```
a[href="#"][class*="accept"]
```

This fires `pagepusher-modal#openModal` immediately and loads the purchase form into `#purchase-selection` via HTMX. Skip to **Verify the modal** below.

## Approach B — Proposal panel flow

Use this when you need the proposal panel loaded first (e.g. verifying the panel's DocuSign gating, or when the sidebar button is not present).

### 1. Navigate to the quote group page
```
browser_navigate(url: "https://az.test/quote_groups/{qg_uuid}")
```

### 2. Open the SOW dropdown
```
target: a.btn.btn-secondary.btn-sm.dropdown-toggle
```

### 3. Select the proposal
```
target: a.dropdown-item[href*="proposal-{proposal_uuid}"]
```
This triggers a JS request (`/quote_groups/{id}/proposals/{uuid}.js`) that renders the proposal panel on the right side of the page.

### 4. Wait for the panel to load
```
browser_wait_for(time: 3)
```

### 5. Click the Accept SOW / Submit for Approval button

The green `btn-success` link in the proposal panel header (distinct from the sidebar version):
```
target: a.text-default.btn.btn-success.me-1
```

## Verify the modal

Wait for the purchase form content to load:
```
browser_wait_for(text: "Reason(s) for choosing this Proposal")
```

**Pass:** Modal renders with shipping/billing addresses, legal document table, and reason checkboxes. No "declined for signing" error.

**Fail (DocuSign bug):** Modal shows "The document has been declined for signing and can't be reinstated." This means `envelope.active?` returned false — check `envelope_status` against `TERMINAL_STATUSES` on `Pg::DocusignEnvelope`.

## Modal details

- Bootstrap modal id: `#purchase_dialog`
- Purchase form loads into: `#purchase-selection`
- Submit button (after filling the form): `input[type=submit]` or `button[type=submit]`
