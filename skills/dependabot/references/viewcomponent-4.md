# ViewComponent 3.x → 4.x Migration

## Security Fixes (why you upgrade)
- **v4.9.0**: Path traversal in `ViewComponentsSystemTestController` + preview route vulnerability

## Breaking Changes (Production)

1. **Removed dependency on `ActionView::Base`** — edge cases may need `helpers.` proxy
2. **Minimum versions**: Rails >= 7.1.0, Ruby >= 3.2.0
3. **Removed `render_component`** and `render` monkey patch
4. **Removed deprecated `use_helper(s)`** — use `include MyHelper` or `helpers.` proxy
5. **Removed default initializer** — components MUST define their own `initialize`
6. **Dropped `method_source` dependency** — remove from Gemfile if only ViewComponent used it

## Breaking Changes (Dev/Test)

- `config.view_component.test_controller` → `vc_test_controller_class` test helper
- Generator: `rails g component` → `rails g view_component:component`
- `Nokogiri::HTML5` replaces `Nokogiri::HTML4` for test helpers

## Codebase Audit Checklist

```bash
# Count components
find app/components -name "*.rb" | wc -l

# Check for slot usage (biggest risk area)
grep -r "renders_one\|renders_many\|with_content\|with_slot" app/components/

# Check for deprecated helpers
grep -r "use_helper\b" app/components/

# Check for render monkey patch
grep -r "render_component" app/ spec/

# Check for previews
find . -path "*component_preview*" -o -path "*components/previews*"

# Check test config
grep -r "test_controller\|component_parent_class\|view_component_path" config/
```

## Dependency Changes (Lockfile Impact)

- v3: depends on `activesupport (>= 5.2)`, `concurrent-ruby`, `method_source`
- v4: depends on `actionview (>= 7.1)`, `activesupport (>= 7.1)`, `concurrent-ruby`
- **Dropped:** `method_source` — remove its lockfile entry if nothing else needs it
- **Added:** `actionview` as explicit dependency

## Manual Lockfile Edit (when bundle update fails)

If local Ruby version doesn't match and private gems also pin Ruby:

1. `gem specification view_component -v 4.x.x --remote` — get exact deps
2. Edit Gemfile.lock: replace version and deps block
3. Remove dropped deps (`method_source`)
4. Note manual edit in PR body — CI validates with correct Ruby
