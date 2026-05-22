# Rails Model Standards

## `belongs_to` — Always Check `belongs_to_required_by_default`

This app sets `config.active_record.belongs_to_required_by_default = false` in `config/application.rb`. This means `belongs_to` associations do **not** validate presence by default.

- **ALWAYS add `optional: false`** to `belongs_to` associations where nil should never be allowed
- Without it, a record with a nil FK will pass model validation and only fail at the DB constraint level (worse error messages, harder to debug)

**Examples:**
- ❌ BAD: `belongs_to :quote_group, class_name: 'Pg::QuoteGroup'`
- ✅ GOOD: `belongs_to :quote_group, class_name: 'Pg::QuoteGroup', optional: false`

## `has_many` in Namespaced Models — Always Specify `class_name` for Top-Level Models

When adding `has_many` inside a namespaced model (e.g. `Pg::QuoteGroup`, `Pg::Provider`), Rails resolves the association class by prepending the current namespace first. A `has_many :preferred_quote_group_providers` inside `Pg::QuoteGroup` will try `Pg::PreferredQuoteGroupProvider` before falling back to `PreferredQuoteGroupProvider`.

- **ALWAYS add `class_name:`** when the associated model lives in a different namespace than the declaring model
- This applies in both directions: `belongs_to` pointing *into* a namespace, and `has_many` pointing *out* to a top-level model

**Examples:**
- ❌ BAD: `has_many :preferred_quote_group_providers, dependent: :destroy` (inside `Pg::QuoteGroup`)
- ✅ GOOD: `has_many :preferred_quote_group_providers, class_name: 'PreferredQuoteGroupProvider', dependent: :destroy`
