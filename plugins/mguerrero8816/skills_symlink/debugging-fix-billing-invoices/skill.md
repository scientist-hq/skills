---
description: Steps to diagnose and fix errors on /billing_invoices — missing quoted_ware and RoutingError patterns.
---

# Fix Billing Invoices Page Errors

Run these steps to diagnose and fix errors on `/billing_invoices`.

## Error 1: `No route matches ... :id=>nil` (missing quoted_ware)

Invoices with `purchase_order_id: 0` or a PO with no `quoted_ware` will blow up `quoted_ware_path`.

**Find them:**
```ruby
docs = Pg::ProviderBillingDocument.all.select { |d| d.quoted_ware.nil? }
docs.each { |d| puts "id=#{d.id} type=#{d.type} invoice=#{d.invoice_number} po_id=#{d.purchase_order_id}" }
```

**Fix:** Delete the bad records (confirm with user first):
```ruby
Pg::ProviderBillingDocument.find(<id>).destroy
```

---

## Error 2: `no implicit conversion of nil into String` (missing currency)

Invoices with no associated `Pg::Currency` record will blow up `wholesale_net_total_price_display`.

**Find them:**
```ruby
Pg::ProviderBillingDocument.all.each do |d|
  begin
    d.wholesale_net_total_price_display
  rescue => e
    puts "id=#{d.id} invoice=#{d.invoice_number} currency_unit=#{d.currency_unit.inspect}"
  end
end
```

**Fix:** Create a USD currency record for each affected invoice:
```ruby
Pg::Currency.create!(
  conversion_history: {},
  conversion_rate: 1.0,
  conversion_set_at: Time.now,
  currency: "USD",
  exchangable_id: <id>,
  exchangable_type: "Pg::ProviderBillingDocument"
)
```

---

## Error 3: `undefined method 'tax' for nil` (missing shipping record)

`Pg::ProviderBillingDocument` uses `Pg::Taxable` which calls `self.shipping.send("#{tax_type}tax").amount` in `shipping_wholesale_tax_amount` / `shipping_retail_tax_amount`. If the shipping record is missing, this blows up even though the object responds to `:shipping`.

**Find them:**
```ruby
Pg::ProviderBillingDocument.left_joins(:shipping).where(shippings: { id: nil }).each do |doc|
  puts "id=#{doc.id} type=#{doc.type} uuid=#{doc.uuid}"
end
```

**Fix:** Create a shipping record (with taxes) for each affected invoice:
```ruby
Pg::ProviderBillingDocument.left_joins(:shipping).where(shippings: { id: nil }).each do |doc|
  doc.create_shipping!
  puts "Created shipping for #{doc.uuid}"
end
```

`create_shipping!` triggers `Pg::Shipping#initialize_taxes` which also creates the required `tax`, `retail_tax`, and `wholesale_tax` child records automatically.
