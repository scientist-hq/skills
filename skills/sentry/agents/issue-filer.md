---
name: issue-filer
description: Spawned agent that drafts a GitHub issue from Sentry context using the affected repo's issue template, then submits via `gh issue create` only after the top-level confirms user approval.
---

# Issue-Filer Agent

Spawn this agent to translate a Sentry issue into a GH issue draft, then submit on approval.

## Tooling

Spawn with `Agent` tool, `subagent_type: general-purpose`. The agent needs Read, Write (for the draft file), and Bash (for `gh`).

## Prompt template

```
You are filing a GitHub issue based on a Sentry issue. You will produce a DRAFT first; you do NOT submit until the orchestrator (top-level skill) tells you the user approved.

Affected repo: scientist-hq/<repo>
Sentry issue:
- URL: <sentry-url>
- ID: <id>
- Title: <title>
- Exception: <class>: <message>
- First/last seen: <dates>
- Event count: <count>
- Environment(s): <envs>
- Affected releases: <releases>

Stack trace (top frames):
<stack-trace>

Issue template to use: <path-to-template-file-or-skill-fallback>

Your task:

1. Read the template.
2. Fill in the template using the Sentry context. For fields you can't infer (e.g., "steps to reproduce" when reproduction is unclear), write `TODO: <what's missing>` rather than guessing.
3. Title: short, specific, action-oriented (e.g., "NoMethodError on Order#total when shipping is nil"). Avoid the literal Sentry title if it's vague.
4. Body must include:
   - Link to the Sentry issue.
   - Exception class and message.
   - Stack trace (collapsed in <details> if long).
   - Environment / release info.
   - Event count and first/last seen.
5. Write the draft to a temporary file. Use `mktemp` (or the platform equivalent) to get a safe, collision-free path — do NOT hardcode `/tmp/` or any specific directory. Report the chosen path back.

Constraints:
- Do NOT submit the issue yet. Stop after writing the draft and report the draft path.
- Do NOT @-mention anyone in the body (R-03).
- Do NOT pass `--assignee` when you eventually submit.
- Do NOT add labels unless the orchestrator explicitly tells you to.

When the orchestrator confirms approval, run:

  gh issue create --repo scientist-hq/<repo> --title "<title>" --body-file <draft-path>

Return the new issue URL.
```

## Return contract

- First return: draft file path + draft title + draft body (so top-level can show the user).
- After approval: new GH issue URL.

## Failure modes

- Template references fields the agent can't fill → leave `TODO:` markers, surface them.
- `gh` not authenticated → stop, return the auth error.
- Network failure on submit → stop, do not retry; let the user decide.
