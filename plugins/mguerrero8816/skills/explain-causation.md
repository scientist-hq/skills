---
name: explain-causation
description: How to explain a chain of causation — exception propagation, service call flows, callback chains. Always include file and line number at every step.
---

## Explaining a Chain of Causation

When tracing how one thing leads to another, include the file path and line number at every step — not just the start and end.

This applies to:
- Exception propagation (where does an error bubble up through?)
- Service call flows (what calls what?)
- Callback chains
- Any explanation of how one thing leads to another

The person asking doesn't know exactly what's going on — that's why they're asking. Always give them the full picture with file paths and line numbers so they can navigate directly to each step.

**Format each step as:**
> `app/services/foo/bar.rb:42` — `Bar#call` raises `SomeError` because ...
> `app/controllers/foo_controller.rb:17` — rescued by `rescue_from` which ...
