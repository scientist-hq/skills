---
description: Canonical patterns for creating CPO and PPO records in specs, including the required through-association between them and purchase_orders_only scope requirements.
---

# Test Data — Purchase Order (CPO + PPO)

**Prerequisites:** a SOW proposal, a quoted_ware, a provider, a quote_group, and a user — see `test-data-proposal.md` and `test-data-request.md`.

## How the association works

`Pg::Proposal#customer_purchase_orders` is a **through association** via `provider_purchase_orders`. A CPO alone is not enough — the PPO is what links the CPO to the proposal. Both must be created.

Both `Pg::CustomerPurchaseOrder` and `Pg::ProviderPurchaseOrder` use STI on the `purchase_orders` table via `Pg::PurchaseOrderBase`.

The `purchase_orders_only` scope (used by the through association) filters on `po_number IS NOT NULL AND po_created_at IS NOT NULL`. A CPO missing either field will be invisible via `proposal.customer_purchase_orders`.

## Helper

```ruby
def create_purchase_order_for(sow, po_created_at:)
  cpo = Pg::CustomerPurchaseOrder.create!(
    quote_group:   quote_group,
    user:          user,
    shipping:      Pg::Shipping.new(cost: 0.0, free_shipping: true, tax: Pg::Tax.new(amount: 0.0)),
    currency:      Pg::Currency.new(currency: 'USD'),
    po_number:     "PO-#{SecureRandom.hex(4)}",
    po_created_at: po_created_at
  )
  Pg::ProviderPurchaseOrder.create!(
    quote_group:             quote_group,
    user:                    user,
    shipping:                Pg::Shipping.new(cost: 0.0, free_shipping: true, tax: Pg::Tax.new(amount: 0.0)),
    currency:                Pg::Currency.new(currency: 'USD'),
    quoted_ware:             quoted_ware,
    provider:                provider,
    ad_po_number:            "SCI-#{SecureRandom.hex(4)}",
    po_created_at:           po_created_at,
    customer_purchase_order: cpo,
    proposal:                sow
  )
  cpo
end
```

The helper returns the CPO. The PPO is a side effect that wires the CPO to the SOW.

## Usage

```ruby
let!(:sow_cpo) { create_purchase_order_for(sow, po_created_at: 3.weeks.ago) }
```

## Gotchas

- **Both CPO and PPO are required.** The through-association goes CPO → PPO → proposal. Creating only a CPO leaves it disconnected.
- **`po_number` and `po_created_at` must both be set** on the CPO or it will be filtered out by the `purchase_orders_only` scope.
- **`Pg::Currency`, `Pg::Shipping`, `Pg::Tax` are value objects** — use `.new`, not `create!`.
- **The PPO needs `proposal: sow`** (the SOW, not the amendment) — this is what `sow.customer_purchase_orders` queries against.
