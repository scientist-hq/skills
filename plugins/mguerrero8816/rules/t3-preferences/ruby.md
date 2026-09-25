# Ruby Style Preferences

## Model Method Ordering

Use this order in Rails models:

1. `include`, `extend`, `delegate`, and `attr_*`
2. Associations
3. Validations
4. Scopes
5. Instance methods, including `to_param`

## Nil or Empty Arrays — `present?` in the View

Check `collection.present?` in the view. Do not call `.presence` on the array in the model to change `[]` to `nil`.

- ❌ BAD: `providers: provider_names.presence` in the model, then `- if file[:providers]` in the view
- ✅ GOOD: `providers: provider_names` in the model, then `- if file[:providers].present?` in the view

## Local Variables That Shadow Method Names

Add a context prefix to a local variable that has the same name as a method in the class.

- ❌ BAD: `provider_names = []` in a class that defines `def provider_names`
- ✅ GOOD: `note_provider_names = []`

## No Backslash String Continuation

Never split a string across lines with `\`. Write it on one line.

## Parallel Arrays — Declare, Then Shovel

To build two arrays from one collection, declare both arrays and shovel into them in an `each`. Do not use `each_with_object` with destructured accumulators.

```ruby
names = []
ids = []
items.each do |item|
  names << item.name
  ids << item.id
end
```

## No Ternary Operators

Use `if/else`, never `condition ? a : b`, in Ruby, JavaScript, and CoffeeScript. A ternary is acceptable inside a scope lambda.

- ✅ ACCEPTABLE: `scope :for_trigger, ->(source, action) { active.where(organization: source.respond_to?(:organization) ? source.organization : nil) }`

## No Assignment From a Conditional Block

Never write `variable = if …` or `variable = case …`. Assign inside each branch.

```ruby
if has_history
  dv = current_dv.paper_trail.version_at(timestamp) || current_dv
else
  dv = current_dv
end
```

## No Assignment and Control Flow on One Line

Never write `break x = nil` or `return result = some_method`. Assign on one line. Put `break`, `return`, or `next` on the next line.

## Short Method Names

Use the shortest name that makes the intent clear. Do not repeat the class or the context. If a name has more than about 4 words, find a shorter one.

- ❌ BAD: `manual_fee_cap_amount_not_below_historical_cap`
- ✅ GOOD: `validate_fee_cap_floor`

## Never Put New Lines in the Middle of a Cohesive Block

Put a new statement at the end of the group it belongs to, or start a new group below it. A dependency sets only the earliest position. It does not decide the group. Below, `@canonical_lock` and `@prediction_model_names` form their own group. They do not go between the `po_context.*` lines.

```ruby
@currency = po_context.currency
@cutoff = po_context.cutoff_date
@predictions = po_context.predicted_revenues
@invoices = po_context.invoices

@canonical_lock = Revenue::CutoffDate.for(canonical: true)
@prediction_model_names = Revenue::PredictionModel.where(id: @predictions.filter_map(&:prediction_model_id).uniq).pluck(:id, :name).to_h
```
