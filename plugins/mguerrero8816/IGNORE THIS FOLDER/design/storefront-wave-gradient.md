---
description: How to add the full-width teal gradient + wave background on storefront_bs5 pages — the correct pattern and every pitfall to avoid.
---

## How the layout works

`storefront_bs5` renders in this order:

```
= content_for :hero      ← full-width block, before the container
.container > .content
  = yield                ← main page content (padding-top: 1.5rem / 24px)
```

There is **no `:head` or `:styles` slot** — you cannot inject CSS from a view file.

---

## The correct gradient + wave structure

```haml
= content_for :hero do
  .position-relative
    .position-absolute.top-0.start-0.end-0.overflow-hidden{ style: "height: 300px; z-index: 0;" }
      .bg-gradient-alt.h-100
      .position-absolute.start-0.w-100{ style: "bottom: -1px; height: 0; padding-bottom: 10%;" }
        %svg.position-absolute.top-0.start-0.w-100.h-100.d-block= inline_svg_tag "svgs/wave.svg", style: "fill: #fff;", aria_hidden: true

    .container.px-4{ style: "position: relative; z-index: 1;" }
      [page content — in normal flow, visually overlaps the gradient]
```

The gradient is `position: absolute` so it takes up **no space in the document flow**. The `.position-relative` wrapper's height comes entirely from the in-flow content inside it. No negative margins are needed.

---

## Rules that must not be broken

**`overflow: hidden` on the gradient wrapper is mandatory.** Without it the wave SVG renders below the gradient and bleeds into the white page area below.

**`bottom: -1px` on the wave container.** A 1px seam can appear between the wave and the white background without this.

**`height: 300px` on the gradient wrapper.** This matches the height used across other gradient pages in the app (e.g. Clinical Navigator / Trials). The wave height is proportional — controlled by `padding-bottom: 10%`, which scales with viewport width.

**`z-index: 0` on the gradient, `z-index: 1` on content.** Content must sit above the gradient or it will be hidden behind it.

**Use `.container` (not `.container-fluid`) for the in-flow content wrapper.** `container-fluid` collapses the left/right gutters at large screen widths.

**Use `inline_svg_tag`, not `image_tag`, for the wave.** The SVG fill color must be set inline: `style: "fill: #fff;"`. File: `app/assets/images/svgs/wave.svg`.

---

## When to put content inside `content_for :hero`

If the page needs content to appear *over* the gradient (e.g. a header, a title, cards that emerge from the wave), put it all inside `content_for :hero` and leave `yield` empty.

- When `yield` is empty, `.container.content` is never rendered — no 300px gap to fight
- The gradient is absolutely positioned so it doesn't push the in-flow content down
- Everything stacks naturally: gradient behind, content on top

If `yield` is non-empty alongside `content_for :hero`, the hero creates a **300px in-flow block** before the yield content. Compensating with negative margins is fragile — avoid this.

---

## Pitfalls we hit

**Wave was being cut off** — missing `overflow: hidden` on the gradient container. The wave SVG extended beyond the gradient area and was partially visible below it.

**A 1px gap between wave and white background** — fixed by `bottom: -1px` on the wave container.

**Wave too short** — `padding-bottom: 10%` creates a proportional height. At narrow viewports the wave is short; this is expected and matches other pages in the app.

**Content pushed down 300px** — happened when using both `content_for :hero` and a non-empty `yield`. The hero block is in-flow and takes up 300px before yield. Solution: put everything inside `content_for :hero` and leave yield empty.

**Gutters collapsed** — using `.container-fluid` instead of `.container` inside the hero caused the content to span full viewport width with tiny gutters. Fix: always use `.container`.

**Content hidden behind gradient** — forgot `z-index: 1` on the content wrapper. The gradient's `z-index: 0` sits above un-positioned elements. Fix: add `style: "position: relative; z-index: 1;"` to the content wrapper.

**CSS injection via `content_for :head` didn't work** — there is no `:head` slot in `storefront_bs5`. Styles injected this way are silently ignored.
