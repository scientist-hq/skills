---
name: R-01 Top-level skill is read-only
description: The top-level sentry triage skill never takes external actions. It reads, classifies, plans, talks to the user, and spawns agents. Spawned agents are the only place writes happen.
---

# R-01 — Top-Level Skill Is Read-Only

## Rule

The top-level sentry triage skill **does not write** to any external system. It does not:

- Update Sentry state (resolve, ignore, assign, comment).
- Open GitHub issues or PRs.
- Modify code on disk in the affected repo.
- Send messages to Slack or any other channel.
- Run jobs, replay events, or query prod data.

What it *does*: read Sentry, read GitHub issues and code, read documentation, classify the issue, propose actions to the user, and spawn agents to carry out approved actions.

## Why

The user explicitly requested this separation: top-level discusses and plans; agents act. Writes from the top-level surface bypass the user's review surface. Forcing every action through a spawned agent makes the action visible (the agent's prompt and result are reviewable) and gives the user a clean approval point.

## How to apply

- When you find yourself about to call a write-capable tool from the top-level, stop. Ask: "is this a spawned-agent job?" If yes, draft the agent prompt and present it for approval.
- If the user asks the top-level to "just go do X" (e.g., "just close it"), restate the action you'd take and the gate it falls under. Don't shortcut R-01 even on user request without an explicit override for that turn.
- The Sentry MCP exposes both read and write tools. Only call its read tools from the top level.