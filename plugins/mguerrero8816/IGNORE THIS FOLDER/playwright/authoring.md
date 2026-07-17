# Playwright Skill Authoring Guide

Reference this document when writing a new skill that builds on `playwright-base`.

## Step 0: Check for an Existing Skill to Build On

Before writing anything, check whether an existing skill already gets the user to the starting point of your new skill. Read `SKILL.md` and scan the Playwright section. Ask: "where does the user need to be when my skill starts — does another skill already end there?"

The existing chain is:

```
storefront-index
  └── storefront-create-request
        └── open-proposal-form
              └── create-proposal
                    └── accept-sow
                          └── create-purchase-order
```

If your skill starts where an existing skill ends, embed that skill using the `!cat` pattern (see below) and write only the delta — the steps your skill adds beyond what the base already covers.

If your skill is standalone (it doesn't build on any existing flow), skip embedding and document everything from navigation.

---

## Skill Chaining with `!cat`

When a skill builds on another, embed the base skill's full content at the top using:

```markdown
## Base: Accept SOW

!`cat ~/skills/plugins/mguerrero8816/skills/playwright/accept-sow.md`

---

## Task: My New Steps

Continuing after the base skill completes...
```

Rules:
- Use a `## Base: <Name>` heading before the `!cat` line so it's clear what's being embedded
- Add a `---` divider after the embedded block before your new content
- Start your section with "Continuing after..." so it's clear this is a delta, not a standalone flow
- Only embed one level — don't add `!cat` in a skill that is itself embedded by another (the chain handles the nesting)

---

## Required Sections

### `## Rails Models`

List every ActiveRecord model the skill touches. Use the correct namespaced class name — wrong names are a common source of console errors.

```markdown
## Rails Models

- `Pg::ProviderPurchaseOrder` — the PO record (NOT `PurchaseOrder` or `Pg::PurchaseOrder`)
- `Pg::QuotedWare` — UUID used in the proposal form URL
```

Include:
- The correct namespaced class name
- Which field is used in URLs (uuid vs numeric id)
- Any query patterns needed to look up records after the flow completes

### `## Rails Models` naming pitfalls

- Most models live under `Pg::` — always check before assuming a bare class name
- Purchase orders are `Pg::ProviderPurchaseOrder`, not `PurchaseOrder`
- Requests are `Pg::QuoteGroup`, not `Request`

---

## Selector Rules

**Never say "click the Foo button" without providing the CSS selector.** Text-label targeting (`link "Foo"`, `button "Bar"`) is not supported in the `target` field — it causes a CSS parse error. `[ref=eN]` refs from snapshots expire between tool calls and must never be used as targets in subsequent calls.

For every interactive element, document the exact CSS selector that works:

```markdown
- Accept SOW link: `a[href="#"][class*="accept"]`
- Submit button: `input[value="Proceed to Proposal Review"]`
- Add PO link: `a.add_po`
```

---

## Select2 Widgets

If a dropdown is a Select2 widget, document it explicitly — `browser_select_option` sets the underlying `<select>` value but does NOT fire the JS change event, which can leave dependent fields locked or unresponsive.

The correct interaction pattern:
1. Click the Select2 container to open it: `.my-select + .select2-container`
2. Click the desired option: `.select2-results__option` (by index or text)

Note which dropdowns are Select2 vs native `<select>` — they look similar in the UI but behave differently.

---

## Fields That Reset on Server Re-render

If a form field loses its value after a failed submission (server re-renders the form), document it and instruct the agent to re-set it immediately before every submit attempt — not just once at the start.

Common offenders in RX:
- International shipping radio (`#international_shipping_no`)
- Free shipping checkbox (`#proposal_shipping_attributes_free_shipping`)
- Required selects with no valid options (remove `required` attribute via evaluate before each submit)

---

## Submit Buttons

Always note whether the submit is `<input type="submit">` or `<button>`. RX forms frequently use `<input type="submit">`, which requires a different selector:

```
# Button:
button[type=submit]

# Input (more common in RX):
input[type=submit]
input[value="Save and Continue"]
```

---

## Bootstrap Modals

Identify modals by their Bootstrap id, not by `dialog[open]`. Bootstrap modals are `<div class="modal">` elements, not HTML `<dialog>` elements — `dialog[open]` will never match them.

Document:
- The modal id: `#po_dialog`
- Key field selectors inside it: `#po_dialog select[name=id]`, `#purchase_po_number`
- The submit selector: `#po_dialog input[type=submit]`

If a select inside a modal uses UUID option values, `browser_select_option` will fail (it matches by display text or value string). Use `browser_evaluate` to set `.value` directly and dispatch a `change` event.

---

## Snapshot Scope

Instruct the agent to use targeted snapshots during normal execution and full-page snapshots only when diagnosing failures. See `~/skills/plugins/mguerrero8816/skills/playwright/base.md` for the snapshot guidance to reference or copy.
