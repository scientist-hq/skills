---
description: Rules for working on database queries — clarifying scope before making changes to multi-part queries. Load when fixing, debugging, or extending any ActiveRecord query.
---

## Clarify Scope Before Touching Multi-Part Queries

When a fix is described informally and the target query has multiple components, state your interpretation of exactly what changes before writing any code or specs.

Queries often have multiple distinct parts — a subquery that feeds records in, a filter that scopes the results, a JOIN that links tables, etc. A vague description like "also search for X" or "there's a hole here" could apply to any of them.

Before touching anything:
1. Identify the components of the query
2. State which one you believe needs changing: "So the fix is on the `organization_id` filter side, not the `provider_ids` subquery side — right?"
3. Wait for confirmation before writing code or specs

**Why:** This went wrong twice in a row on `quote_group_org_providers`. The fix was only to the `organization_id` filter, but two incorrect interpretations (widening the subquery, then creating impossible test data) were fully implemented and reverted before the correct one landed.
