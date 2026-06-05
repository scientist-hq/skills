---
description: Creates a new configuration rule in the backoffice admin UI. Use when the user wants to create or test a configuration rule, add a directive via the GUI, or verify a directive works end-to-end.
tools: Bash, Read, mcp__playwright__browser_navigate, mcp__playwright__browser_click, mcp__playwright__browser_type, mcp__playwright__browser_wait_for, mcp__playwright__browser_select_option, mcp__playwright__browser_snapshot, mcp__playwright__browser_evaluate
model: sonnet
---

## Base: Playwright QA

Invoke `Skill(playwright-base)` before proceeding.

---

## Rails Models

- `Pg::ConfigurationRule` — the rule record; UUID appears in the URL after saving
- `Pg::Directive` — STI base; `Pg::Directive` (Basic Directive) sets a property on the target object
- `Pg::Criterion` — STI base; `Pg::AlwaysMatchCriterion` matches every record unconditionally

---

## Task: Create a Configuration Rule

Default configuration (unless the user specifies otherwise):
- **Org**: AZ
- **Trigger**: `request_created`
- **Criterion**: Always Match Criterion — no fields needed, fires unconditionally
- **Directive**: Basic Directive — sets `description` to `"this was created by config rule [UUID]"` where UUID is filled in after saving
- **Active**: checked

---

### 1. Login and navigate

1. Run the Login Flow from the base skill (backoffice only is sufficient)
2. Navigate to `https://backoffice.test/admin/configuration_rules/new`

---

### 2. Select Organization (Select2)

The Organization field is a Select2 widget — `browser_select_option` will NOT work, and typing into the search field does not reliably trigger the AJAX fetch.

**Use the `new Option()` pattern instead** — append the option directly and trigger a change:

```js
const newOption = new Option('{text}', '{id}', true, true);
$('#configuration_rule_organization_id').append(newOption).trigger('change');
```

Dev org IDs (stable — visible in backoffice URLs):

| Subdomain | Name    | ID |
|-----------|---------|----|
| az        | AZ      | 10 |
| acme      | Acme    | 8  |
| alexion   | Alexion | 9  |
| bms       | BMS     | 12 |
| crex      | NIH     | 13 |
| novartis  | Novartis| 15 |
| pfizer    | Pfizer  | 14 |

Example for AZ:
```js
const newOption = new Option('AZ (az)', '10', true, true);
$('#configuration_rule_organization_id').append(newOption).trigger('change');
```

Confirm by checking the container text:
```js
document.querySelector('#select2-configuration_rule_organization_id-container').textContent
// should return "AZ (az)"
```

---

### 3. Select Trigger (Select2 multi-select)

The trigger field is a **multi-select** Select2 — clicking the dropdown option does NOT bind the value to the underlying `<select>`. Use JavaScript to set it directly:

```js
const sel = document.querySelector('#configuration_rule_configured_actions');
const opt = Array.from(sel.options).find(o => o.value === 'request_created');
opt.selected = true;
sel.dispatchEvent(new Event('change', { bubbles: true }));
```

Confirm it worked by checking the Select2 container shows `×request_created`.

---

### 4. Set Criterion to Always Match

The criterion type is a native `<select>` — use `browser_select_option`:
```
selector: select[name="configuration_rule[criteria_attributes][0][type]"]
value:    Pg::AlwaysMatchCriterion
```

After selecting, wait for the HTMX re-render — the criterion property fields will disappear:
```
browser_wait_for: select[name="configuration_rule[criteria_attributes][0][type]"]
```

---

### 5. Set Directive to Basic Directive

The directive type is a native `<select>` — use `browser_select_option`:
```
selector: select[name="configuration_rule[directives_attributes][0][type]"]
value:    Pg::Directive
```

After selecting, **wait for the HTMX re-render** before filling fields:
```
browser_wait_for: select[name="configuration_rule[directives_attributes][0][type]"]
```

---

### 6. Fill Basic Directive Fields

After the re-render, fill in two fields:

**Property Name** — the attribute to set on the target object:
```
selector: input[name="configuration_rule[directives_attributes][0][properties][property_name]"]
value:    description
```

**Property Value** — `property_value` is a `<textarea>`, not an `<input>`. Use a placeholder for now; updated after saving:
```
selector: textarea[name="configuration_rule[directives_attributes][0][properties][property_value]"]
value:    created by config rule (uuid tbd)
```

---

### 7. Mark as Active

Rails renders a hidden `input` with the same name as the checkbox, so `input[name="configuration_rule[active]"]` matches two elements. Use the ID instead:

```
selector: #configuration_rule_active
action:   click to check if not already checked
```

---

### 8. Save

```
selector: button.btn-primary
```

Wait for redirect — success lands at `/admin/configuration_rules/{uuid}/edit`. Extract the UUID from the URL.

---

### 9. Update the Property Value with the Real UUID

After saving, extract the UUID from the URL (`/admin/configuration_rules/{uuid}/edit`). Update the textarea via JS and save again:

```js
const ta = document.querySelector('textarea[name="configuration_rule[directives_attributes][0][properties][property_value]"]');
ta.value = 'created by config rule {uuid}';
```

Then click `button.btn-primary` to save.

---

## Verifying the Rule Fired

After creating the rule, create a new request via the AZ storefront (use the `storefront-create-request` skill). Then verify in the Rails console:

```ruby
qg = Pg::QuoteGroup.order(created_at: :desc).first
puts qg.description
```

Note: if looking up a specific quote group by UUID, always use `find_by(uuid: '...')` — never `find('...')`. Rails casts the UUID string to an integer for `find`, which silently looks up the wrong record or raises `RecordNotFound` with no useful hint.

Expected: `"this was created by config rule {uuid}"`

---

## Cleanup

After testing, **delete or mark inactive** to prevent the rule from firing on future requests:

```
Navigate to: https://backoffice.test/admin/configuration_rules/{uuid}/edit
Uncheck Active, then save — or use the Delete button
```

---

## Notes

- Target Class defaults to `Pg::QuoteGroup` — leave as-is
- Org, target class, and trigger selects are **all Select2** — never use `browser_select_option` on them
- Criterion type and directive type selects are **native `<select>`** — use `browser_select_option`
- After every Select2 interaction or directive type change, take a snapshot to confirm the form updated
- The Basic Directive calls `object.description = value` on the target — it modifies the actual DB record when the rule fires
