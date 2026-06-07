---
description: Shared PR review criteria and constraints for review subagents. Covers what to check, RX-specific patterns, feedback style, and what not to flag.
---

## What to Check

- **Logic & Correctness** — does the code do what it claims?
- **Bugs & Edge Cases** — obvious bugs, nil handling, boundary conditions, missing guards
- **Patterns & Conventions** — does it follow RX codebase patterns?
- **Performance** — N+1 queries inside loops, missing eager loading, expensive operations in hot paths
- **Testing** — are specs adequate? Do they cover the failure path and edge cases?
- **Error Handling** — are errors handled appropriately?

## RX-Specific Patterns

- Business logic in services, not models
- View logic in presenters
- Stimulus for JavaScript (not legacy patterns)
- ActiveStorage for file uploads (not Paperclip)
- Proper indexing on foreign keys
- Money gem for currency handling
- strong_migrations patterns for all migrations
- New files in the correct locations per `CLAUDE.md`

## Feedback Style

- Provide specific file paths and line numbers
- Explain WHY something is an issue, not just that it is
- Suggest alternatives when pointing out problems
- Acknowledge good patterns when you see them

## What Not to Flag

**Don't flag pre-existing intentional patterns:**
- If a pattern has a comment explaining it or is clearly established across the codebase, it is not a bug introduced by the PR — skip it
- Only flag things that the PR itself introduced or changed

**A DB query in an AJAX endpoint is not an N+1:**
- Each AJAX request is a fresh controller action — there is no outer loop
- Only flag N+1s where a query fires inside a loop within a single request

**A constant's home is valid if its namespace communicates meaning:**
- Only flag constant placement if the location is genuinely confusing or causes a coupling problem

**Never flag potential Rubocop violations:**
- Do NOT note style issues, spacing, naming, or any other concern Rubocop would catch
- Rubocop runs automatically on the PR — only flag things it cannot catch: logic bugs, design concerns, missing error handling, performance issues, security vulnerabilities, test gaps

**Before flagging a missing registry entry, verify the live UI's data source:**
- Constants like `DIRECTIVE_NAMES` may only drive legacy forms — the BS5 UI may use a different source (e.g. `available_type_options`)
- Trace the actual controller action and view before flagging a gap
