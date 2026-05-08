---
name: R-05 Significant decisions pause autonomy
description: When investigation surfaces a significant decision — cross-repo impact, schema/migration changes, auth/billing/money code, or ambiguous root cause — stop the autonomous chain and ask the user before spawning further agents.
---

# R-05 — Significant Decisions Pause Autonomy

## Rule

The default is: when investigator confidence is high, the chain proceeds automatically through test-writer → fix-author → draft PR. That default is **suspended** if any of these flags are raised:

1. **Cross-repo impact** — the fix would change more than one repo, or requires a coordinated deploy across services.
2. **Schema or migration changes** — any DB migration, schema change, data backfill, or change to a model's persistent shape.
3. **Auth, billing, or money-handling code** — anything in authentication, authorization, payment flows, Money/Currency objects, refund/charge logic.
4. **Ambiguous root cause** — investigator can't narrow to one likely cause, or sees multiple plausible explanations of equal weight.

When any flag is raised, the top-level skill stops, surfaces the flag(s) and the investigator's findings, and asks the user how to proceed. The user may override the gate for that issue, but the override doesn't carry to other issues.

## Why

These are the categories where automated fixes have caused or could cause outsized harm: cross-repo coordination is easy to half-finish, migrations can lock tables or lose data, auth/billing code touches user trust and money, and an ambiguous cause means the "fix" is a guess that could ship the wrong thing. The team would rather pause and think than move fast and unwind.

## How to apply

- The investigator agent's contract requires it to populate a `significant_decisions:` array in its return — empty if none, otherwise a list of the flags above with a one-line explanation.
- When the array is non-empty, the top-level does not spawn test-writer or fix-author. It presents the flags and asks.
- "Auth/billing/money" is interpreted broadly — if you're not sure, flag it. The cost of an unnecessary pause is small.
- For cross-repo changes, the right next step is usually a `/architect`-style plan, not an immediate fix. Suggest that.