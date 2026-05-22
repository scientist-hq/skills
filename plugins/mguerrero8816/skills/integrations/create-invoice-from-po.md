---
name: create-invoice-from-po
description: Rails console recipe for manually creating a Pg::Invoice from a Pg::CustomerPurchaseOrder without going through the NetSuite-driven flow.
---

# Creating a Customer Invoice from a Purchase Order (without NetSuite)

## When to Use

- A PO exists but has no invoice and you need to create one manually for testing or data repair
- You are in a non-NetSuite environment (local dev, staging) and need an invoice to exist
- NetSuite sync is not relevant or not available

## How to Use

1. Open Rails console (`rails c`) and run the code below
2. Replace the UUID on line 1 with the actual CPO UUID you want to invoice

## Rails Console Code

```ruby
po = Pg::CustomerPurchaseOrder.where_id('REPLACE_WITH_CPO_UUID')

@invoice = Pg::Invoice.new
@invoice.currency = Pg::Currency.new(currency: po.currency.currency)
@invoice.issued_at = DateTime.now
@invoice.set_properties_from_po(po)

po.milestones.each do |po_milestone|
  @invoice.milestones << po_milestone.dup
end

@invoice.customer_billing_address = po.customer_billing_address.dup
@invoice.customer_shipping_address = po.customer_shipping_address.dup
@invoice.storefront_users_emails = @invoice.get_storefront_users_emails
@invoice.shipping ||= Pg::Shipping.new
@invoice.retail_tax ||= Pg::RetailTax.new
@invoice.quoted_ware ||= po.quoted_wares.first
@invoice.proposal ||= po.proposals.first
@invoice.discount_amount = 0.0

@invoice.save

puts "Invoice created: #{@invoice.uuid}" if @invoice.persisted?
puts "Errors: #{@invoice.errors.full_messages}" if @invoice.errors.any?
```

## Verification

After saving, verify the invoice was created:

```ruby
@invoice.persisted?          # should be true
@invoice.uuid                # invoice UUID
@invoice.purchase_order_id   # should match the CPO's id
@invoice.currency.currency   # should match the CPO's currency (e.g. "USD")
@invoice.milestones.count    # number of milestones copied from the PO
```

## Notes

- `set_properties_from_po` sets `purchase_order`, `order_request_id`, `from`, `to`, and `remittance_address` from the PO
- Milestones are duplicated from the PO (`.dup`) so the originals on the PO are unaffected
- `shipping` and `retail_tax` are initialized as empty records if they don't already exist — this is required for the `Pg::Purchasable` concern's validations
- If the PO has no milestones, the milestones loop is a no-op; the invoice is still valid
- The invoice will NOT be sent to NetSuite — use `/netsuite-ppo-sync` if NetSuite sync is needed
