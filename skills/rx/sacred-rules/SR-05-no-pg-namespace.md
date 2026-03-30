# SR-05: No Pg:: Namespace for New Models

**Level:** MUST follow
**Category:** Architecture

## Rule

Never create new models in `app/models/pg/`. The `Pg::` namespace is legacy. New models go directly in `app/models/` or in feature-specific namespaces (e.g., `Inventory::`, `AppStore::`).

## Why

The `Pg::` namespace was an early convention that added no semantic value — it just means "PostgreSQL model," which is all of them. New feature namespaces like `Inventory::` are meaningful and group related models together.

## Incorrect

```ruby
# BAD: New model in legacy namespace
# app/models/pg/approval.rb
class Pg::Approval < ApplicationRecord
end
```

## Correct

```ruby
# GOOD: Top-level model
# app/models/approval.rb
class Approval < ApplicationRecord
end

# GOOD: Feature namespace
# app/models/inventory/catalog.rb
class Inventory::Catalog < ApplicationRecord
end
```

## Existing Pg:: Models

Many existing models use `Pg::` (e.g., `Pg::QuoteGroup`, `Pg::User`). These are fine — don't rename them. Just don't add new ones.
