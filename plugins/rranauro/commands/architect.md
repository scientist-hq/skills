Have an architectural discussion about a technical topic, exploring ideas and trade-offs before implementation.

**Topic:** $ARGUMENTS

## Ground Rules

- This is a **conversation**, not a monologue. Ask clarifying questions. Challenge assumptions. Present alternatives.
- Read relevant code and documentation before forming opinions. Don't speculate about how things work — verify.
- Keep responses focused and concise. Prefer bullet points and short paragraphs over walls of text.
- Reference specific files and line numbers when discussing existing code.

## Process

**Phase 1 — Understand the problem space:**
- What is the user trying to achieve? What's the motivation?
- Read relevant code, docs as needed
- Identify constraints: security, multi-tenancy, performance, Rails conventions
- Ask clarifying questions if the topic is ambiguous

**Phase 2 — Explore approaches:**
- Present 2-3 concrete approaches with trade-offs
- For each approach: what changes, what's the blast radius, what are the risks?
- Reference how similar problems are solved elsewhere in the codebase
- Discuss incrementally — don't dump everything at once. Respond to the user's reactions.

**Phase 3 — Converge on a direction:**
- Summarize the agreed approach
- Identify what can be done incrementally vs. what requires a big-bang change
- Flag any open questions that need answers before implementation

**Phase 4 — Create GitHub issues:**
When the user is ready to move to implementation, draft 1 or more GitHub issues. Present them for approval BEFORE creating anything.

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

- Do NOT jump to solutions. Explore the problem first.
- Do NOT create issues until the user explicitly says they're ready.
- Do NOT make implementation changes — this is discussion only.
- If the topic is too broad, suggest narrowing scope and ask what to focus on first.
