# Namespacing — Never Add New Models to `app/models/pg/`

**NEVER create new model files under `app/models/pg/`**

- `app/models/pg/` is a legacy directory — new models go top-level or in a purpose-specific subdirectory
- Referencing existing `Pg::` classes is fine — the ban is on creating new ones in that directory

**Exception — configuration rule directives:**
- Directives live in `app/models/configuration/pg/` and **all** use the `Pg::` namespace — follow that convention for new directives
- ✅ GOOD: `class Pg::PreferredProviderDirective < Pg::Directive` in `app/models/configuration/pg/preferred_provider_directive.rb`
