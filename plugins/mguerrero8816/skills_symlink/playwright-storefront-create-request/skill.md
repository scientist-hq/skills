---
description: Creates a new request from the storefront by searching for a service. Use when the user wants to create a request, start a new request, or search for a service on the storefront.
tools: Bash, Read, mcp__playwright__browser_navigate, mcp__playwright__browser_click, mcp__playwright__browser_type, mcp__playwright__browser_wait_for, mcp__playwright__browser_select_option, mcp__playwright__browser_snapshot
model: sonnet
---

## Base: Storefront Index

!`cat ~/skills/plugins/mguerrero8816/skills_symlink/playwright-storefront-index/skill.md`

---

## Rails Models

- `Pg::QuoteGroup` — the request record created by this flow
- `Pg::QuotedWare` — one per supplier invited to the request
- `Pg::ProviderLegalEntity` — queried in Step 0 to find the NetSuite-connected supplier

## Task: Create a Request

Continue from the storefront index to create a new request.

### Step 0: Find a NetSuite-connected supplier

Before navigating to the storefront, run this query to find a provider with a legal entity already sent to NetSuite:

```
bundle exec rails runner "le = Pg::ProviderLegalEntity.where(netsuite_status: 'Sent Successfully').first; puts le ? le.scientist_entity.name : 'NONE'"
```

Note: do NOT use `.joins(:scientist_entity)` — `scientist_entity` is a polymorphic association and Rails will raise `EagerLoadPolymorphicError`. Load the first record then call `.scientist_entity` on it.

- If a provider name is returned, remember it — this is the **target supplier**. Make sure to include them during supplier selection (step 9).
- If `NONE` is returned, stop and run the `setup-legal-entity` skill first to create a provider legal entity in NetSuite, then return here with the provider name.

### Reusing an existing request

If there is already a request in a suitable state (sent to suppliers, correct ware and target supplier already selected), you may navigate to it directly and skip steps 1–10. A suitable request must be in "Supplier Review" state with the target supplier listed. Always create a fresh request if none exists or if test isolation is required.

### Steps

1. Use the storefront-index flow above to reach the storefront index for the requested org (default `az`)
2. Find the service or product search field on the index page
3. Type `hbs` into the search field and wait for results to appear
4. Select "Human Biological Samples" from the results
5. On the new request form, fill in the following fields with reasonable test data:
   - **Description for Suppliers**: a brief description of a fictional HBS request (2-3 sentences)
   - **Project Code**: `TEST-001`
   - **Proposals required by**: a date 30 days from today
   - Leave **Notes for the Concierge** blank unless the user specifies otherwise
   - Leave the shipping/billing address fields as-is (pre-populated from the org)

   **IMPORTANT — Description field uses TinyMCE**: The description textarea is `aria-hidden="true"` and cannot be filled with `browser_type`. Use `browser_evaluate` to set content via the TinyMCE API:
   ```js
   window.tinymce.editors.find(e => e.id === 'pg_quote_group_description').setContent('<p>Your description here.</p>');
   ```
   If you skip this or try to fill the hidden textarea directly, the form will submit silently and redirect to `/quote_groups` with no error message — the request will not be created.

6. Click the **Save and Continue** button (`id="make-request"`)
7. On the next page (compliance manifest), fill in:
   - **Business Unit**: select "R&D Oncology Unit" from the dropdown
   - **Certify checkbox**: check it
8. Click **Save and Continue**
9. On the supplier selection page, make sure the **target supplier** from Step 0 is selected. Also select 2-3 other suppliers without a checkmark or "added" indicator.
10. Click **Save and Finish** (or equivalent final submit button)
11. Report what page you land on, confirm the request was submitted successfully, and note the target supplier name for the next steps in the flow
