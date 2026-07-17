---
description: CSS patterns and gotchas for the RX frontend. Load when working on styling, especially inline element decoration or link styling.
---

## `text-decoration` on Child Inline Elements

When you need to hide the underline on a specific child inline element inside an `<a>` tag, `text-decoration: none` on the child does **not** work — the underline is drawn by the parent's box and passes through all children regardless.

The correct approach:
1. Set `text-decoration: underline` on the child (so it owns its own underline segment)
2. Set `text-decoration-color: <background-hex>` to make that segment invisible

**Examples:**
- ❌ BAD: `style: "text-decoration: none;"` on a child `<i>` inside an `<a>` — has no effect
- ✅ GOOD: `style: "text-decoration: underline; text-decoration-color: #f2f2f2;"` — child owns its segment and colors it to match the background

Look up the exact background color hex before hardcoding it (e.g. `neutral-95` = `#f2f2f2`).
