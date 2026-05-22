---
description: Structure and behavior of the preferred suppliers feature — two systems (annotation-based vs. join table), how the badge renders, and how to find a quote group that demonstrates the feature in any dev environment.
---

## Preferred Suppliers

## Two Systems

There are two separate systems that can mark a supplier as "preferred":

1. **Annotation-based** — stored as provider capability/certification annotations. Shows a green "Preferred" pill in the Badges column of modals. NOT scoped to a specific quote group.
2. **Join table** (`PreferredQuoteGroupProvider`) — stored in `preferred_quote_group_providers`, scoped to a specific quote group. Shows a **blue seal icon** (`fa-solid fa-seal text-primary`) next to the supplier name.

These are visually distinct. When the user asks about the preferred supplier badge, they almost certainly mean the blue seal (join table), not the green annotation pill.

## Join Table Structure

```ruby
PreferredQuoteGroupProvider
  quote_group_id  # FK to quote_groups
  provider_id     # FK to providers
```

The `QuoteGroup` model exposes:
```ruby
has_many :preferred_providers, through: :preferred_quote_group_providers, source: :provider, class_name: 'Pg::Provider'
```

## Finding a Quote Group That Shows the Badge

Three conditions must ALL be true for the blue seal to appear in the supplier list:

1. A `PreferredQuoteGroupProvider` record exists linking the quote group to a provider
2. That provider has a `QuotedWare` on that quote group (`quoted_wares.provider_id` matches)
3. That quoted ware is `participating?` — meaning it has proposals OR has `responded?`

**"Internal Review" quoted wares are NOT participating** — the supplier won't appear in the list at all, so the badge has nowhere to render.

### Rails console query to find a suitable quote group

```ruby
# Find a quote group where a preferred provider (join table) has submitted a proposal
PreferredQuoteGroupProvider.all.each do |p|
  qg = Pg::QuoteGroup.find(p.quote_group_id)
  qw = qg.quoted_wares.find_by(provider_id: p.provider_id)
  next unless qw
  next unless qw.proposals.exists?
  org = qg.organization
  puts "#{org.subdomain}.test/quote_groups/#{qg.uuid}"
end
```

## Where the Badge Renders

The blue seal appears next to the supplier name in:
- Main supplier list (`_dashboard_beta_supplier_overview`) — only for `participating?` quoted wares
- Proposals tab (`_dashboard_beta_proposal`)
- Manage Legal modal (`_legal_manager`) — server-rendered, works automatically
- Send to Suppliers modal (`_legal_manager` via AJAX) — requires `@preferred_provider_ids` set in the `legal_manager` controller action
- Files form (`_files_form`)
- Send Message modal (`_dashboard_beta_multiple_recipient_message`)

## Instance Variable

All views check `@preferred_provider_ids`, set as:
```ruby
@preferred_provider_ids = PreferredQuoteGroupProvider.where(quote_group: @quote_group).pluck(:provider_id)
```

This must be set in every controller action that renders a partial containing the badge check — not just `show`.
