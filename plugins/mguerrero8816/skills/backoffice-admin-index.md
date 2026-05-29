---
description: Canonical pattern for building backoffice admin list/index pages — controller, routes, view structure, filters, sorting, pagination, and Select2.
---

## Controller

- Namespace: `Backoffice::Admin` (or nested further, e.g. `Backoffice::Admin::Rfx`)
- File: `app/controllers/backoffice/admin/<name>_controller.rb`
- Auth: `before_action :authenticate_user!` + `before_action :ensure_admin`
- Layout: `backoffice_bs5_layout`
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

Add a `.joins` for every association column in `SORT_COLUMNS` — `includes` alone won't work for `ORDER BY` on association columns.

Every column visible in the table should have a corresponding sort option.

## Route

Add inside `namespace :admin` in `config/routes/backoffice_only.rb`. Nest further namespaces to match the controller module path:

```ruby
namespace :admin do
  namespace :rfx do
    resources :projects, only: [:index]
  end
end
```

Route helper will be `admin_<resource>_path` (not `backoffice_admin_...` — the backoffice subdomain constraint is not reflected in the helper name).

## View structure

File: `app/views/backoffice/admin/<name>/index.html.haml`

```haml
- content_for :title do
  Page Title

- add_breadcrumb "Page Title", admin_resource_path

.py-3
  %h2.my-0.fs-2 Page Title

.card
  .card-body
    = form_tag(admin_resource_path, method: :get, class: "mb-3") do
      [filter form]

    .table-responsive
      %table.table.table-sm.table-striped.align-middle.mb-0
        [table]

    - if @records.total_pages > 1
      .d-flex
        %ul.pagination.mx-auto.mt-3.mb-0
          = will_paginate(@records, renderer: WillPaginate::ActionView::BootstrapLinkRenderer, container: false)
```

Key points:
- Filters, table, and pagination all live inside **one** `.card > .card-body`
- `.card` (no `.p-0`) so the card-body padding gives the table breathing room
- Pagination is only rendered when `total_pages > 1`
- Table uses `.mb-0` to avoid double-spacing before pagination

## Filter form

Use native BS5 classes throughout — avoid custom `l-flex`, `control-label`, `form-group` classes:

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
- Filter dropdowns (non-sort): `form-select basic-full-width-select2` — Select2 auto-initialises on that class
- Sort dropdowns: plain `form-select`, no Select2
- Prompt text: Title Case (`"All Orgs"`, `"All Statuses"`, `"All Types"`)
- Text inputs: `form-control` (not `form-select`)
- No `.form-group` wrapper (removed in BS5)
- No `.control-label` (BS3/4 — use `.form-label`)
- No `.input-group-btn` wrapper (removed in BS5 — button goes directly inside `.input-group`)

## Cross-subdomain links (backoffice → storefront)

Use the storefront route helper with `host:` — do not manually construct URLs:

```ruby
rfx_project_url(project, host: project.organization.host)
quote_group_url(quote_group, host: quote_group.organization.host)
```

`organization.host` returns `"subdomain.domain"` (e.g. `"az.test"`).

## Helper for status badges

If the model has a status enum, put badge class mappings in a helper module:

```ruby
# app/helpers/backoffice/admin/<name>_helper.rb
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

- File: `spec/controllers/backoffice/admin/<name>_controller_spec.rb`
- `require 'spec_helper'` (matches sibling specs)
- Hand-roll all records — no FactoryBot
- Stub admin: `allow_any_instance_of(Pg::User).to receive(:is_admin?).and_return(true)`
- Cover: index renders, each filter param narrows results, non-admin is blocked
