---
description: Accepts an RFX invitation and submits a response on behalf of a supplier. Use when the user wants to complete the supplier-side RFX flow — accepting the invite, setting pricing validity, and submitting.
tools: Bash, Read, mcp__playwright__browser_navigate, mcp__playwright__browser_click, mcp__playwright__browser_wait_for, mcp__playwright__browser_snapshot, mcp__playwright__browser_evaluate
model: sonnet
---

## Base: Playwright QA

Invoke `Skill(playwright-base)` before proceeding.

---

## Rails Models

- `Rfx::Provider` — the join record; UUID used in the invitation URL; `status` advances from `invited` → `in_progress` → `submitted`
- `Pg::Provider` — the supplier; `to_param` returns UUID (used in the URL path)

## Task: Accept Invitation and Submit Response

This flow is done from the **backoffice** as the supplier-facing view.

### Step 0: Get invitation URLs

If URLs are not already known, run:

```
bundle exec rails runner "
  p = Rfx::Project.find_by(uuid: 'PROJECT_UUID')
  p.rfx_providers.each { |rp| puts \"#{rp.provider.name}: https://backoffice.test/providers/#{rp.provider.to_param}/rfx/invitations/#{rp.uuid}/edit\" }
"
```

### Steps (repeat for each supplier)

1. Navigate to the invitation URL: `https://backoffice.test/providers/{provider_uuid}/rfx/invitations/{rfx_provider_uuid}/edit`

2. **Accept the invitation** — click the button inside the accept form:
   ```
   form[action*='/accept'] button
   ```
   The page reloads showing the response form.

3. **Set pricing validity** — the radio inputs are visually hidden (`btn-check`), click the label instead:
   ```
   label[for=rfx_duration_6]
   ```
   (Change `6` to `3`, `12`, or `24` for other durations.)

4. **Fill in any pricing line items** — if the pricing table has rows with `.rfx-price-input` fields, fill each one:
   ```js
   document.querySelectorAll('.rfx-price-input').forEach((input, i) => {
     input.value = String((i + 1) * 1000);
     input.dispatchEvent(new Event('input', { bubbles: true }));
   });
   ```
   If the table shows "No line items to price." skip this step.

5. **Check both acknowledgment boxes**:
   ```
   #rfx_ack_terms
   #rfx_ack_authority
   ```

6. **Submit** — the Submit Response button is enabled once both boxes are checked:
   ```
   button.rfx-form-submit
   ```

7. Confirm the page shows "Response submitted" and the submitted date.

### Notes

- The **Submit Response** button is disabled until both acknowledgment checkboxes are checked — check them before clicking
- Pricing validity uses `btn-check` (visually hidden radios) — always click the `<label>`, not the `<input>`
- If there are RFI questions (`_rfi` partial), answer them before pricing — they appear above the pricing card
