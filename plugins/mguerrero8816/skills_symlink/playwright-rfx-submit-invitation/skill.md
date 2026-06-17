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
  p.rfx_providers.each { |rp| puts \"#{rp.provider.name}: https://backoffice.test/providers/#{rp.provider.id}/rfx/invitations/#{rp.uuid}/edit\" }
"
```

**Important**: Use the provider's **numeric ID** (`rp.provider.id`), not the UUID or slug — the backoffice invitation routes use the integer ID in `:provider_id`. After accepting, the redirect uses the provider's UUID, so subsequent page URLs will swap to the UUID form — that is expected.

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
- **Avoid RFI forms**: RFI questions are driven by the RFX type, not the line item tax item. To avoid a multi-question RFI during QA, choose a service category with 0 type forms — **Cell Line Authentication** (ID 1) and **RNA Sequencing** (ID 6) have no RFI. Check with: `Rfx::Type.all.map { |t| [t.name, t.rfx_type_forms.count] }`
- If the project was already created with an RFI-generating type and you need to skip questions, the RFI is pure client-side Alpaca validation — use "Save for later" (`button.rfx-form-save-draft`, which has `formnovalidate`) to persist pricing data without answering RFI questions, then click Submit with acks checked
