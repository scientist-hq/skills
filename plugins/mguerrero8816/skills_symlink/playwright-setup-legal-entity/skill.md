---
description: Creates a customer legal entity for an org in backoffice and sends it to NetSuite. Use when the user wants to set up a legal entity, create a legal entity for an org, or fix a "customerLegalEntity not imported to NetSuite" error.
tools: Bash, Read, mcp__playwright__browser_navigate, mcp__playwright__browser_click, mcp__playwright__browser_type, mcp__playwright__browser_wait_for, mcp__playwright__browser_snapshot, mcp__playwright__browser_select_option
model: sonnet
---

## Base: Playwright QA

Invoke `Skill(playwright-base)` before proceeding.

---

## Task: Ensure a synced CustomerLegalEntity exists for the org

This skill does NOT need to run the full request/proposal flow — it is a standalone setup task.

### Step 0: Check for an existing synced one

Before doing anything else, run:

```
bundle exec rails runner "org = Pg::Organization.find_by(subdomain: 'SUBDOMAIN'); le = Pg::CustomerLegalEntity.where(scientist_entity: org).where.not(netsuite_id: nil).first; puts le ? \"Found: #{le.companyname} (netsuite_id: #{le.netsuite_id})\" : 'None found'"
```

If a result is returned, report the name and netsuite_id — **no further action needed**. Stop here.

### Step 1: Find the org ID

```
bundle exec rails runner "puts Pg::Organization.find_by(subdomain: 'SUBDOMAIN').id"
```

### Step 2: Create the legal entity via the UI

Navigate to `https://backoffice.test/admin/organizations/:org_id/legal_entities/new`

Fill in the form using `browser_type` (NOT `browser_fill` — it does not exist):
- **Company name**: use a short, unique name (e.g. `AZ NS TEST 2`) to avoid entityid truncation collisions
- **Invoicing email**: any valid email (e.g. `dev@scientist.com`)
- **Billing address**: fill street, city, state, zip, country
- **Tax ID**: can be left blank if not required

Submit the form and note the legal entity ID from the resulting URL.

### Step 3: Mark as accounting reviewed and send to NetSuite

`accounting_reviewed: true` is required — `Netsuite::LegalEntityJob` silently returns without sending if it is false.

```
bundle exec rails runner "le = Pg::LegalEntity.find(LE_ID); le.update!(accounting_reviewed: true, skip_netsuite_callbacks: false)"
```

### Step 4: Confirm

```
bundle exec rails runner "le = Pg::LegalEntity.find(LE_ID); puts le.netsuite_status; puts le.netsuite_id"
```

Report the legal entity ID and NetSuite ID. Status should be `Sent Successfully`.

**Note:** If you get a 400 error from NetSuite about a duplicate entityid, the company name is too long and is being truncated to match an existing record. Use a shorter unique name.
