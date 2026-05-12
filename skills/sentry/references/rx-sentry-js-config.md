# RX Sentry JavaScript SDK Configuration

## Location

`rx/app/views/layouts/_sentry.html.haml`

Rendered conditionally in layout heads:
- `layouts/backoffice_bs5/_backoffice_bs5_head.html.haml`
- `layouts/storefront_bs5/_head_js_bs5.html.haml`

Condition: `Sentry.configuration.enabled_environments.include?(Rails.env) && ENV["SENTRY_IO_JAVASCRIPT_DSN"].present?`

## Architecture

Uses **Sentry Loader (CDN)** pattern, NOT an npm package:
- Script tag loads from `ENV["SENTRY_IO_JAVASCRIPT_DSN"]` (which is actually a loader URL, not a DSN)
- Configuration via `Sentry.onLoad(function() { Sentry.init({...}) })`
- No `@sentry/*` packages in `package.json`

## Configuration Options

The `Sentry.init()` call accepts all standard JS SDK options inside the `onLoad` callback:
- `ignoreErrors: [...]` — array of strings (partial match) or regexes
- `denyUrls: [...]` — filter by script URL
- `beforeSend: function(event) { ... }` — programmatic filtering

## Ruby-side Config

`rx/config/initializers/sentry.rb`:
- Enabled: production, staging only
- Breadcrumbs: active_support_logger, http_logger
- PII: enabled (IP, cookies, request, params)

## Common Noise Patterns

Good candidates for `ignoreErrors`:
- `"Non-Error exception captured with keys"` — generic ErrorEvent from global onerror, no stacktrace
- `"Script error"` — cross-origin script errors (already filtered by Sentry SDK default)
