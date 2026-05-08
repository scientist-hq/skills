# End-to-End Workflow

The triage flow for a single unhandled Sentry issue. Top-level skill follows this; spawned agents follow their own definition files.

## 0. Preconditions

- Sentry MCP available and authenticated (R-04 still applies for any prod-data tools).
- `gh` CLI authenticated for repos under `scientist-hq/`.
- The user has provided a single Sentry issue URL or ID.

If any precondition is missing, stop and tell the user what's needed.

## 1. Read

Use the Sentry MCP to fetch:

- Issue summary, status, assignee, project, first/last-seen, event count.
- Latest event: stack trace, breadcrumbs, tags, request context.
- Linked GH issues / PRs (Sentry's GitHub integration may already have linked one — surface this before W-02).

Read-only. Do not call any Sentry tool that writes.

## 2. Classify

Pick exactly one outcome:

- **noise** — bot traffic, expected client errors, third-party noise. Recommend resolve-as-noise / ignore. Gate on R-02.
- **duplicate** — Sentry's GitHub link or W-02 found a matching open GH issue. Recommend linking and stopping.
- **new bug** — proceed to file + investigate.

If the classification is unclear, present the evidence to the user and ask. Do not guess.

## 3. Identify owner (always ask)

Per R-05 and the team's rule that owners are never inferred: present a candidate (based on stack trace path, Sentry project, or repo signals) and ask the user to confirm the affected repo and owning team. Do not @-mention anyone — naming an owner is a candidate, not a ping (R-03).

## 4. Dedupe (W-02)

Before recommending "file new GH issue", run W-02: search the affected repo's GH issues (issues only, not PRs) by error signature. Surface candidates to the user. If a match is found, jump back to step 2 with outcome=duplicate.

## 5. File a GH issue (W-04)

Spawn the **issue-filer** agent with the Sentry context and the repo's `.github/ISSUE_TEMPLATE/` (if present) — the agent must use the repo's templates when they exist. Wait for it to return a draft. Show the draft to the user and confirm before the agent submits.

## 6. Investigate (W-03)

Spawn the **investigator** agent in a git worktree of the affected repo. It returns:

- Likely root cause (with confidence: low / medium / high).
- Proposed approach (test strategy, fix sketch, scope).
- Significant-decision flags (any R-05 trigger).

Decision tree:

- Confidence **high** AND no R-05 flags → spawn test-writer, then fix-author. Each returns a draft for user review.
- Confidence **medium** → present analysis to user, ask whether to proceed to test-writer.
- Confidence **low** OR any R-05 flag → stop. Present findings; ask the user how to proceed.

## 7. Test (T from W-03)

If we proceed: spawn the **test-writer** agent in the same worktree. It writes a failing test that reproduces the Sentry error. Returns the test diff. User reviews; on approval, the test stays in the worktree for the fix-author.

## 8. Fix (F from W-03)

If we proceed: spawn the **fix-author** agent in the same worktree. It produces a minimal fix that turns the failing test green, then opens a **draft** PR. Never opens a non-draft PR (R-01 / standard team practice).

## 9. Close the loop in Sentry

Recommend (do not execute) a Sentry update: link the GH issue and PR to the Sentry issue. R-02 applies — wait for user approval before any Sentry write.

## Decision summary

| Step | Top-level acts | User gate? |
|------|---------------|-----------|
| Read Sentry | yes (read-only) | no |
| Classify | yes (proposes) | only if unclear |
| Identify owner | yes (proposes) | **always** |
| Dedupe search | yes | no |
| File GH issue | spawns agent | yes, before submit |
| Investigation | spawns agent | confidence-driven (R-05) |
| Test draft | spawns agent | yes, on test review |
| Fix + draft PR | spawns agent | yes, on PR review |
| Sentry write | no | **always** (R-02) |
| Teammate ping | no | **always** (R-03) |
| Prod data tool | no | **always** (R-04) |