# ST-06: Pagy for Pagination

**Level:** SHOULD follow
**Category:** UI Pattern

## Preference

Use the Pagy gem for all pagination. It's faster and more memory-efficient than alternatives.

## Pattern

```ruby
# Controller
def index
  @pagy, @records = pagy(collection)
end
```

```haml
-# View
= render "shared/pagination", pagy: @pagy
```

## With Searchkick

```ruby
# Pagy integrates with Searchkick results
@pagy, @results = pagy_searchkick(Model.search(query, page: params[:page]))
```
