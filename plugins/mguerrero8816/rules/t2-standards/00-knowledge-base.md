# Knowledge Base

A local knowledge base exists at `~/knowledge/`. It contains domain reference material for the RX platform and related integrations. Consult it when you need context about how something works before writing code, debugging, or making architectural decisions.

## Structure

```
~/knowledge/
  rx/
    data-models/     Pg:: record creation patterns (organization, user, proposal, purchase-order, request)
    features/        Feature internals (preferred-suppliers, fee-cap-rules)
    ui/              Page anatomy, layout patterns, partial context behaviour
    debugging/       Known error patterns and fixes (billing-invoices, etc.)
    urls.md          URL patterns for storefront and backoffice
  integrations/
    netsuite/        SuiteScript reference, PPO/CPO sync gotchas
  testing/
    rspec.md         RSpec conventions for this codebase
  workflows/
    playwright/      Widget behaviour and gotchas for browser automation flows
```

## When to Use It

- Before writing or editing code that touches a feature — check `rx/features/`
- Before writing specs — check `rx/data-models/` and `testing/rspec.md`
- Before building a backoffice page — check `rx/ui/backoffice-index-patterns.md`
- Before a NetSuite task — check `integrations/netsuite/`
- Before a Playwright automation task — check `workflows/playwright/`

## Separation of Concerns

- **Skills** (`~/skills/plugins/mguerrero8816/skills/`) — procedure: how to do things step by step
- **Knowledge** (`~/knowledge/`) — reference: what things are, how they work, known gotchas
