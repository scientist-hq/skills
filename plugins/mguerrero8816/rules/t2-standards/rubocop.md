# RuboCop Compliance Rules

Rules for writing RuboCop-clean code in this codebase. These apply to all Ruby files including specs.

## Layout/EmptyLinesAroundBlockBody

**Never leave a blank line at the start or end of a block body**

RuboCop enforces that `do...end` and `{}` blocks, as well as `describe`/`context`/`it` blocks in RSpec, have no extra blank lines immediately inside the opening or before the closing keyword.

**Examples:**
- ❌ BAD:
  ```ruby
  describe 'something' do
    context 'when X' do
      it 'does Y' do
        expect(foo).to eq(bar)
      end
    end

  end
  ```
- ✅ GOOD:
  ```ruby
  describe 'something' do
    context 'when X' do
      it 'does Y' do
        expect(foo).to eq(bar)
      end
    end
  end
  ```

This most commonly appears at the end of a top-level `describe` block when a blank line is left before the closing `end`.

## Parenthesizing `change { }` Blocks

See `spec-rules.md` — `change { }` used with `.not_to` or `.and` must be parenthesized to avoid RuboCop's block-association error.

## Style/SymbolArray

**Always use `%i[]` for arrays of symbols — never `[:foo, :bar]`**

- Applies everywhere: migrations, model code, specs, anywhere a symbol array appears

**Examples:**
- ❌ BAD: `add_index :table, [:quote_group_id, :provider_id]`
- ✅ GOOD: `add_index :table, %i[quote_group_id provider_id]`

## Layout/HashAlignment

**Never pad hash values with extra spaces to align them** — use a single space after each colon.

**Examples:**
- ❌ BAD:
  ```ruby
  {
    name:         'foo',
    long_key:     'bar',
    another_key:  'baz'
  }
  ```
- ✅ GOOD:
  ```ruby
  {
    name: 'foo',
    long_key: 'bar',
    another_key: 'baz'
  }
  ```

## Style/IfUnlessModifier

**Always use modifier form when a conditional has only one line in its body** — write `expression if condition` instead of a multi-line `if/end` block.

**Examples:**
- ❌ BAD:
  ```ruby
  if record.present?
    do_something
  end
  ```
- ✅ GOOD: `do_something if record.present?`
- ❌ BAD:
  ```ruby
  unless user.admin?
    redirect_to root_path
  end
  ```
- ✅ GOOD: `redirect_to root_path unless user.admin?`

## Layout/DotPosition — ActiveRecord Query Chains

**Never start a new line with a leading dot** — Rubocop requires trailing dots on multi-line method chains.

In practice, the cleanest solution for ActiveRecord queries is to **keep the chain on a single line**, even if it's long. The codebase does not split these onto multiple lines.

**Examples:**
- ❌ BAD (leading dots — Rubocop will flag this):
  ```ruby
  eligible_ids = Pg::Provider
    .joins(:organization_providers)
    .where(organization_providers: { organization: canonical_organization, published: true, purchasable: true })
    .where(id: provider_ids)
    .pluck(:id)
  ```
- ✅ GOOD (single line):
  ```ruby
  eligible_ids = Pg::Provider.joins(:organization_providers).where(organization_providers: { organization: canonical_organization, published: true, purchasable: true }).where(id: provider_ids).pluck(:id)
  ```

Long lines are acceptable — Rubocop's line-length cop is not enforced strictly here. Prefer a long single line over a multi-line leading-dot chain.

## Layout/ExtraSpacing

**Never pad variable assignments with extra spaces to align them** — use a single space around `=`.

**Examples:**
- ❌ BAD:
  ```ruby
  proposal    = @document.source
  quoted_ware = proposal.quoted_ware
  quote_group = quoted_ware.quote_group
  ```
- ✅ GOOD:
  ```ruby
  proposal = @document.source
  quoted_ware = proposal.quoted_ware
  quote_group = quoted_ware.quote_group
  ```
- ❌ BAD:
  ```ruby
  NAVY     = '1f356f'
  CYAN     = '6fceb9'
  LABEL_BG = 'eff3f5'
  ```
- ✅ GOOD:
  ```ruby
  NAVY = '1f356f'
  CYAN = '6fceb9'
  LABEL_BG = 'eff3f5'
  ```
