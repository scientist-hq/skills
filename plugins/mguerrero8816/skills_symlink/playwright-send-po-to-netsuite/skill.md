---
description: Sends a purchase order to NetSuite from the backoffice request page. Use when the user wants to send a PO to NetSuite or sync a purchase order with NetSuite.
tools: Bash, Read, mcp__playwright__browser_navigate, mcp__playwright__browser_click, mcp__playwright__browser_fill, mcp__playwright__browser_wait_for, mcp__playwright__browser_snapshot, mcp__playwright__browser_select_option
model: sonnet
---

## Base: Create Purchase Order

Invoke `Skill(playwright-create-purchase-order)` before proceeding.

---

## Task: Send PO to NetSuite

Continuing after the purchase order has been created:

1. Navigate to `https://backoffice.test/accounting/purchase_orders`
2. Find the PO by its internal reference number — look for "NetSuite Status: Not Sent"
3. Open its **Actions** dropdown and click **Send** → **Send Purchase Order & Sales Order to Netsuite**
4. In the modal, check that the **customer legal entity** dropdown is set to one with a valid NetSuite ID. If the pre-populated entity has no NetSuite ID (the Send button will be disabled), switch it to one that has been synced — query to find one: `bundle exec rails runner "puts Pg::CustomerLegalEntity.where(netsuite_status: 'Sent Successfully').first&.companyname"`
5. Click **Send to Netsuite** — status will change to "Enqueued to be sent"
6. Run the job directly if it stays enqueued: `bundle exec rails runner "Netsuite::PoSoJob.perform_now(PO_ID)"`
7. Confirm final status: `bundle exec rails runner "po = Pg::PurchaseOrderBase.find(PO_ID); puts po.netsuite_status; puts po.netsuite_id"`
8. Report the NetSuite ID and status
