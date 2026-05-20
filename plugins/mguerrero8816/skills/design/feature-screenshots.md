# Feature Screenshots

Rules for taking screenshots of completed features — typically for PR descriptions, documentation, or stakeholder demos. This is a post-development activity, distinct from browser testing.

## Save Location

All feature screenshots go to `/Users/mike/playwright_screenshots/`. Create a subfolder per feature (e.g. `preferred-supplier-screenshots/`). Never save screenshots inside the repo.

## Programmatic Bootstrap Tooltip Screenshots

**When forcing a Bootstrap tooltip visible via `browser_evaluate` for a screenshot, follow this pattern exactly — deviating causes stale tooltips, invisible tooltips, or tooltips trapped behind modals.**

### The pattern

```js
// 1. Dispose ALL existing instances and remove DOM remnants
document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(el => {
  const t = bootstrap.Tooltip.getInstance(el);
  if (t) t.dispose();
});
document.querySelectorAll('.tooltip').forEach(t => t.remove());

// 2. Scroll target into view, then create with container: 'body' — mandatory
icon.scrollIntoView({ block: 'center' });
const t = new bootstrap.Tooltip(icon, { trigger: 'manual', container: 'body', html: true });
t.show();
```

Wait 0.5s after `.show()` before taking the screenshot so the fade-in animation completes.

### Why `container: 'body'` is mandatory

Page pushers have `z-index: 1032`. Without `container: 'body'`, Bootstrap appends the tooltip inside the pusher's DOM, inheriting its stacking context. Even though the tooltip's own z-index is 1080, it gets capped at the pusher's level and appears **behind** any open modal (z-index: 1055) or its backdrop (z-index: 1030).

With `container: 'body'`, the tooltip is a direct child of `<body>` and uses the root stacking context, so its z-index 1080 is respected globally.

## Clean Up Modal State Before Each Step

An open modal left over from a previous step leaves its backdrop in the DOM, creating a stacking context that traps subsequent tooltips. Run this before each screenshot step:

```js
document.querySelectorAll('.modal.show').forEach(m => {
  const instance = bootstrap.Modal.getInstance(m);
  if (instance) instance.hide();
});
document.querySelectorAll('.modal-backdrop').forEach(b => b.remove());
document.querySelectorAll('.tooltip').forEach(t => t.remove());
document.body.classList.remove('modal-open');
document.body.style.removeProperty('overflow');
document.body.style.removeProperty('padding-right');
```

## Pick the Most Informative Tooltip Target

When multiple elements have similar tooltips (e.g. "1 Supplier" vs "4 Suppliers"), always prefer the one that shows more content — it demonstrates the full behavior rather than a minimal case.

## Include Context in Every Screenshot

Every screenshot should show enough surrounding UI that a viewer can tell where they are without a caption:
- Page pushers: include the panel heading
- Modals: include the modal title bar
- Tables: include the table heading row
- Tabs: include the tab bar so the active tab is visible

Scroll to show the relevant heading before taking the shot rather than cropping tight to the icon.
