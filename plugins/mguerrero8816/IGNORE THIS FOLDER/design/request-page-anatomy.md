---
description: Map of every partial and surface on the quote_groups/show request page where provider/supplier names appear, with preferred-supplier icon status for each.
---

# Request Page Anatomy

## Controller

`QuoteGroupsController#show` — sets key instance variables including:
- `@quote_group` / `@presenter` (a `QuoteGroupPresenter`)
- `@preferred_provider_ids = PreferredQuoteGroupProvider.where(quote_group: @quote_group).pluck(:provider_id)`

The comparison controller (`QuoteGroupsProposalComparisonsController#index`) is a **separate controller** — it must set `@preferred_provider_ids` independently.

## Page Structure

```
show.html.haml
├── _dashboard_beta_status          # status bar (no provider names)
├── _dashboard_beta_next_actions    # action buttons sidebar (no provider names)
├── _dashboard_beta_meta            # request metadata sidebar
│   └── shows qg.provider_name for some request types (lines 70-75)
├── _provider_list                  # supplier list section
│   └── _dashboard_beta_quoted_wares
│       └── _dashboard_beta_supplier_overview  ← provider name + icon here
│           └── (click supplier) → quote_groups_quoted_wares/show.js  ← icon in heading
│
├── Page Pushers (slide in from right)
│   ├── #documents  →  _dashboard_beta_documents
│   │   ├── tab: Payment Documents  →  _dashboard_beta_payment_documents
│   │   │   ├── Purchase Orders   →  _dashboard_beta_purchase_order  ← icon per PPO
│   │   │   ├── Purchase Reqs     →  _dashboard_beta_purchase_order
│   │   │   └── Proposals         →  _dashboard_beta_proposal        ← icon
│   │   └── tab: Files            →  _dashboard_beta_files  ← icon in supplier tooltip
│   │
│   ├── #billing   →  shared/billing (no provider names)
│   │
│   ├── #comparison  →  _comparison
│   │   ├── _proposal_comparison_checkbox_item  ← icon in label
│   │   └── (loads via AJAX) →  quote_groups_proposal_comparisons/index
│   │       ├── _compare.html.haml (new, feature-flagged: compare_page_update)
│   │       │   └── _compare_card_header  ← icon in supplier heading
│   │       │   └── _compare_card_body    (no provider names)
│   │       └── _compare_old.html.haml (legacy, skipped)
│   │
│   └── #actions   →  _action_items (no provider names)
│
└── Modals
    ├── #purchase_dialog  →  _purchase_dialog_modal (loading shell)
    │   └── loads via HTMX →  _purchase_selection
    │       └── select_tag with @selection_dropdown  ← proposals w/ provider names
    │           (standard <select>, can't embed HTML icons — same problem as auto_negotiation)
    │
    ├── #negotiation  →  quote_groups_proposals/auto_negotiation.html.haml
    │   └── SKIPPED — has a <select> for multi-proposal case, can't embed icons
    │
    ├── #concierge_options  →  _dashboard_beta_concierge_options
    │   └── provider names in two tables  ← icon already added
    │
    ├── #multiple_recipients  →  _dashboard_beta_multiple_recipient_message
    │   └── two supplier checkbox lists (active + cancelled/declined)  ← icon already added
    │
    ├── #add_file_dialog  →  _files_form
    │   └── supplier checkbox list  ← icon already added
    │
    ├── #manage_legal  →  _legal_manager
    │   └── challenged + unchallenged supplier tables  ← icon already added
    │
    └── other modals (cancel, deadline, addresses, etc.) — no provider names
```

## Individual Proposal Page Pusher

When the user clicks a proposal link it loads `quote_groups_proposals/show.html.haml` into a page pusher. This renders `_proposal.html.haml` (the proposal PDF content). Provider identity is shown via logo image and remittance address — no standalone "provider name" text, so no icon needed.

## Surfaces with Provider Names — Status

| Partial | Provider Name Location | Icon Status |
|---|---|---|
| `_dashboard_beta_supplier_overview` | `quoted_ware.provider_name` (line 21) | ✅ Done |
| `_dashboard_beta_proposal` | `proposal.provider.name` (line 23) | ✅ Done |
| `_dashboard_beta_purchase_order` | `ppo.provider_name` per PPO (line 26) | ✅ Done |
| `_compare_card_header` | `proposal.provider_name` heading | ✅ Done |
| `_proposal_comparison_checkbox_item` | `proposal.provider.name` in label | ✅ Done |
| `_dashboard_beta_concierge_options` | `quoted_ware.provider_name` (×2) | ✅ Done |
| `_dashboard_beta_multiple_recipient_message` | `qw.provider&.name` in active + cancelled/declined lists | ✅ Done |
| `_files_form` | `quoted_ware.provider&.name` in supplier checkbox list | ✅ Done |
| `_dashboard_beta_files` | provider name in tooltip HTML on "N Supplier" label | ✅ Done |
| `_legal_manager` | `qw.provider&.name` in challenged + unchallenged tables | ✅ Done |
| `quote_groups_quoted_wares/show.js` | `@provider.name` in supplier detail panel heading | ✅ Done |
| `_purchase_selection` | `@selection_dropdown` in `select_tag` | ⏭ Skipped (HTML in `<option>` not possible) |
| `auto_negotiation` | readonly text field + `f.select` | ⏭ Skipped |
| `_compare_old` | "Name" row `proposal.provider_name` | ⏭ Skipped (legacy view) |
| `_dashboard_beta_meta` | `qg.provider_name` (lines 70-75) | Not done — low priority, context is a list/meta view |

## Key Model Notes

- `QuotedWare` — `provider_id` is the FK; use `@preferred_provider_ids.include?(quoted_ware.provider_id)`
- `Pg::Proposal` — `provider_pg_id` is the FK; use `@preferred_provider_ids.include?(proposal.provider_pg_id)`
- `Pg::ProviderPurchaseOrder` (PPO) — `provider_pg_id` is the FK; use `@preferred_provider_ids.include?(ppo.provider_pg_id)`
- Icon markup: `%i{ class: PreferredQuoteGroupProvider::ICON_CLASSES, data: { bs_toggle: "tooltip", bs_title: "Preferred" } }`
- `ICON_CLASSES = 'fa-solid fa-seal text-primary'`
