---
name: test-data-proposal
description: Canonical patterns for creating Pg::Proposal (SOW and Change Order) records in specs, including value object usage and before_save caching gotchas.
---

# Test Data — Proposal (SOW / Amendment)

**Prerequisites:** a `quoted_ware` — see `test-data-request.md`.

## Value objects

`Pg::Currency`, `Pg::Shipping`, and `Pg::Tax` are value objects with no DB table. Always use `.new`, never `create!`.

## Helper

```ruby
def create_proposal(qw, type: 'SOW', **attrs)
  Pg::Proposal.create!(
    quoted_ware:   qw,
    proposal_type: type,
    currency: Pg::Currency.new(currency: 'USD'),
    shipping: Pg::Shipping.new(cost: 0.0, free_shipping: true, tax: Pg::Tax.new(amount: 0.0)),
    **attrs
  )
end
```

## SOW

```ruby
let!(:sow) { create_proposal(quoted_ware) }
```

## Amendment (Change Order)

Amendments require both `proposal_type: 'Change Order'` AND `parent_proposal_id`. Either alone is not enough.

```ruby
let!(:amendment) { create_proposal(quoted_ware, type: 'Change Order', parent_proposal_id: sow.id) }
```

## Valid proposal_type values

`'SOW'`, `'Change Order'`

## Gotchas

- **`before_save :assign_milestone_line_numbers`** runs on every proposal save and calls `organization_context.default_value(:supplier_part_id_prefix)`, which memoizes the `OrganizationContext` and loads `org.default_values` onto the proposal object. If spec `before` blocks update `org.default_values` after the proposal is created, the cached state on the proposal object will be stale. Keep `before` blocks that configure org state before the `let!` blocks that create proposals.
