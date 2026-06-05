---
description: Rules and available skills for Playwright-based browser testing and automation in the local RX dev environment, including screenshot locations, reload discipline, and PR test verification standards.
---

# Playwright Testing Rules

## Available Skills

Personal skills for automating browser tasks.

**`playwright-base`** — base Playwright skill
- Knows all dev credentials, org subdomains, and login flows
- Use for general multi-step browser automation
- Other browser skills build on this one

**`/storefront-index`** — open the storefront index
- Use when the user says "open the storefront", "go to az.test", "open the [org] storefront", etc.
- Defaults to `az` if no org is specified
- ALWAYS use this skill instead of `playwright-base` when the task is just opening the storefront index

**`/storefront-create-request`** — create a new request from the storefront
- Use when the user wants to create a request or search for a service on the storefront
- Opens the storefront index first, then searches "hbs" and selects Human Biological Samples
- Builds on storefront-index

**`/open-proposal-form`** — open the new proposal form
- Use when the user wants to open a proposal form, inspect it, or get to the proposal creation page
- Starts from the storefront request page: sends to suppliers → opens backoffice → selects a quoted ware → clicks Start Proposal
- Stops at the open blank form and reports the URL — does NOT fill or submit

**`/create-proposal`** — fill and submit a proposal
- Use when the user wants to create and submit a full proposal (SOW, fees, line items)
- Builds on open-proposal-form to get to the form, then fills and submits it

**`/create-purchase-order`** — create a purchase order from a proposal
- Use when the user wants to create a purchase order or complete the PO workflow
- Builds on create-proposal, then returns to the storefront request page to initiate the PO

**`/create-change-order`** — create a change order against an existing PO
- Use when the user wants to create a change order or modify scope on an in-progress request
- Builds on send-po-to-netsuite; action is in the backoffice quoted ware sidebar, not the storefront

**`/send-po-to-netsuite`** — send a PO to NetSuite
- Use when the user wants to send a PO to NetSuite or sync a purchase order
- Goes to `backoffice/accounting/purchase_orders`, finds the PO, opens Actions → Send → Send Purchase Order & Sales Order to Netsuite
- Note: AZ org will fail with `customerLegalEntity` error in dev — use an org with NetSuite configured (e.g. BMS) for a full end-to-end test

**ALWAYS use the most specific skill available:**
- ALWAYS run `/storefront-index` when the user wants to open or navigate to a storefront — do NOT use playwright-base directly
- ALWAYS run `/storefront-create-request` when the user wants to create a request from the storefront
- ALWAYS run `/open-proposal-form` when the user wants to open or inspect the proposal form — do NOT use create-proposal if the user only wants to open the form
- ALWAYS run `/create-proposal` when the user wants to create and submit a complete proposal
- ALWAYS run `/create-purchase-order` when the user wants to create a purchase order

## Screenshots

**ALWAYS save Playwright screenshots to `/Users/mike/playwright_screenshots/` — NEVER save them inside the repo.**

This applies to any screenshot taken via `browser_take_screenshot` or any other Playwright screenshot tool.

## Always Reload After Making Changes

**After any code change or database change, ALWAYS reload the page before checking the result — never trust the current browser state.**

The browser caches the previous response. After a change, the page may still show a stale error, old content, or a Better Errors page from a previous request. A fresh reload is required to see the actual effect of the change.

**Pattern:**
```ruby
# After making a change, navigate to the URL fresh — don't just inspect the current state
browser_navigate(url: "https://az.test/quote_groups/...")
# or use a cache-busting param if Better Errors is being sticky:
browser_navigate(url: "https://az.test/quote_groups/...?v=2")
```

Do not report what you see in the browser until after the reload. Do not assume the current screenshot reflects your change.

## Console Pre-Check Before Browser Testing

**Before browser-testing any model validation or service behavior, verify the logic works in the Rails console first.**

A console check takes 30 seconds and catches obvious breakage before you invest time in a browser flow.

**Pattern:**
```ruby
record = Model.find_by(...)
record.some_attribute = invalid_value
record.valid?         # => false
record.errors.full_messages
```

This does NOT replace browser testing — end users interact via the UI, not the console. The console check is a fast pre-flight that confirms the underlying logic works before you automate the browser.

## Check development.log When the Browser Behaves Unexpectedly

**When a browser action produces unexpected results (error page, wrong redirect, blank response, RoutingError), check `development.log` before trying anything else.**

The browser only shows the surface. The log shows what actually happened server-side: rollbacks, rescued exceptions, validation errors, nil associations, etc.

```bash
tail -n 100 /Users/mike/rx/rx/log/development.log
```

This is complementary to the Post-Run Investigation steps in the `playwright-base` skill, which handle browser-side diagnosis (selector mismatches, timing, login state). The log covers the server side of unexpected behavior.

## Browser Steps in PR Test Plans Are Not Optional

**When a PR test plan says "verify in browser", you MUST show the actual UI. Console or code verification is NOT a substitute — it is a complement at best.**

This failure mode looks like:
- Page shows an error or dev gate ("You must enable X to view this")
- Falling back to: "the code is registered correctly, so this step passes"
- Reporting PASS without ever seeing the feature in the browser

That is not a passing test. The user cannot verify anything from a console assertion alone.

**1. Work through every blocker until the page renders.**

If a page shows a dev gate, routing error, or "feature not enabled" message:
- Diagnose WHY — check the gate condition in the view code
- Find a way past it: use the right user, temporarily bypass the condition, or enable the feature
- Only report PASS after you have seen the actual page content

**2. Use the right user for the right permissions.**

Before navigating to a page, check whether it requires a specific role or feature flag. Find a user who has it:
```ruby
Pg::User.where('email ILIKE ?', '%@scientist.com').each do |u|
  puts u.email + ': ' + u.has_feature?(org, 'site_rep').to_s
end
```
Do not test a permissions-gated page as a user who cannot see it.

**3. Temporary bypasses are acceptable — leave no trace.**

To get past a dev gate, it is fine to temporarily edit a view condition (e.g. `- if false`) or rescue a connection error. But:
- Tell the user what you changed and why
- Revert immediately after the user has seen what they need to see
- Never commit these changes

**4. Report what you actually saw, not what the code implies.**

A passing browser step means: "I navigated to the page, it rendered, and I can see X in the snapshot." It does not mean: "the method exists and returns the right value in the console."

**5. Take a screenshot at the end of every browser test step — but ONLY during testing.**

This rule applies when running a PR test plan or QA verification. It does NOT apply to general Playwright automation (opening storefronts, navigating for the user, filling forms, creating test data in the browser, etc.).

After confirming a browser test step passes:
- Take a screenshot with `browser_take_screenshot`
- Save to `/Users/mike/playwright_screenshots/<step-name>.png`
- Tell the user the exact path: e.g. "Screenshot saved to `/Users/mike/playwright_screenshots/step2-bell-badge.png`"
- This gives the user a visual record they can open and verify independently

**When this applies:** running steps from a PR description, QA checklist, or explicit "verify X works" request.
**When this does NOT apply:** `/storefront-index`, `/create-proposal`, form automation, navigating to a URL for the user, any task where the goal is to accomplish something rather than verify something.
