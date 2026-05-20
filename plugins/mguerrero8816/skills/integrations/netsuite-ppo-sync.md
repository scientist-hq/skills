# Syncing a PPO/CPO to NetSuite Dev

These steps assume you have an existing PPO and CPO that need to be sent to NetSuite.
We modified existing records (PPO #7, CPO #6) rather than creating new ones.

## How to Use This

1. Find your PPO: `ppo = Pg::ProviderPurchaseOrder.find(<id>)`
2. Derive cpo and org: `cpo = ppo.customer_purchase_order; org = cpo.organization`
3. Then follow Steps 1–6 in order
4. Before each `create!` for an address, check it doesn't already exist — use `find_or_create_by!` or check with `.present?` first to avoid duplicate errors

## Step 1: Fix Legal Entities

### Provider Legal Entity (vendor)
The PPO's `provider_billing_address` must point to a `ProviderLegalEntity` with a real netsuite_id.

```ruby
# Find the provider's legal entity
ple = Pg::ProviderLegalEntity.find_by(scientist_entity_id: ppo.provider_pg_id, scientist_entity_type: 'Pg::Provider')

# taxidnums keys must be real ISO country codes — "N/A" will be rejected by NetSuite
ple.update!(
  accounting_reviewed: true,
  taxidnums: { "US" => ple.taxidnums.values.first },
  skip_netsuite_callbacks: true
)
Netsuite::LegalEntityJob.perform_now(ple.id)
# Wait for job, then verify:
Pg::ProviderLegalEntity.find(ple.id).netsuite_id  # should be non-nil
```

### Customer Legal Entity (customer)
The CPO's billing address must point to a `CustomerLegalEntity` with a real netsuite_id.

```ruby
# Find or create — if it already exists in NetSuite dev (from a prior DB reset), create a new one
# with a unique entityid to avoid conflicts (NetSuite matches by custentity_rsm_scientist_internal_id)
new_cle = Pg::CustomerLegalEntity.create!(
  companyname: "#{org.name} DEV",
  entityid: "#{org.name.first(10).gsub(' ', '-')}-Dev-#{SecureRandom.hex(4)}",
  entity_type: "customer",
  accounting_reviewed: true,
  scientist_entity_id: cpo.customer_legal_entity.scientist_entity_id,
  scientist_entity_type: "Pg::Organization",
  taxidnums: { "US" => "123456789" }
  # no skip_netsuite_callbacks — let the after_commit fire the job automatically
)
# Wait a few seconds then verify:
Pg::CustomerLegalEntity.find(new_cle.id).netsuite_id  # should be non-nil

# Point CPO billing address at the new legal entity
Pg::BillingAddress.find_by(addressable_id: cpo.id, addressable_type: 'Pg::PurchaseOrderBase')
  .update!(legal_entity_id: new_cle.id)
```

## Step 2: Set Up Missing PPO Associations

```ruby
ppo = Pg::ProviderPurchaseOrder.find(ppo_id)
marketplace_le = Pg::MarketplaceLegalEntity.find(1)  # "The Assay Depot LLC", netsuite_id: 99001
provider = ppo.quoted_ware.provider

# Clear any fake netsuite_ids
ppo.update_columns(
  provider_pg_id: provider.id,
  quote_group_pg_id: ppo.quoted_ware.quote_group_id,
  po_created_at: ppo.po_created_at || Time.current,
  netsuite_id: nil,
  netsuite_status: 'Not Sent'
)

# Provider shipping address (polymorphic has_one)
Pg::ProviderShippingAddress.create!(
  addressable: ppo,
  organization_name: provider.name,
  street: "123 Provider St",
  city: "San Diego",
  state: "CA",
  zipcode: "92101",
  country: "US"
)

# Provider billing address pointing to the ProviderLegalEntity
Pg::ProviderBillingAddress.find_or_create_by!(
  addressable_id: ppo.id,
  addressable_type: 'Pg::PurchaseOrderBase'
).update!(
  legal_entity_id: ple.id,
  organization_name: ple.companyname,
  street: "123 Provider St",
  city: "San Diego",
  state: "CA",
  zipcode: "92101",
  country: "US"
)

# Remittance address pointing to MarketplaceLegalEntity
Pg::RemittanceAddress.create!(
  addressable: ppo,
  legal_entity: marketplace_le,
  organization_name: marketplace_le.companyname,
  person_name: "DBA Scientist.com",
  street: "329 S Highway 101, Suite 230",
  city: "Solana Beach",
  state: "CA",
  zipcode: "92075",
  country: "US"
)

# Currency
Pg::Currency.create!(exchangable: ppo, currency: "USD", conversion_rate: 1.0)

# Fix milestone provider_id so provider_purchase_order lookup works on CPO milestones
Pg::Milestone.where(itemizable_type: 'Pg::PurchaseOrderBase', itemizable_id: cpo.id)
  .update_all(provider_id: provider.id)

# Milestone title must be non-nil — SO/PO restlets call custcol_milestone_title.slice(0,998)
Pg::Milestone.where(itemizable_type: 'Pg::PurchaseOrderBase', itemizable_id: [cpo.id, ppo.id]).each do |m|
  m.update_columns(title: m.title || m.name)
end
```

## Step 3: Set Up Missing CPO Associations

```ruby
cpo = ppo.customer_purchase_order

cpo.update_columns(
  netsuite_id: nil,
  netsuite_status: 'Not Sent',
  po_created_at: cpo.po_created_at || Time.current,
  po_number: cpo.po_number || "SCI-CPO-#{cpo.id}"  # SO restlet calls tranid.slice(0,998) — must be non-nil
)

# Remittance address (also provides marketplace_legal_entity)
Pg::RemittanceAddress.create!(
  addressable: cpo,
  legal_entity: marketplace_le,
  organization_name: marketplace_le.companyname,
  person_name: "DBA Scientist.com",
  street: "329 S Highway 101, Suite 230",
  city: "Solana Beach",
  state: "CA",
  zipcode: "92075",
  country: "US"
)

# Turn around time (columns are :min and :max, NOT min_in_days/max_in_days)
Pg::TurnAroundTime.create!(turnaroundable: cpo, min: 14, max: 30)
```

## Step 4: Verify Payloads Build

```ruby
Netsuite::SalesOrderService.new(cpo).as_json  # should not raise
Netsuite::PurchaseOrderService.new(ppo).as_json  # should not raise
```

## Step 5: Send to NetSuite

```ruby
Netsuite::PoSoJob.perform_now(ppo.id)
Pg::CustomerPurchaseOrder.find(cpo.id).netsuite_id  # should be non-nil
Pg::ProviderPurchaseOrder.find(ppo.id).netsuite_id  # should be non-nil
```

## Step 6: Send Provider Invoice

Once PPO and CPO have real netsuite_ids, find or create the invoice and trigger:

```ruby
pi = ppo.provider_invoices.first  # or Pg::ProviderInvoice.find(id)
```

If no invoice exists yet, create one manually (callbacks fire before associations exist, so use `insert`):

```ruby
pba = Pg::ProviderBillingAddress.find_by(addressable_id: ppo.id, addressable_type: 'Pg::PurchaseOrderBase')
psa = Pg::ProviderShippingAddress.find_by(addressable_id: ppo.id, addressable_type: 'Pg::PurchaseOrderBase')
now = Time.current

Pg::ProviderInvoice.insert({
  purchase_order_id: ppo.id,
  provider_id: ppo.provider_pg_id,
  invoice_date: Date.today,
  invoice_number: "INV-PPO-#{ppo.id}",  # invoice_number has a NOT NULL constraint
  provider_notes: 'Test invoice',
  netsuite_status: 'Not Sent',
  provider_billing_address_id: pba.id,
  provider_shipping_address_id: psa.id,
  wholesale_subtotal_price: ppo.milestones.sum(:wholesale_unit_price),
  wholesale_total_price: ppo.milestones.sum(:wholesale_unit_price),
  retail_subtotal_price: ppo.milestones.sum(:wholesale_unit_price),
  retail_total_price: ppo.milestones.sum(:wholesale_unit_price),
  type: 'Pg::ProviderInvoice',
  status: 0,
  uuid: SecureRandom.uuid,
  created_at: now,
  updated_at: now
})

pi = Pg::ProviderInvoice.where(purchase_order_id: ppo.id).last

# Shipping record is required — taxable callbacks call shipping.tax without nil guard
Pg::Shipping.create!(
  shipable_type: 'Pg::ProviderBillingDocument',
  shipable_id: pi.id,
  cost: 0.0,
  currency: 'USD',
  free_shipping: false,
  tbd: false
)

# Invoice needs its own polymorphic ProviderBillingAddress (service ignores the direct FK column)
ple = Pg::ProviderLegalEntity.find_by(scientist_entity_id: ppo.provider_pg_id, scientist_entity_type: 'Pg::Provider')
Pg::ProviderBillingAddress.create!(
  addressable: pi,
  legal_entity: ple,
  organization_name: ple.companyname,
  street: pba.street,
  city: pba.city,
  state: pba.state,
  zipcode: pba.zipcode,
  country: pba.country
)

# Invoice also needs its own RemittanceAddress
marketplace_le = Pg::MarketplaceLegalEntity.find(1)
Pg::RemittanceAddress.create!(
  addressable: pi,
  legal_entity: marketplace_le,
  organization_name: marketplace_le.companyname,
  person_name: 'DBA Scientist.com',
  street: '329 S Highway 101, Suite 230',
  city: 'Solana Beach',
  state: 'CA',
  zipcode: '92075',
  country: 'US'
)
```

Then send:

```ruby
# provider_notes must be non-nil — NetSuite script calls memo.slice(0,998) with no null check
pi.update_columns(provider_notes: 'Test invoice') if pi.provider_notes.blank?
pi.update_columns(netsuite_status: 'Not Sent')

# Run job directly — don't use update! trick, skip_netsuite_callbacks persists on the object
Netsuite::ProviderInvoiceNetsuiteJob.perform_now(pi.id)

# Verify
pi.reload
pi.netsuite_id      # should be non-nil
pi.netsuite_status  # should be "Sent Successfully"
```

## Common Gotchas

- `taxidnums` keys must be ISO country codes (`"US"`), never `"N/A"` → NetSuite rejects with "Invalid Field Value N/A for nexuscountry"
- `Pg::TurnAroundTime` columns are `:min` / `:max`, NOT `min_in_days` / `max_in_days`
- `Pg::Currency` column is `:currency`, NOT `iso_currency_code`
- Never set fake netsuite_ids on PPO/CPO — set to nil so PoSoJob treats them as new records
- `puts` returns nil in Ruby — evaluate expressions directly to see values
- `provider_billing_address` on the PPO must point to a `ProviderLegalEntity`, NOT a `MarketplaceLegalEntity` — using the marketplace LE's netsuite_id as a vendor ID will be rejected
- If a CustomerLegalEntity already exists in NetSuite dev (conflict on `custentity_rsm_scientist_internal_id`), create a brand new one — renaming `entityid` alone won't help
- `provider_notes` on the invoice must be non-nil — the NetSuite restlet calls `context.memo.slice(0,998)` with no null check, so a null memo throws "Cannot read property 'slice' of null"
- `skip_netsuite_callbacks: true` persists on the Ruby object instance — subsequent `update!` calls on the same object also skip callbacks. Always run the job directly with `perform_now` rather than relying on the after_commit trigger
- `cpo.po_number` must be non-nil — the SO restlet calls `tranid.slice(0,998)` with no null check; set it to e.g. `"SCI-CPO-#{cpo.id}"`
- `milestone.title` must be non-nil on all CPO/PPO milestones — the SO and PO restlets call `custcol_milestone_title.slice(0,998)`; set it to `milestone.name` if blank
- `cpo.po_created_at` must be non-nil — same as PPO, set it to `Time.current` if blank
- **Provider invoices may not exist** — if `ppo.provider_invoices.first` is nil, create one manually using `insert` (bypasses taxable callbacks that crash when shipping is absent) then create the `Pg::Shipping`, polymorphic `Pg::ProviderBillingAddress`, and `Pg::RemittanceAddress` records separately
- `invoice_number` has a NOT NULL database constraint — always supply it (e.g. `"INV-PPO-#{ppo.id}"`)
- The invoice service uses the **polymorphic** `provider_billing_address` (looks up by `addressable_id/type`), not the direct `provider_billing_address_id` column — create a separate address record pointing to the invoice
- The invoice service requires its own `remittance_address` — the PPO/CPO remittance address is not reused
- `remittance_address.organization_name` on the invoice must be non-nil — NetSuite script calls `.slice()` on it; set it to the marketplace legal entity's `companyname`
- `customer_shipping_address.organization_name` (the CPO's `Pg::ShippingAddress`) must be non-nil — the `custcol_location` hash is built from `netsuite_fields` which includes `organization_name`, and NetSuite slices it; set it to the customer org name
