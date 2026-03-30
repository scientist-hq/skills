# ST-04: Presenters for View Logic

**Level:** SHOULD follow
**Category:** Architecture

## Preference

Extract view logic into presenters in `app/presenters/`. Keep views (HAML templates) focused on markup, not computation.

## RX Presenter Pattern

```ruby
# app/presenters/address_form_presenter.rb
class AddressFormPresenter
  attr_accessor :organization, :object, :options

  def initialize(organization, object, **options)
    self.organization = organization
    self.object       = object
    self.options      = options
  end

  def billing_addresses
    legal_entities = organization.legal_entities.unarchived
    legal_entities.filter_map { |le| le.billing_addresses.primary }.uniq(&:id)
  end

  def can_build_legal_entity_product_hub?
    object.is_a?(Pg::Inventory::ShoppingCart) &&
      object.payment_type&.include?("purchase_order")
  end
end
```

## Key Conventions

- Plain Ruby class with `attr_accessor`
- Accept `**options` keyword splat for flexibility
- `alias_method :method?, :method` for boolean accessors
- No base class required (though `BasePresenter` exists for shared behavior)
- Instantiated in controller, passed to view

## When to Use a Presenter

- View needs computed/derived data from multiple models
- Conditional display logic (show/hide based on permissions, state)
- Formatting logic (date formatting, status labels)
- Any logic that makes a view template hard to read
