---
description: Opens the new proposal form in backoffice for a given request using the admin flow. Use when the user wants to open a proposal form, inspect the proposal form, or get to the proposal creation page. Starts from the storefront request page and ends with the blank proposal form open in backoffice.
tools: Bash, Read, mcp__playwright__browser_navigate, mcp__playwright__browser_click, mcp__playwright__browser_type, mcp__playwright__browser_wait_for, mcp__playwright__browser_snapshot
model: sonnet
---

## Base: Create Request

!`cat ~/skills/plugins/mguerrero8816/skills/playwright/storefront-create-request.md`

---

## Rails Models

- `Pg::QuoteGroup` — the request; has a numeric `identifier` (e.g. 913127) and a UUID
- `Pg::QuotedWare` — one per supplier; the UUID is used in the proposal form URL (`/quoted_wares/{uuid}/proposals/new`)

## Task: Open the New Proposal Form (Admin Flow)

Starting from a storefront request detail page:

1. Use the Create Request flow above to create a new request, OR navigate to an existing request URL if one is provided.
2. In the **Available Actions** left sidebar, click **Send to Suppliers**
3. In the modal that appears (`#send_to_vendors`), send the request to all selected suppliers. The submit button is `<input type="submit">` — use selector `#send_to_vendors input[type=submit]`
4. After sending, click **Open Backoffice** (appears in the header or sidebar)
5. In the backoffice view (filtered to this request's quoted wares), click on the **target supplier** row identified in the Create Request step — this is the supplier whose legal entity is connected to NetSuite
6. On the quoted ware page, navigate directly to the proposal form URL — do NOT try to click "Start Proposal" by text label (text-label selectors are unsupported). Construct the URL as:
   `https://backoffice.test/quoted_wares/{quoted_ware_uuid}/proposals/new`
   You can get the quoted ware UUID from the current page URL or by running:
   `bundle exec rails runner "puts Pg::QuotedWare.joins(:quote_group).where(quote_groups: {identifier: REQUEST_ID}).first&.uuid"`
7. You should now be on the new proposal form — stop here, report the URL, and confirm the form is visible
