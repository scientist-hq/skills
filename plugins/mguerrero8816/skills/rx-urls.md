---
description: How to build correct development URLs for the RX app — storefront vs backoffice routing, subdomain patterns, and page-specific URL rules. Load whenever constructing or providing a URL.
---

## Always Provide Live URLs

**NEVER provide placeholder URLs — always query the database and construct a real, working URL.**

- **NEVER**: `/providers/#{provider.uuid}/...`
- **NEVER**: instructions on how to generate URLs
- **ALWAYS**: use `bundle exec rails runner` to fetch real UUIDs/IDs, then return the full URL ready to copy-paste

## Domain Patterns

| App | Domain pattern | Example |
|-----|---------------|---------|
| Storefront | `https://{subdomain}.test/` | `https://az.test/quote_groups/...` |
| Backoffice | `https://backoffice.test/` | `https://backoffice.test/providers/...` |

- ❌ `https://storefront.test/` is **not** a valid URL — storefront uses org subdomains
- To get the subdomain: `record.organization.subdomain`

## Storefront vs Backoffice Routing

| Path prefix | App | Notes |
|-------------|-----|-------|
| `/quote_groups/` | Storefront | use `{subdomain}.test` |
| `/providers/` | Backoffice | use `backoffice.test` |

When in doubt: check whether the controller lives under `app/controllers/backoffice/` (backoffice) or not (storefront).

## Page-Specific URL Rules

### Request (Quoted Ware) — Backoffice

Use `/quoted_wares/:uuid/edit` — **UUID, not numeric id**.

- ❌ BAD: `https://backoffice.test/quoted_wares/10`
- ✅ GOOD: `https://backoffice.test/quoted_wares/589762de-6915-48e8-a6a4-c1d3ca244d9c/edit`

This is the edit page — it shows invoices, credits, and request details side by side.

## Workflow

1. Query the database for actual records
2. Determine if the page is storefront or backoffice (see routing table above)
3. Get the subdomain if storefront: `record.organization.subdomain`
4. Construct the complete URL with real identifiers
5. Provide the URL ready to use
