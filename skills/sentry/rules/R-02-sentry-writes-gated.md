---
name: R-02 Sentry writes are user-gated
description: Any state change in Sentry (resolve, ignore, assign, comment, snooze, merge) requires explicit user approval per call. Read-only Sentry tools may be used freely.
---

# R-02 — Sentry Writes Are User-Gated

## Rule

Every Sentry-side state change requires explicit user approval, every time. This includes:

- Resolving, ignoring, archiving, or snoozing an issue.
- Assigning an owner or team.
- Commenting on the issue.
- Merging or unmerging issues.
- Bulk operations on issues.

Read-only Sentry MCP tools (fetching issues, events, breadcrumbs, search) may be used freely.

## Why

Sentry state is shared with the whole engineering team. A wrong "resolve" hides a real bug. A wrong "assign" lands on someone's queue silently. The user wants to be the one who clicks the button, even when the recommendation is obvious. This rule was set during skill design and is not negotiable per session.

## How to apply

- When the workflow says "recommend resolve-as-noise", **say** "I'd resolve this as noise — want me to draft the Sentry write?" Wait for approval. Then take the action.
- "Approval to resolve issue X" does not extend to issue Y. Each call is its own gate.
- If the user pre-authorizes a batch ("yes, resolve all three"), confirm the list back before acting.
- Comments on Sentry are writes. Drafting a comment for review is fine; posting requires approval.