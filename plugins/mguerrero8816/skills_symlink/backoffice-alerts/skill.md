---
description: How to build inline status/notice alert boxes in backoffice views so they match the app's flash/alert styling. Load when adding a highlighted status message, note, or callout to a backoffice page.
---

## Inline Alert Boxes

For a persistent status message, note, or callout rendered in page content (not a one-shot flash), use a Bootstrap alert box so it matches the app's flash styling exactly. Both the storefront/backoffice manifests load Bootstrap 5.3, so the `.alert` component is already styled (square corners, filled background, `15px 48px 15px 16px` padding).

```haml
.alert.alert-info.mb-0
  %strong Please note:
  not all agreements may apply to your services.
```

Reference implementation: `app/views/backoffice/providers_legal_documents/index.html.haml` (the "Please note" box).

## Variant → meaning

Use the same variants the app's flash uses (see `flash_class` in `app/helpers/application_helper.rb`: notice → `alert-info`, error → `alert-danger`, alert → `alert-warning`):

| Class | Color | Use for |
|-------|-------|---------|
| `alert-success` | green | good / complete / up-to-date state |
| `alert-warning` | yellow | needs attention / action required |
| `alert-danger` | red | error / problem |
| `alert-info` | blue | neutral note / heads-up |
| `alert-secondary` | grey | neutral / status unavailable |

## Rules

- **Use `.alert.alert-<variant>` — never hand-roll a colored-text status** (`%p.text-success`, `%p.text-warning`). Plain colored text doesn't match the app's flash/alert boxes; the alert component does.
- **Single line:** `.alert.alert-success Message here`.
- **Multi-line / interpolated:** use the block form and put content on indented lines.
- **Margins:** the alert carries a default bottom margin. Add `.mb-0` only when it's the **last** element in its container (e.g. the last thing in a `.card-body`); otherwise leave the default so it spaces from following content.
- **Lead-in emphasis:** wrap a short label in `%strong` (e.g. `%strong Please note:`) as the app does.

**Examples:**
- ❌ BAD: `%p.m-0.text-success All POs are up to date.` — colored text, not an alert box
- ✅ GOOD: `.alert.alert-success All POs are up to date.`
