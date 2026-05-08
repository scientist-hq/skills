---
name: sentry
description: Triage unhandled Sentry issues for the Scientist.com engineering team. Read-only top-level skill that classifies issues, dedupes against GitHub, and spawns specialist agents (investigator, issue-filer, test-writer, fix-author) for follow-up work. All Sentry writes, teammate pings, and prod data access are gated on user approval.
argument-hint: [issue-id-or-url]
arguments: [issue]
disable-model-invocation: true
---

# Scientist Sentry Triage

**Triage target:** `$issue`

Begin by loading WORKFLOW.md and following the W-01 sequence against the target above. The remainder of this file is reference material — rules, workflow nav, agent definitions, and setup notes.

## What this skill does

Given a single Sentry issue (URL or ID), produce a triage decision and either:

1. **Recommend Sentry-side resolution** (noise, ignore, resolve-as-noise) — gated on user approval, R-02.
2. **Link to an existing GitHub issue** when dedupe finds a match (W-02).
3. **Spawn investigation** — investigator agent reads code and proposes a path; if confident, escalates through test-writer and fix-author agents to a draft PR. Pauses at every "significant decision" (R-05).

The top-level skill **never writes** — not to Sentry, not to GitHub, not to the codebase. It reads, plans, talks to the user, and spawns agents (R-01).

## Setup

Before first use, install and authenticate the prerequisites.

### Sentry MCP

This skill requires a Sentry MCP server registered in your Claude Code MCP configuration. The skill is implementation-agnostic — it uses whichever read tools the MCP exposes for issue metadata, latest event, stack frames, and breadcrumbs.

You'll need:

- A Sentry MCP server. Use whatever your team standardizes on; the official Sentry MCP from getsentry covers the read tools this skill expects.
- An auth token (or OAuth flow) that gives the MCP read access to your Sentry org. Write access is also needed if you'll be approving Sentry-side updates per R-02 (resolve-as-noise, link to GH issue).
- The MCP registered in Claude Code (`~/.claude.json` or project `.mcp.json`).

Verify by asking Claude to fetch any issue from your Sentry org. If that round-trips successfully, you're set.

### GitHub CLI

The skill spawns agents that call `gh` directly:

- Run `gh auth status` to verify (or `gh auth login` to set up).
- Auth must cover the `scientist-hq/` repos you'll be filing issues and opening PRs against.

### Local checkouts

Spawned agents work in `git worktree`s of the affected repo. The skill will ask for the local checkout path on first use; have a clean working copy of the repos you triage against.

## Invocation

Once setup is done, invoke the skill with:

```
/sentry <issue-id-or-url>
```

Examples:

- `/sentry SCIENTIST-1234`
- `/sentry https://scientist.sentry.io/issues/1234567/`

The skill loads SKILL.md → WORKFLOW.md → W-01 and walks through triage interactively.

## Inputs

- A Sentry issue URL or ID. Single-issue invocation is the supported entrypoint.
- Sentry MCP server installed and authenticated (see Setup).
- `gh` CLI authenticated for the affected repo (see Setup).

## Rules (MUST follow)

| ID | Rule | File |
|----|------|------|
| R-01 | Top-level skill is read-only; only spawned agents take actions | rules/R-01-read-only-top-level.md |
| R-02 | All Sentry state changes require explicit user approval | rules/R-02-sentry-writes-gated.md |
| R-03 | Never @-mention or assign a teammate without approval | rules/R-03-no-pings-without-approval.md |
| R-04 | Prod data access (logs, replay, job rerun) requires approval | rules/R-04-prod-data-access-gated.md |
| R-05 | Significant decisions pause autonomy and ask the user | rules/R-05-significant-decisions.md |

## Workflows

| ID | Workflow | File |
|----|----------|------|
| W-01 | Triage a single Sentry issue end-to-end | workflows/W-01-triage.md |
| W-02 | Dedupe against GH issues by error signature | workflows/W-02-dedupe-search.md |
| W-03 | Spawn investigation in a git worktree | workflows/W-03-spawn-investigation.md |
| W-04 | File a new GH issue from Sentry context | workflows/W-04-file-gh-issue.md |

## Agents (spawned, never invoked at top level)

| Agent | Purpose | File |
|-------|---------|------|
| investigator | Read-only analysis; returns confidence + proposed path | agents/investigator.md |
| issue-filer | Opens a GH issue using the repo's template | agents/issue-filer.md |
| test-writer | Writes a failing test that reproduces the Sentry error | agents/test-writer.md |
| fix-author | Minimal fix + draft PR, in a git worktree | agents/fix-author.md |

## Templates

| File | Purpose |
|------|---------|
| templates/gh-issue-from-sentry.md | Body the issue-filer agent fills when creating a GH issue |

## Quick start

1. User runs `/sentry <issue-id-or-url>`.
2. Top-level loads SKILL.md → WORKFLOW.md → W-01.
3. W-01 walks through: read Sentry → classify → dedupe → decide → (if file+investigate) spawn agents.
4. User confirms owner (always — never inferred), approves any Sentry writes, and reviews drafts before they go live.