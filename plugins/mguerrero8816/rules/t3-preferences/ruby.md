# Ruby Style Preferences

## Model Method Ordering

Always follow this order in Rails models:

1. `include` / `extend` / `delegate` / `attr_reader` / `attr_writer` / `attr_accessor`
2. Associations (`belongs_to`, `has_many`, etc.)
3. Validations
4. Scopes
5. Instance methods (including `to_param`)

Never place `to_param` or other instance methods before scopes. Never place `attr_*` declarations at the bottom of the file or after method definitions.

## Nil/Empty Array Checks — `present?` in Views, Not `presence` in Models

When a view needs to distinguish between a populated array and an empty one, check `collection.present?` in the view — do not call `.presence` on the array in the model to coerce `[]` to `nil`.

**Examples:**
- ❌ BAD: `providers: provider_names.presence` in a model method, then `- if file[:providers]` in a view
- ✅ GOOD: `providers: provider_names` in the model, then `- if file[:providers].present?` in the view

## Local Variables That Shadow Method Names

When a local variable name would shadow a same-class method name, prefix the local with context to make the distinction clear.

**Examples:**
- ❌ BAD: `provider_names = []` inside a method that also defines `def provider_names`
- ✅ GOOD: `note_provider_names = []`

## No Backslash String Line Continuation

Never split strings across lines using `\` — write the full string on one line. Long lines are acceptable.

**Examples:**
- ❌ BAD:
  ```ruby
  Rails.logger.error(
    "[MyClass] something went wrong for " \
    "id=#{record.id} status=#{record.status}"
  )
  ```
- ✅ GOOD:
  ```ruby
  Rails.logger.error(
    "[MyClass] something went wrong for id=#{record.id} status=#{record.status}"
  )
  ```

## Parallel Array Building — Prefer Explicit Init + Shovel

When building two parallel arrays from a single collection, declare the arrays first and shovel into them — do not use `each_with_object` with destructured accumulators.

**Examples:**
- ❌ BAD:
  ```ruby
  names, ids = items.each_with_object([[], []]) do |item, (n, i)|
    n << item.name
    i << item.id
  end
  ```
- ✅ GOOD:
  ```ruby
  names = []
  ids = []
  items.each do |item|
    names << item.name
    ids << item.id
  end
  ```

## No Ternary Operators

Never use ternary operators (`condition ? a : b`) — always use `if/else` instead. Applies to Ruby and JavaScript/CoffeeScript.

**Exception:** Ternaries are acceptable inside scope lambdas where the `if/else` alternative would be significantly more verbose.

**Examples:**
- ❌ BAD: `obj.is_a?(Hash) ? obj[segment] : obj.public_send(segment)`
- ✅ GOOD:
  ```ruby
  if obj.is_a?(Hash)
    obj[segment]
  else
    obj.public_send(segment)
  end
  ```
- ✅ ACCEPTABLE (scope lambda): `scope :for_trigger, ->(source, action) { active.where(organization: source.respond_to?(:organization) ? source.organization : nil) }`

## No Assigning the Result of a Conditional Block

Never write `variable = if condition ... end` — assign inside each branch instead. Applies to `if/else`, `case/when`, and any conditional block.

**Examples:**
- ❌ BAD:
  ```ruby
  dv = if has_history
    current_dv.paper_trail.version_at(timestamp) || current_dv
  else
    current_dv
  end
  ```
- ✅ GOOD:
  ```ruby
  if has_history
    dv = current_dv.paper_trail.version_at(timestamp) || current_dv
  else
    dv = current_dv
  end
  ```

## No Combined Assignment and Control Flow

Never combine a variable assignment with a control flow keyword (`break`, `return`, `next`) on the same line. Assign first, then control flow on the next line.

**Examples:**
- ❌ BAD: `break current_value = nil`
- ❌ BAD: `return result = some_method`
- ✅ GOOD:
  ```ruby
  current_value = nil
  break
  ```
- ✅ GOOD:
  ```ruby
  result = some_method
  return result
  ```

## Method Naming — Keep It Short

- **Always choose the shortest name that clearly conveys intent**
- Avoid restating the subject, type, or surrounding context — the class and location already provide that
- If a name is longer than ~4 words, look for a shorter equivalent before committing to it

**Examples:**
- ❌ BAD: `manual_fee_cap_amount_not_below_historical_cap`
- ✅ GOOD: `validate_fee_cap_floor`
- ❌ BAD: `check_if_commission_fee_cap_exceeds_historical_value`
- ✅ GOOD: `commission_over_cap?`
