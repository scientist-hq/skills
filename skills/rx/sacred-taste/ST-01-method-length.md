# ST-01: Methods Under 15 Lines

**Level:** SHOULD follow
**Category:** Readability

## Preference

Keep methods under 15 lines. Extract private helper methods for complex logic.

## Why

Long methods are hard to test, hard to name, and hard to understand. RX has 59+ service objects — keeping each method focused makes the codebase navigable.

## Example

```ruby
# GOOD: Short focused methods
def accept(quote_group)
  validate_acceptance(quote_group)
  update_statuses(quote_group)
  notify_stakeholders(quote_group)
end

private

def validate_acceptance(quote_group)
  raise "Already accepted" if quote_group.sow_accepted_at.present?
end

def update_statuses(quote_group)
  quote_group.update(sow_accepted_at: Time.current)
  quote_group.quotes.each { |q| q.update(status: 'accepted') }
end
```

## When to Bend

Complex `case` statements (like `LegalNameService#assay_depot_legal_name_for`) can exceed 15 lines if each branch is simple.
