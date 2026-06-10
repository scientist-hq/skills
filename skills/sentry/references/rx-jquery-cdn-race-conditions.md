# RX jQuery CDN Race Conditions & Load Failures

## Pattern: Inline script assumes jQuery is loaded

When jQuery is loaded from a CDN (`_package_js_cdns.html.haml`) and inline `<script>` blocks
reference `$` without guarding for its existence, Safari users (especially those with ITP,
privacy extensions, or transient network issues) can hit `ReferenceError: Can't find variable: $`.

### Common mistake

```javascript
// BAD: only checks fillViewport, assumes $ exists
if ($.fn.fillViewport) { ... }

// GOOD: checks $ first, then the plugin
if (typeof $ !== 'undefined' && $.fn.fillViewport) { ... }
```

### Files involved (as of 2026-05)

- `app/views/users/sessions/new.html.haml` — login page inline scripts (lines ~21, ~71)
- `app/views/layouts/_package_js_cdns.html.haml` — CDN jQuery source
- `app/views/layouts/backoffice/splash_bs5.html.haml` — splash layout
- `app/views/layouts/backoffice_bs5/_backoffice_bs5_head.html.haml` — head partial

### Why Safari specifically?

Safari's Intelligent Tracking Prevention (ITP) can block or delay CDN script loads
that it classifies as cross-site tracking. Combined with aggressive resource prioritization,
inline scripts may execute before deferred/CDN scripts complete. This manifests as
intermittent failures (4 users over 2 months in the RX-5JG case).

### Regression history for RX-5JG

1. `2dd3f6688f` (2025-11-25) — moved fillViewport call from shared JS into inline script
2. `696ce3824a` (2025-12-13) — added `if ($.fn.fillViewport)` guard (insufficient)
3. March 2026 — regressed when real Safari users hit CDN failures

### General principle

Any inline `<script>` in RX views that references `$`, `jQuery`, or any CDN-loaded library
must use `typeof` guards. The asset pipeline doesn't guarantee CDN availability.
