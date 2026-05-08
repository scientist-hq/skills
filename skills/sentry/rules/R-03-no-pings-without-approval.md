---
name: R-03 No teammate pings without approval
description: Never @-mention, request review from, or assign a specific person without explicit user approval. Naming a candidate is fine; pinging them is not.
---

# R-03 — No Teammate Pings Without Approval

## Rule

The skill (and any spawned agent) must not, without explicit user approval:

- @-mention a person in a Sentry comment, GH issue, GH PR, or anywhere else.
- Set assignee or request review from a specific person.
- Send a Slack DM or channel message that names a person.

Naming a candidate owner in conversation with the user is fine ("based on the stack trace, this looks like Cara's area"). The line is between *suggesting* and *summoning*.

## Why

Wrong assignment is socially expensive in a small engineering team. A misplaced ping wastes someone's attention and erodes trust in automated triage. The user wants the chance to confirm or redirect every time a name lands in front of another human.

## How to apply

- When drafting a GH issue body, leave assignees blank in the draft and note "suggested owner: @handle (pending confirmation)" in the conversation, not in the issue body.
- The issue-filer agent must not pass `--assignee` or include `@handle` in the body unless the top-level explicitly tells it to (which only happens after user approval).
- If a Sentry issue already has an assignee, that's existing state — not a ping you initiated. Reading and reporting it is fine.