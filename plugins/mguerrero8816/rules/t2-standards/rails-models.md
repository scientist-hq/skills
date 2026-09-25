# Rails Model Standards

## `belongs_to` — Add `optional: false`

The app sets `belongs_to_required_by_default = false`, so `belongs_to` does not validate presence. Add `optional: false` when nil must never be allowed.

- ✅ GOOD: `belongs_to :quote_group, class_name: 'Pg::QuoteGroup', optional: false`

## Namespaced Associations — Always Set `class_name`

Rails looks for an association class in the current namespace first. Add `class_name:` when the associated model is in a different namespace, in either direction.

- ❌ BAD: `has_many :preferred_quote_group_providers, dependent: :destroy` (inside `Pg::QuoteGroup`)
- ✅ GOOD: `has_many :preferred_quote_group_providers, class_name: 'PreferredQuoteGroupProvider', dependent: :destroy`

## Get-or-Create — Use `find_or_create_by!`

Use `find_or_create_by!`. Never use `create_or_find_by` or `create_or_find_by!` on a model with a uniqueness validation. That method rescues only the database unique error, but the validation fails first. Then `create_or_find_by!` raises `RecordInvalid`, and `create_or_find_by` returns an unsaved record. Specs do not catch this, because the row does not exist before the create.

Use `create_or_find_by!` only when all three are true, and write a comment that says why:

1. Concurrent writers race to create the same row.
2. A database unique index covers the attributes.
3. The model has no uniqueness validation on them.

- ❌ BAD: `Revenue::PredictionModel.create_or_find_by!(name: Revenue::PredictionModel::HUMAN)`
- ✅ GOOD: `Revenue::PredictionModel.find_or_create_by!(name: Revenue::PredictionModel::HUMAN)`
