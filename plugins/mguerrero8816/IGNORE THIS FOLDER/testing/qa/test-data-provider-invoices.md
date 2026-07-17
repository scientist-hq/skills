---
description: How to create test Pg::ProviderInvoice records in local development for manual QA.
---

## Why Not `create!`

`Pg::ProviderInvoice` callbacks expect associated shipping and tax records that don't exist yet — `create!` fails. Use raw SQL to insert the record, then create the associations manually.

## Status Enum

| Status | Integer |
|--------|---------|
| `in_review` | 0 |
| `rejected` | 1 |
| `sent_to_customer` | 2 |
| `cancelled` | 3 |
| `processing` | 4 |

## Step 1 — Insert via Raw SQL

Open a Rails console (`bundle exec rails console`) and run:

```ruby
provider_id = Pg::Provider.first.id
po_id = Pg::CustomerPurchaseOrder.first.id

ActiveRecord::Base.connection.execute(<<~SQL)
  INSERT INTO provider_billing_documents (
    type, status, uuid, invoice_number, invoice_date,
    provider_id, purchase_order_id,
    retail_subtotal_price, retail_total_price,
    wholesale_subtotal_price, wholesale_total_price,
    netsuite_status, created_at, updated_at
  ) VALUES (
    'Pg::ProviderInvoice', 0, gen_random_uuid(), 'TEST-INV-1', NOW(),
    #{provider_id}, #{po_id},
    1000.0, 1100.0, 900.0, 1000.0,
    'Not Sent', NOW(), NOW()
  )
SQL
```

Repeat with different `invoice_number` values for multiple records.

## Step 2 — Create Shipping + Currency Records

Without these, any page rendering invoice data throws nil errors. For each new invoice:

```ruby
doc = Pg::ProviderBillingDocument.find_by(invoice_number: 'TEST-INV-1')

# Creates shipping + tax child records automatically
doc.create_shipping!

# Creates the currency record required for price display
Pg::Currency.create!(
  conversion_history: {},
  conversion_rate: 1.0,
  conversion_set_at: Time.now,
  currency: "USD",
  exchangable_id: doc.id,
  exchangable_type: "Pg::ProviderBillingDocument"
)
```

See `skills/debugging/fix-billing-invoices.md` for how to diagnose missing shipping or currency records on existing invoices.

## Step 3 — Reindex

```ruby
Pg::ProviderBillingDocument.reindex
```

