---
description: Creates a change order against an existing purchase order. Use when the user wants to create a change order, modify an existing PO, or add scope to an in-progress request.
tools: Bash, Read, mcp__playwright__browser_navigate, mcp__playwright__browser_click, mcp__playwright__browser_fill, mcp__playwright__browser_wait_for, mcp__playwright__browser_snapshot, mcp__playwright__browser_select_option
model: sonnet
---

## Base: Send PO to NetSuite

!`cat ~/skills/plugins/mguerrero8816/skills/playwright/send-po-to-netsuite.md`

---

## Task: Create a Change Order

Continuing after the PO has been sent to NetSuite:

1. Navigate to the backoffice quoted ware page for the supplier — `https://backoffice.test/quoted_wares/:uuid/edit`
2. In the sidebar, click **Create a Change Order**
3. In the modal that appears, select the PO to change order against (it will be pre-populated with the existing PO — explicitly select it from the dropdown)
4. Click **Create Change Order** to navigate to the change order form
5. The form is pre-populated with the original line items — update the price or add a new line item to represent a scope change
6. Fill in the required fields:
   - **Turnaround time**: set both the number (e.g. `30`) and the units dropdown — units are required server-side even if the field looks optional. Use `browser_evaluate` to set the units select value directly if the dropdown is not visible: `document.querySelector('#proposal_turn_around_time_display_units').value = 'days'`
   - **Expiry date**: set a date at least 30 days out
   - **Submit**: target `#proposal_form` explicitly — `document.querySelector('form')` may match the wrong form on this page. Use `browser_evaluate` to submit: `document.querySelector('#proposal_form').submit()`
   - If HTML5 validation blocks submission (e.g. a required select has no options), disable it first: `document.querySelector('#proposal_form').setAttribute('novalidate', '')`
7. On the review page, confirm and submit the change order
8. Report the URL and confirm the change order was submitted successfully
