# RuboCop Compliance Rules

These rules apply to all Ruby files, including specs.

## Layout/EmptyLinesAroundBlockBody

Never put a blank line just after `do` or `{`, or just before the closing `end` or `}`. This includes `describe`, `context`, and `it` blocks. The common mistake is a blank line before the last `end` of a top-level `describe`.

## Parenthesize `change { }` Blocks

See `spec-rules.md`. A `change { }` with `.not_to` or `.and` must be in parentheses.

## Style/SymbolArray

Use `%i[]` for every symbol array.

- ❌ BAD: `add_index :table, [:quote_group_id, :provider_id]`
- ✅ GOOD: `add_index :table, %i[quote_group_id provider_id]`

## Layout/HashAlignment and Layout/ExtraSpacing

Never add spaces to align hash values, assignments, or constants. Use one space after a colon, and one space on each side of `=`.

- ❌ BAD: `proposal    = @document.source`
- ✅ GOOD: `proposal = @document.source`

## Style/IfUnlessModifier

Use the modifier form when a conditional body has one line.

- ✅ GOOD: `do_something if record.present?`
- ✅ GOOD: `redirect_to root_path unless user.admin?`

## Layout/DotPosition

Never start a line with a leading dot. Keep an ActiveRecord query chain on one line, even when it is long. The line-length cop is not strict here.

- ✅ GOOD: `eligible_ids = Pg::Provider.joins(:organization_providers).where(organization_providers: { organization: canonical_organization, published: true, purchasable: true }).where(id: provider_ids).pluck(:id)`
