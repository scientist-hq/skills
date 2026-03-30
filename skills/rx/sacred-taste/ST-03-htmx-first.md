# ST-03: HTMX-First for Dynamic Interactions

**Level:** SHOULD follow
**Category:** Frontend

## Preference

Use HTMX for server-driven dynamic interactions before reaching for Stimulus or custom JS. HTMX handles most AJAX patterns (form submission, partial updates, infinite scroll) without writing JavaScript.

## RX HTMX Pattern

RX has a custom `hx()` helper in `app/modules/htmx.rb`:

```ruby
# Converts kwargs to hx-* HTML attributes
def hx(**kwargs)
  kwargs.to_h { |k, v| ["hx-#{k.to_s.dasherize}", v.to_s] }
end
```

## Usage in Views (HAML)

```haml
-# Form with HTMX submission
= form_tag search_path, method: :post, **hx(
    post: search_path,
    target: "#results",
    swap: "innerHTML transition:true",
    disabled_elt: "#submitBtn",
    trigger: "submit"
  ) do
  = text_field_tag :query

-# Out-of-band swaps for updating multiple regions
#filters{ "hx-swap-oob": "true" }
  = render "filters"

#pagination{ "hx-swap-oob": "innerHTML:.pagination-container" }
  = render "pagination"
```

## Helper Pattern

```ruby
# app/helpers/feature_helper.rb
def search_htmx(page = 1)
  hx(
    post: search_path(page: page),
    push_url: "false",
    target: "#resultsContent",
    swap: "innerHTML transition:true show:none",
    include: "input[name^='filters']:checked,.search-input"
  )
end
```

## When to Use Stimulus Instead

- Complex client-side state management
- Animations/transitions that need JS timing
- Third-party JS library integration
- Interactions that don't need a server round-trip
