# Rails Preferences

## Default User

Use `michael@scientist.com` as the default user for test data, new records, and "my user" queries, unless Mike says otherwise.

## Membership Checks in a View Loop — `pluck` in the Controller

When each row in a loop needs a membership check, load the set one time in the controller with `pluck`. Then check it in the view. Do not query for each row. Use a model method only when the logic is complex.

- ✅ GOOD: `@preferred_provider_ids = PreferredQuoteGroupProvider.where(quote_group: @quote_group).pluck(:provider_id)` in the controller, then `@preferred_provider_ids&.include?(quoted_ware.provider_id)` in the view
