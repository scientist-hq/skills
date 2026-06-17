---
description: Creates a new RFX project from the RFX index. Use when the user wants to create an RFX project or start a new RFX engagement.
tools: Bash, Read, mcp__playwright__browser_navigate, mcp__playwright__browser_click, mcp__playwright__browser_type, mcp__playwright__browser_wait_for, mcp__playwright__browser_snapshot, mcp__playwright__browser_evaluate, mcp__playwright__browser_select_option
model: sonnet
---

## Base: RFX Index

Invoke `Skill(playwright-rfx-index)` before proceeding.

---

## Rails Models

- `Rfx::Project` — the project record; UUID used in all subsequent URLs (`/rfx/:uuid/setup`)
- `Rfx::Type` — service category selected at creation (e.g. "In Vitro ADME", "Custom Antibodies")

## Task: Create a New RFX Project

Continue from the RFX index to create a new project.

### Step 0: Confirm RFX types exist

```
bundle exec rails runner "puts Rfx::Type.count"
```

If the count is 0, run the seed task first:

```
bundle exec rake rfx_seed:types
```

### Steps

1. Use the rfx-index flow above to reach the RFX index for the requested org (default `az`)
2. Click **New RFX Project** — selector: `a[href*="/rfx/new"]`
3. Fill in the form:

   **Project Name** (`#rfx_project_name`): a short descriptive test name, e.g. `QA Test - In Vitro ADME`

   **Service Category** — this is a Select2 widget. Use `browser_evaluate` to select the first available type:
   ```js
   const sel = document.getElementById('rfx_project_rfx_type_id');
   sel.value = sel.options[1].value;
   sel.dispatchEvent(new Event('change', { bubbles: true }));
   ```

   **Due Date** (`.rfx-due-date`) — jQuery datepicker, format `Month DD, YYYY`. Use `browser_evaluate` to set it without opening the picker UI:
   ```js
   const f = document.querySelector('.rfx-due-date');
   f.value = 'July 17, 2026';
   $(f).datepicker('setDate', new Date(f.value));
   f.dispatchEvent(new Event('change', { bubbles: true }));
   ```
   Replace the date with one 30 days from today.

4. Leave **Allow Custom Line Items** unchecked unless specified
5. Click **Create Project** — selector: `button[type=submit]`
6. Confirm you land on the setup page (`/rfx/:uuid/setup`) and report the project UUID from the URL

**After success**: record the project UUID — it's required for all subsequent RFX steps.
