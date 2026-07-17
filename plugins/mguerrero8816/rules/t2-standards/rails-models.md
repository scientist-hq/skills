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

## Get-or-Create — Default to `find_or_create_by!`, Not `create_or_find_by`

**Default to `find_or_create_by!` for get-or-create. Never use `create_or_find_by` / `create_or_find_by!` on a model that has a uniqueness *validation*.**

`create_or_find_by[!]` attempts the `create` **first** and only falls back to `find` by rescuing the database's `ActiveRecord::RecordNotUnique` (the DB unique index). It does **not** rescue `ActiveRecord::RecordInvalid`. So when the model also has `validates ..., uniqueness: true`, the create fails at the *validation* layer before the DB is ever touched, the rescue never fires, and:
- `create_or_find_by!` raises `RecordInvalid: ... has already been taken` (loud crash),
- `create_or_find_by` returns an unsaved, invalid, brand-new record instead of the existing one (silent, worse).

**Crucially, this passes in specs** — a fresh transactional test DB never pre-creates the row, so `create` succeeds and the broken branch is never exercised. It only fails once the record already exists (i.e. in real/dev data). Green specs, latent bug.

Most models in this app have uniqueness validations, so `create_or_find_by` is almost always the wrong tool.

- **Default:** `find_or_create_by!(...)` — find-first, works with validations, readable.
- **Only use `create_or_find_by!`** when *all three* hold and you document why: (1) genuine concurrent writers racing to create the same row, (2) a real DB unique index on those attributes, (3) **no** uniqueness validation that would fire on create. (It's the more race-safe option only in that narrow case; it also burns a PK sequence value on the rolled-back insert.)

**Examples:**
- ❌ BAD: `Revenue::PredictionModel.create_or_find_by!(name: Revenue::PredictionModel::HUMAN)` (PredictionModel has `validates :name, uniqueness: true` → raises `RecordInvalid` once the row exists)
- ✅ GOOD: `Revenue::PredictionModel.find_or_create_by!(name: Revenue::PredictionModel::HUMAN)`
