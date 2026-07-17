---
description: Canonical patterns for creating Pg::Proposal (SOW and Change Order) records in specs, including value object usage, before_save caching gotchas, and creating a proposal through the real Proposals::Create path (with the minimal valid Change Order params).
---

# Test Data — Proposal (SOW / Amendment)

**Prerequisites:** a `quoted_ware` — see `test-data-request.md`.

## Value objects

`Pg::Currency`, `Pg::Shipping`, and `Pg::Tax` are value objects with no DB table. Always use `.new`, never `create!`.

## Helper

```ruby
def create_proposal(qw, type: 'SOW', **attrs)
  Pg::Proposal.create!(
    quoted_ware: qw,
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

## Creating a proposal through the real path (`Proposals::Create`)

`Proposals::Build.run` only **pre-fills** the new-proposal form — it returns an *unsaved* proposal and never persists. The actual record creation is `Proposals::Create#run` (its `save!`), which the `create` controller action calls with `proposal: nil` + form params. When a spec needs a proposal that was genuinely *created* (not just built), drive `Proposals::Create` — do not save a built proposal yourself (see `testing-spec-rules` → "Test Through the Real Persistence Path").

Minimal params to get a **Change Order** to `save!` through `Proposals::Create` (each was a real validation gate, in order encountered):

```ruby
Proposals::Create.new(
  proposal: nil,                                   # nil → Create builds fresh from params (as the controller does)
  quoted_ware: quoted_ware,
  created_by: user,
  params: {
    proposal_type: 'Change Order',
    parent_proposal_id: original_proposal.id,
    parent_purchase_order_id: parent_ppo.customer_purchase_order&.id,
    parent_provider_purchase_order_id: parent_ppo.id,   # how Create finds the parent PO
    commission_rate: 10,
    fee_assignment: 'customer',                    # 'customer' | 'supplier' | 'split' — else "Fee assignment must be selected"
    description: 'Change order',                   # proposals.description is NOT NULL
    tax_category: 'service',                       # else "Tax category must be selected"
    shipping_attributes: { free_shipping: 'true' },
    provider_shipping_address_attributes: { street: 'street', city: 'city', state: 'CA', zipcode: 'zipcode', country: 'US', organization_name: 'org' },
    provider_billing_address_attributes: { street: 'street', city: 'city', state: 'CA', zipcode: 'zipcode', country: 'US' }, # must be non-blank, else "Legal Entity (Billing Address) missing"
    currency_attributes: { currency: 'USD' },
    turn_around_time_attributes: { adjusted_min: 1, adjusted_max: 1, display_units: 'days' },
    milestones_attributes: parent_ppo.milestones.map { |m| { name: m.name, provider_id: provider.id, quantity: m.quantity, base_unit_price: m.base_unit_price, retail_unit_price: m.retail_unit_price, wholesale_unit_price: m.wholesale_unit_price, tax_rate: m.tax_rate, referential_id: m.id } }
  }
).run
```

Gotchas:
- **`state` is required** on the provider shipping address (surfaces only when a PO is later cut from the proposal).
- **CO milestones carry `referential_id`, never `milestone_group_id`** — `milestone_group_id` isn't a permitted form field, so anything that groups a CO's milestones must derive the group by walking `referential_id` → parent-PO milestone → its group.
- **Don't pass a built proposal + address params to `Create`** — the built proposal's in-memory dup'd addresses raise `FrozenError` on `assign_attributes`, and `Create` doesn't persist in-memory addresses anyway. Use `proposal: nil` + params.

## Gotchas

- **`before_save :assign_milestone_line_numbers`** runs on every proposal save and calls `organization_context.default_value(:supplier_part_id_prefix)`, which memoizes the `OrganizationContext` and loads `org.default_values` onto the proposal object. If spec `before` blocks update `org.default_values` after the proposal is created, the cached state on the proposal object will be stale. Keep `before` blocks that configure org state before the `let!` blocks that create proposals.
