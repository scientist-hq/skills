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
- Say **tested**, never "pinned" / "pinning" / "pins", when a spec covers a behaviour. The word appears in some comments and PR bodies in this repo — do not mirror it back
- For a spec that runs code but would still pass if that code broke, describe it rather than labelling it: "the spec runs the guard but never checks the flat list, so reverting it leaves the spec green"

## Pre-Existing Bugs

**A real bug that predates the PR still gets reported — labelled as pre-existing.** Dropping it loses the finding. Reporting it unlabelled sends the author to fix something they did not break, and can pull a live bug fix into a PR that promised to change nothing on deploy.

- **Verify it against the base branch — never guess.** Read the file there (`git show main:rx/app/models/foo.rb`) and check the branch's own diff for it.
- **Watch the pathspec.** Pathspecs are relative to the current directory while revisions are not, so from inside `rx/` use `git diff main...HEAD -- app/models/foo.rb`. A repo-root path matches nothing and returns an empty diff that reads as "unchanged".
- **Say which it is in the finding itself**, alongside the claim — not in a footnote.
- **Say what the PR changed about its reachability.** A pre-existing bug the PR makes newly reachable matters more than one it leaves alone, and that is usually the author's next question.
- **Flag it when a fix does not belong in this PR.** If the bug is live and the PR changes nothing on deploy, say the fix belongs in its own PR rather than folding it in.

**Examples:**
- ❌ BAD: "`groups_missing_turnaround` trusts the submitted flag, so a supplier can clear a mandate the customer set."
- ✅ GOOD: "`groups_missing_turnaround` trusts the submitted flag, so a supplier can clear a mandate the customer set. Pre-existing: `main:app/models/pg/proposal.rb:406` is identical, and the branch's only change to that file is two lines. The lock work does not reach it."

## What Not to Flag

**Don't flag pre-existing intentional patterns:**
- If a pattern has a comment explaining it or is clearly established across the codebase, it is not a bug introduced by the PR — skip it
- This covers deliberate patterns, not defects. A genuine pre-existing bug is still reported, labelled — see **Pre-Existing Bugs**

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
