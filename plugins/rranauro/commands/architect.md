Have an architectural discussion about a technical topic, exploring ideas and trade-offs before implementation.

**Topic:** $ARGUMENTS

## Ground Rules

- This is a **conversation**, not a monologue. Ask clarifying questions. Challenge assumptions. Present alternatives.
- Read relevant code and documentation before forming opinions. Don't speculate about how things work — verify.
- Keep responses focused and concise. Prefer bullet points and short paragraphs over walls of text.
- Reference specific files and line numbers when discussing existing code.

## Process

**Phase 1 — Grill the problem space (do not skip to Phase 2):**

Interrogate the problem until you and the user share a model of it. Establish what they're trying to achieve, the motivation, and constraints (security, multi-tenancy, performance, Rails conventions). Grilling rules:

- **One question at a time.** Ask, then wait for the answer before the next question — batching questions is bewildering and lets wrong assumptions slide through.
- **Recommend an answer to every question.** Don't ask open-ended; put your best guess on the table so the user can confirm or correct it.
- **Walk the decision tree.** Resolve dependencies between decisions one branch at a time — a later decision often hinges on an earlier one.
- **Look up facts; reserve decisions.** If a fact lives in the codebase (how X works, what Y calls, the current schema), read it — don't ask. The *decisions* are the user's; put each one to them.

**Gate:** Do not enter Phase 2 until the user confirms you share a model of the problem. Solutioning on a wrong problem model is the failure this phase exists to prevent.

**Phase 2 — Explore approaches:**
- Present 2-3 concrete approaches with trade-offs
- For each approach: what changes, what's the blast radius, what are the risks?
- Reference how similar problems are solved elsewhere in the codebase — prefer reusing an existing class / single entry point over introducing a parallel one.
- **Score each approach on depth.** Favor the one that hides the most behaviour behind the smallest interface — leverage for callers, locality for maintainers (change, bugs, and tests concentrate in one place). Distrust an approach that spreads logic across many shallow modules or call sites.
- **Deletion test** on any new module an approach introduces: would deleting it *concentrate* complexity or just *move* it? If it only moves complexity, it's shallow — push back before it's built.
- Discuss incrementally — don't dump everything at once. Respond to the user's reactions.

**Phase 3 — Converge on a direction:**
- Summarize the agreed approach
- Identify what can be done incrementally vs. what requires a big-bang change
- Flag any open questions that need answers before implementation

**Phase 4 — Create GitHub issues:**
When the user is ready to move to implementation, draft 1 or more GitHub issues. Present them for approval BEFORE creating anything.

Shape the issues as **tracer-bullet vertical slices**, not horizontal layers:
- Each slice cuts a narrow but COMPLETE path through every layer it touches (schema → service → controller → view → specs) — a completed slice is demoable or verifiable on its own. Do NOT file "all the models," then "all the controllers."
- Any **prefactoring** that makes the real change easy ("make the change easy, then make the easy change") is its own slice, filed first.
- **Wide mechanical refactors are the exception** (rename a column, retype a shared symbol whose blast radius fans across the codebase): sequence them expand → migrate-in-batches → contract, each step its own issue, rather than forcing a vertical slice.
- Give each issue its **Dependencies** — the issues that must complete before it can start (an issue with none can start immediately). This is the "Blocked by" edge; use it to order the set. For a stacked chain, base each PR on its blocker's branch (GitHub auto-retargets on merge).
- Use the project's **domain glossary vocabulary** in titles and descriptions — the RX nomenclature the codebase already uses, not invented jargon. If a term is fuzzy, that's a Phase 1 grilling question, not a naming guess here.

For each issue, show:
```
Title: [concise, actionable title]
Labels: [relevant labels]
---
## Problem / Motivation
[Why this change is needed]

## Proposed Approach
[What we agreed on, with enough detail for an implementer]

## Acceptance Criteria
- [ ] [Specific, verifiable criteria]

## Implementation Notes
[Key decisions, trade-offs, files to touch, gotchas]

## Dependencies
[Other issues that must come first, or that this unblocks]
```

**Only the Acceptance Criteria are binding.** Proposed Approach and Implementation Notes are the best guess at the time of writing — a downstream plan may supersede them freely, and doing so is not a scope change or a conflict. Keep implementation detail (exact files, methods, line numbers) valuable but non-authoritative; a plan that satisfies the ACs by another route has not violated the ticket. Only rephrase or revisit an AC if the *observable outcome* itself must change.

Ask the user to confirm before running `gh issue create`. Create issues one at a time so the user can review each.

**Phase 5 — Save a plan file:**

After convergence (Phase 3), save the agreed approach to a plan file at `plans/<short-description>.md`:

```markdown
# <Topic Title>

## Context
[Brief summary of the problem and motivation]

## Agreed Approach
[The approach converged on in Phase 3, with enough detail for an implementer]

## Key Decisions
- [Decision 1 and rationale]
- [Decision 2 and rationale]

## Steps
1. [ ] [First concrete step]
2. [ ] [Second step]
3. [ ] ...

## Files to Modify
- `path/to/file.rb` - [what changes]
- ...

## Open Questions
- [Any remaining uncertainties]
```

If a GitHub issue is created in Phase 4, rename the plan file to `plans/<issue_number>-<short-description>.md` and add `Resolves #<issue_number>` under the title.

## Important

- Do NOT jump to solutions. Grill the problem first (Phase 1) and pass its gate before surveying approaches.
- Ask ONE question at a time, and always recommend an answer — never batch questions.
- Look up facts in the codebase; only put *decisions* to the user.
- Do NOT create issues until the user explicitly says they're ready.
- Do NOT make implementation changes — this is discussion only.
- If the topic is too broad, suggest narrowing scope and ask what to focus on first.
