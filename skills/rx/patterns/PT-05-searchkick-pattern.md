# PT-05: Searchkick Integration Pattern

## Model Setup (via Concern)

RX organizes Searchkick config in `app/modules/searchkick/` concerns:

```ruby
# app/modules/searchkick/feature_record.rb
module Searchkick
  module FeatureRecord
    extend ActiveSupport::Concern

    included do
      searchkick searchable: %i[name description status]

      # Eager-load scopes for indexing (prevents N+1 during reindex)
      scope :search_import, -> {
        includes(:organization, :category)
      }
    end

    # What gets indexed
    def search_data
      {
        name: name,
        description: description,
        status: status,
        organization_id: organization_id,
        category_name: category&.name,
        created_at: created_at
      }
    end

    # Conditional indexing
    def should_index?
      active? && !archived?
    end
  end
end
```

## Include in Model

```ruby
# app/models/feature_record.rb
class FeatureRecord < ApplicationRecord
  include Searchkick::FeatureRecord
end
```

## Searching

```ruby
# Basic search
results = FeatureRecord.search("query term")

# Filtered search
results = FeatureRecord.search("query",
  where: { organization_id: current_organization.id, status: "active" },
  order: { created_at: :desc },
  page: params[:page],
  per_page: 20
)
```

## Reindexing

```bash
# Single model
bundle exec rake searchkick:reindex CLASS=FeatureRecord

# All models
bundle exec rake searchkick:reindex:all
```

## RX Reference

`app/modules/searchkick/provider_purchase_order.rb` — demonstrates split `search_data` methods, chained `search_import` scopes, and `should_index?`.
