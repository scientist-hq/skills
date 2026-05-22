---
name: test-data-request
description: Canonical patterns for creating Pg::QuoteGroup and Pg::QuotedWare (request) records in specs, including required address records and provider setup.
---

# Test Data — Request (Quote Group + Quoted Ware)

A "request" in the RX domain is a `Pg::QuoteGroup` with one or more `Pg::QuotedWare` records.

**Prerequisites:** organization, user — see `test-data-organization.md` and `test-data-user.md`.

## Ware + Provider

```ruby
let!(:ware) do
  Pg::Ware.create!(
    name:      "Test Ware #{SecureRandom.hex(4)}",
    slug:      "test-ware-#{SecureRandom.hex(4)}",
    snippet:   "A test ware.",
    ware_type: "CustomService"
  )
end

let!(:provider) do
  Pg::Provider.create!(name: "Test Provider #{SecureRandom.hex(4)}", contact_emails: [])
end
```

## Quote Group

`Pg::QuoteGroup` requires separate shipping and billing address records — they cannot be inlined.

```ruby
def create_quote_group_for(org, name: 'Test Quote Group')
  Pg::QuoteGroup.create!(
    name:         name,
    description:  'Test description',
    organization: org,
    user:         user,
    ware:         ware,
    shipping_address: Pg::ShippingAddress.create!(
      organization_name: "Test Org",
      person_name:       "Test User",
      street:            "123 Test St",
      city:              "Test City",
      state:             "CA",
      zipcode:           "12345",
      country:           "US"
    ),
    billing_address: Pg::BillingAddress.create!(
      organization_name: "Test Org",
      person_name:       "Test User",
      street:            "123 Test St",
      city:              "Test City",
      state:             "CA",
      zipcode:           "12345",
      country:           "US"
    )
  )
end

let!(:quote_group) { create_quote_group_for(organization) }
```

## Quoted Ware

```ruby
let!(:quoted_ware) { Pg::QuotedWare.create!(quote_group: quote_group, provider: provider) }
```
