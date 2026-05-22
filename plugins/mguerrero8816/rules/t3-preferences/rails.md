# Rails Preferences

## View Loop Membership Checks — Use Controller-Level `pluck`

When a view needs to check whether each row in a loop belongs to a set (e.g. "is this provider preferred?"), default to loading the full set once in the controller via `pluck` into an instance variable, then check membership in the view.

- ❌ BAD: Model methods that query per row (N+1), or methods that take two IDs when one object already implies the other
- ✅ GOOD: `@preferred_provider_ids = PreferredQuoteGroupProvider.where(quote_group: @quote_group).pluck(:provider_id)` in the controller, then `@preferred_provider_ids&.include?(quoted_ware.provider_id)` in the view

Only reach for a model method if the membership logic is complex enough to warrant encapsulation.
