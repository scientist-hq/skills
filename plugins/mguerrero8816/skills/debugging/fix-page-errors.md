---
description: Default approach when a page has an error or isn't behaving as expected — fix the database, not the code.
---

## Default: Fix the Database, Not the Code

When a page has an error or isn't rendering correctly, the default assumption is that the database is in a bad state — missing records, nil associations, stale data, or incomplete setup. Fix the data so the app behaves as expected.

- **DEFAULT**: Investigate and repair data using `bundle exec rails runner`
- **EXCEPTION**: If the current conversation has been actively working on a related code change, a code fix may be appropriate
- **NEVER** edit code in response to a page error unless it's clearly code-related

## Workflow

1. Read the error or identify the broken behavior
2. Trace what data the page expects — check associations, required records, nil guards
3. Query the database to find what's missing or wrong
4. Create, update, or delete records to restore expected state
5. Reload the page and confirm the error is gone

## Last Resort: Hardcode Conditionals in Code

If the page still won't load after fixing the data, conditionals in Rails code can be temporarily hardcoded to `true` or `false` to bypass poorly understood or blocking behavior.

- Edit the conditional directly in the source file to return `true` or `false`
- This is purely investigational — the goal is to get the page to load so the actual feature can be seen
- The blocking behavior doesn't need to be fully understood; the point is to isolate it
- **ALL hardcoded conditionals MUST be reverted before committing any code**

Only reach for this when proper database setup hasn't unblocked the page and the blocking condition is outside the scope of the feature being investigated.
