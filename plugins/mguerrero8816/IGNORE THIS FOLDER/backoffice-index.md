---
description: Canonical pattern for building any backoffice list/index page — controller, routes, view structure, filters, sorting, pagination, and Select2.
---

## Controller

- Namespace matches the subdirectory: `Backoffice::Admin`, `Backoffice::Accounting`, `Backoffice::Admin::Rfx`, etc.
- Layout: `backoffice_bs5_layout`
- Auth varies by namespace — `ensure_admin` for admin pages; check existing controllers in the same namespace for the right guard
- Pagination: `.paginate(page: params[:page], per_page: 25)` (will_paginate gem)

### Sorting pattern

Whitelist sort columns in a constant — never interpolate params directly into SQL:

```ruby
SORT_COLUMNS = {
  "created_at" => "table_name.created_at",
  "name"       => "organizations.name"
}.freeze

@sort_by    = SORT_COLUMNS.key?(params[:sort_by]) ? params[:sort_by] : "created_at"
@sort_order = %w[asc desc].include?(params[:sort_order]) ? params[:sort_order] : "desc"

scope = Model.joins(:association).order("#{SORT_COLUMNS[@sort_by]} #{@sort_order}")
```

- Add `.joins` for every association column used in `SORT_COLUMNS` — `includes` alone won't work for `ORDER BY` on association columns
- Every column visible in the table should have a corresponding sort option

## Route

Routes live in `config/routes/backoffice_only.rb` under the appropriate namespace. The route helper name does **not** include `backoffice_` — the subdomain constraint is invisible to the helper:

```ruby
namespace :admin do
  resources :things, only: [:index]         # => admin_things_path
  namespace :rfx do
    resources :projects, only: [:index]     # => admin_rfx_projects_path
  end
end
```

## View structure

```haml
- content_for :title do
  Page Title

- add_breadcrumb "Page Title", resource_path

.py-3
  %h2.my-0.fs-2 Page Title

.card
  .card-body
    = form_tag(resource_path, method: :get, class: "mb-3") do
      [filter form]

    .table-responsive
      %table.table.table-sm.table-striped.align-middle.mb-0
        [table]

    - if @records.total_pages > 1
      .d-flex
        %ul.pagination.mx-auto.mt-3.mb-0
          = will_paginate(@records, renderer: WillPaginate::ActionView::BootstrapLinkRenderer, container: false)
```

- Filters, table, and pagination all inside **one** `.card > .card-body`
- `.card` without `.p-0` — card-body padding gives the table breathing room
- Pagination only rendered when `total_pages > 1`
- `.mb-0` on the table to avoid double-spacing before pagination

## Filter form

Use native BS5 only — avoid custom `l-flex`, `form-group`, `control-label` classes:

```haml
.d-flex.gap-3.align-items-end.flex-wrap
  .flex-fill
    = label_tag :field, "Label", class: "form-label"
    = select_tag :field, options, prompt: "All Things", class: "form-select basic-full-width-select2"
  .flex-fill
    = label_tag :sort_by, "Sort By", class: "form-label"
    = select_tag :sort_by, options_for_select([...], @sort_by), class: "form-select"
  .flex-fill
    = label_tag :sort_order, "Direction", class: "form-label"
    = select_tag :sort_order, options_for_select([["Descending", "desc"], ["Ascending", "asc"]], @sort_order), class: "form-select"
  .input-group.flex-fill.align-self-end
    = text_field_tag :query, params[:query], class: "form-control", placeholder: "Search..."
    = button_tag type: "submit", name: nil, class: "btn btn-info" do
      %i.fa-solid.fa-search
      Search
```

- `.flex-fill` on every child — even distribution, no inline styles needed
- Filter dropdowns: `form-select basic-full-width-select2` — Select2 auto-initialises on that class
- Sort dropdowns: plain `form-select`, no Select2
- Prompt text: Title Case (`"All Orgs"`, `"All Statuses"`, `"All Types"`)
- Text inputs: `form-control` (not `form-select`)
- No `.form-group` wrapper (removed in BS5)
- No `.control-label` (BS3/4 — use `.form-label`)
- No `.input-group-btn` (removed in BS5 — button goes directly inside `.input-group`)

## Cross-subdomain links (backoffice → storefront)

Use the storefront route helper with `host:` — never construct URLs manually:

```ruby
quote_group_url(quote_group, host: quote_group.organization.host)
```

`organization.host` returns `"subdomain.domain"` (e.g. `"az.test"`).

## Helper for status badges

```ruby
STATUS_BADGE_CLASSES = {
  "draft"    => "bg-secondary",
  "active"   => "bg-success",
  "archived" => "bg-warning text-dark"
}.freeze

def model_status_badge_class(status)
  STATUS_BADGE_CLASSES.fetch(status.to_s, "bg-secondary")
end
```

In the view: `%span{ class: "badge #{model_status_badge_class(record.status)}" }`

## Spec

- `require 'spec_helper'` (matches sibling specs in `spec/controllers/backoffice/`)
- Hand-roll all records — no FactoryBot
- Stub admin where needed: `allow_any_instance_of(Pg::User).to receive(:is_admin?).and_return(true)`
- Cover: index renders, each filter param narrows results, access guard blocks unauthorised users
