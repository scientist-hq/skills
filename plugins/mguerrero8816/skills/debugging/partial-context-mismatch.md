---
description: Diagnosing why a feature renders in some places but not others — covers AJAX-loaded partials that don't share instance variables with the show action.
---

## Partial Context Mismatch

Use this when a feature (badge, icon, section, conditional block) appears correctly in one place but is missing in another place that seems like it should show the same thing.

## First Question: Server-Rendered or AJAX-Loaded?

The same partial can be rendered two ways:

- **Server-rendered** — embedded in the page on load (e.g. inside a `modal_for` block in `show.html.haml`). Has access to all instance variables set in the `show` action.
- **AJAX-loaded** — the page contains an empty container (e.g. `#legal-manager`) that gets populated by a separate request after the page loads. Hits its own controller action, which must set instance variables independently.

If a feature shows in a server-rendered context but not an AJAX-loaded one, the AJAX controller action is almost certainly missing an instance variable that the view depends on.

## Investigation Steps

1. Find where the feature is missing — identify the partial and the specific conditional that gates it (e.g. `@preferred_provider_ids&.include?(...)`)
2. Check how that partial gets rendered in the broken context — look for an empty container div and search the JS for `.load(` or `hx-get` targeting that container
3. Find the controller action that serves the AJAX endpoint
4. Compare its assigned instance variables against what the partial needs — the missing one is the bug

## Fix

Set the missing instance variable in the AJAX controller action, mirroring what `show` does.

## Related Gotcha: Tooltips in AJAX Content

Bootstrap tooltips on dynamically inserted content won't initialize automatically unless `initBs5Overlays(element)` is called after the content is inserted. The global `initBs5Overlays` function is wired to HTMX events and collapse events — but NOT to jQuery `.load()` callbacks.

Fix: add a callback to the `.load()` call:
```javascript
container.load('/some/path', function() {
  if (typeof initBs5Overlays === 'function') initBs5Overlays(container[0])
})
```
