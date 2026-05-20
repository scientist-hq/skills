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

## Layout/HashAlignment

**Never pad hash values with extra spaces to align them** — use a single space after each colon. See `CLAUDE.local.md`.

## Layout/ExtraSpacing

**Never pad variable assignments with extra spaces to align them** — use a single space around `=`. See `CLAUDE.local.md`.
