---
name: test-writer
description: Spawned agent that writes a failing test reproducing a Sentry error in the affected repo's worktree. Returns the test diff for user review; does not modify production code.
---

# Test-Writer Agent

Spawn this agent after the investigator has returned high confidence and no significant decisions. The agent writes a single failing test that reproduces the Sentry error, in the same worktree.

## Tooling

Spawn with `Agent` tool, `subagent_type: general-purpose`. The agent needs Read, Edit, Write, Bash (for running the test to confirm it fails).

## Prompt template

```
You are writing a failing test that reproduces a Sentry error. The test must fail in a way that demonstrates the bug, BEFORE any fix is applied.

Working directory: <worktree-path>
Repo: scientist-hq/<repo>
Branch: sentry/<issue-id>

Sentry context:
<stack-trace, exception, relevant breadcrumbs>

Investigator's findings:
<investigator's likely_cause and proposed_approach>

Your task:

1. Locate the existing test file(s) for the code at the top in-app stack frame. Match the project's testing conventions (RSpec, Jest, pytest, etc. — read the repo's existing tests to learn the style).
2. Write ONE focused failing test that reproduces the Sentry error. Use the same exception class / message as the indicator that the bug is being hit.
3. Run the test to confirm it fails. If it doesn't fail (or fails for the wrong reason), refine until it fails for the right reason. If you can't make it fail without prod data or non-deterministic input, STOP and report.
4. Commit the test:
     git add <test-file>
     git commit -m "test: failing reproduction of <sentry-id>"

Constraints:
- ONE test. Not a suite. Smallest reproduction.
- Do NOT touch production code.
- Do NOT @-mention anyone in commit messages (R-03).
- Match existing test style in the repo. Don't introduce new test infrastructure.
- If the repo has a SKILL.md or .claude/skills/, read its testing rules first and follow them.

Return:
- Path to the test file.
- The test diff.
- The exact failure output (so the orchestrator can confirm the test fails for the expected reason).
- The commit SHA.
```

## Return contract

- Test file path + diff.
- Failure output verbatim.
- Commit SHA.

If the agent stops without committing (couldn't reproduce, needed prod data), it returns that finding instead. The chain stops.

## Why one test

A single, tight reproduction is easier to review and gives the fix-author a clear target. Adding adjacent tests is scope creep — let humans request that in PR review.
