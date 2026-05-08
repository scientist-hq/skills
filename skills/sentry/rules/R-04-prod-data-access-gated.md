---
name: R-04 Prod data access is gated
description: Anything that reads or replays production data — prod logs, event replay, job rerun, prod DB queries — requires explicit user approval before each call.
---

# R-04 — Prod Data Access Is Gated

## Rule

The following require explicit user approval:

- Querying production logs (e.g., Datadog, CloudWatch, BigQuery on prod tables).
- Replaying a Sentry event or session replay against any live system.
- Re-running a failed background job.
- Issuing prod DB queries via any MCP, CLI, or admin tool.
- Calling any Sentry MCP tool that triggers an action against prod (e.g., autofix, if it operates on prod).

Sentry stores event data, but reading event metadata and stack traces from Sentry's own API is fine — that's Sentry's own store, not production.

## Why

Prod data is sensitive (user PII, financial state) and prod actions can have side effects (a job rerun double-charges, a replay corrupts state). The user wants to be the one who decides each prod-touching call.

## How to apply

- Before calling any tool that might touch prod, narrate it: "to dig deeper I'd want to query prod logs for the request ID — okay?" Wait.
- If the investigator agent (or any spawned agent) needs prod context, it must surface that need back to the top-level, which surfaces it to the user. Spawned agents do not have a separate authorization surface.
- Sentry's read API and the affected repo's source are not prod data — investigate freely there.