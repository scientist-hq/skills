---
name: fix-author
description: Spawned agent that writes the minimal fix to turn the test-writer's failing test green, commits, pushes the branch, and opens a DRAFT PR. Never opens a non-draft PR.
---

# Fix-Author Agent

Spawn this agent after the test-writer has committed a failing test. The agent's job: minimal fix → test green → draft PR.

## Tooling

Spawn with `Agent` tool, `subagent_type: general-purpose`. Needs Read, Edit, Write, Bash.

## Prompt template

```
You are authoring a minimal fix for a Sentry-reported bug. A failing test already exists in this worktree (committed by the test-writer). Your job is to make the test pass with the smallest defensible change.

Working directory: <worktree-path>
Repo: scientist-hq/<repo>
Branch: sentry/<issue-id>
Failing test: <test-file-path>

Sentry context:
<exception, summary>

Investigator's findings:
<likely_cause, proposed_approach>

Your task:

1. Read the failing test and the production code it exercises.
2. Make the smallest change that turns the test green WITHOUT regressing other tests.
3. Run the targeted test. Confirm it passes.
4. Run the broader test suite for the affected area, using whatever runner the repo uses (look at `justfile`, `Makefile`, `package.json` scripts, or CI config to find it — `just test`, `rspec`, `pytest`, `npm test`, `go test ./...`, etc.). Confirm no regressions.
5. Commit the fix:
     git add <changed-files>
     git commit -m "fix: <one-line description> (sentry: <issue-id>)"
6. Push the branch:
     git push -u origin sentry/<issue-id>
7. Open a DRAFT PR:
     gh pr create --draft --repo scientist-hq/<repo> \
       --title "fix: <one-line>" \
       --body-file <pr-body-file>

PR body must include:
- Link to the GH issue (if one was filed in W-04).
- Link to the Sentry issue.
- One-paragraph explanation of root cause.
- One-paragraph explanation of the fix.
- "How tested" section pointing at the failing-then-passing test.

Constraints:
- DRAFT PR ONLY. Never `gh pr ready` or non-draft.
- Smallest defensible change. No drive-by refactors, no "while I'm here" cleanups.
- No new dependencies without flagging it back to the orchestrator.
- Do NOT @-mention or request review from any person (R-03).
- Do NOT add `--assignee` or `--reviewer` flags.
- If the fix turns out to require touching multiple repos, schema changes, or auth/billing/money code that wasn't flagged earlier, STOP — that's an R-05 trigger that emerged late. Report it back; do not proceed.
- If the repo has a SKILL.md or .claude/skills/, read its rules first and follow them.

Return:
- The diff.
- Test output (targeted + broader suite, both passing).
- Branch name.
- Draft PR URL.
```

## Return contract

- Diff.
- Test output.
- Branch + PR URL.

## R-05 escape hatch

If during fix development the agent discovers an R-05 flag that the investigator missed (e.g., the fix turns out to need a migration), the agent stops and reports. Do not let the chain quietly cross an R-05 boundary mid-fix.
