---
description: Canonical patterns for creating Pg::Organization records in specs, including single org, org hierarchy, and default_values gotchas.
---

# Test Data — Organization

## Single org

```ruby
let!(:organization) do
  Pg::Organization.create!(
    name: "Test Org #{SecureRandom.hex(4)}",
    subdomain: "test-#{SecureRandom.hex(4)}",
    canonical: true
  )
end
```

## Org hierarchy

Only the root needs `canonical: true`. Children get `parent_id`.

```ruby
let!(:grandparent_org) do
  Pg::Organization.create!(
    name: "Grandparent #{SecureRandom.hex(4)}",
    subdomain: "grandparent-#{SecureRandom.hex(4)}",
    canonical: true
  )
end
let!(:parent_org) do
  Pg::Organization.create!(
    name: "Parent #{SecureRandom.hex(4)}",
    subdomain: "parent-#{SecureRandom.hex(4)}",
    parent_id: grandparent_org.id
  )
end
let!(:organization) do
  Pg::Organization.create!(
    name: "Leaf #{SecureRandom.hex(4)}",
    subdomain: "leaf-#{SecureRandom.hex(4)}",
    parent_id: parent_org.id
  )
end
```

## default_values

`Pg::Organization.create!` automatically creates a `Pg::CustomSettings::DefaultValues` record via `after_create :create_custom_settings`. Never create or destroy it manually — just update it:

```ruby
organization.default_values.update(
  commission_fee_caps: { "usd_fee_cap" => 1000 },
  commission_fee_caps_use_default: false
)
```

## Gotchas

- `default_values` is auto-created — never call `Pg::CustomSettings::DefaultValues.create!` manually for an org.
- `org.default_values` can be stale if the association was loaded before a `before` block updated the DB record. In production code, call `.reload` when fresh data is needed. In specs, keep `before` blocks that update `default_values` before the `let!` blocks that create proposals (so the amendment's `before_save` callback sees the correct state).
