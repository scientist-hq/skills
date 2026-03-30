# SR-03: N+1 Query Prevention

**Level:** MUST follow
**Category:** Performance

## Rule

Every ActiveRecord query that loads associated records MUST use `includes`, `preload`, or `eager_load` to prevent N+1 queries.

## Why

RX serves large pharmaceutical companies with thousands of records per organization. A single N+1 on a listing page can generate 1000+ queries and cause request timeouts. Skylight monitoring flags these in production.

## Incorrect

```ruby
# BAD: N+1 — each iteration fires a separate query
quote_groups = QuoteGroup.where(request_id: request.id)
quote_groups.each { |qg| qg.quotes.map(&:total) }

# BAD: N+1 in a presenter
def suppliers
  @quote_groups.map { |qg| qg.provider.name }
end
```

## Correct

```ruby
# GOOD: Eager load associations
quote_groups = QuoteGroup.where(request_id: request.id).includes(:quotes)
quote_groups.each { |qg| qg.quotes.map(&:total) }

# GOOD: Chain includes for nested associations
QuoteGroup.includes(quotes: :provider).where(request_id: request.id)

# GOOD: Use preload when you need separate queries (avoids join ambiguity)
QuoteGroup.preload(:quotes, :provider).where(request_id: request.id)
```

## Searchkick Pattern

RX uses `search_import` scopes to eager load for indexing (see PT-05):

```ruby
scope :search_import, -> {
  model_search_import.address_search_import.currency_search_import
}
scope :address_search_import, -> { includes(:customer_shipping_address, :provider_shipping_address) }
```

## Validation

```bash
# Run specs — Bullet gem will flag N+1 queries in test output
bundle exec rspec spec/path/to/spec.rb
```
