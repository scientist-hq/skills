---
name: W-04 File a GH issue from Sentry
description: Spawn the issue-filer agent to draft a GitHub issue using the affected repo's `.github/ISSUE_TEMPLATE/` and the Sentry context. Show the draft to the user before the agent submits.
---

# W-04 — File a GH Issue from Sentry

## Goal

Create a GitHub issue in the affected repo that captures the Sentry context cleanly, respects the repo's issue templates, and links back to Sentry. Always reviewed before submission.

## Inputs

- Confirmed affected repo (from W-01 step 3).
- Sentry issue: ID, URL, summary, latest stack trace, first/last-seen, event count, environment(s), affected releases.
- Any signals from W-02 (e.g., "no dupes found").

## Step 1 — Read the repo's issue templates

Look in the affected repo at `.github/ISSUE_TEMPLATE/` for templates. When templates exist, use them — they encode whatever fields the repo's maintainers want captured.

- If a "bug report" template exists, use it.
- If multiple templates exist, present them and ask which fits.
- If no template directory exists, fall back to `templates/gh-issue-from-sentry.md` in this skill.

## Step 2 — Spawn issue-filer

Use the `Agent` tool with `subagent_type: general-purpose`. Prompt per `agents/issue-filer.md`. Pass:

- Path to the repo's chosen template (or skill template fallback).
- Sentry context.
- Explicit instructions: produce a draft, do not submit yet, do not @-mention or assign anyone (R-03).

## Step 3 — Review

Show the draft (title + body) to the user. They approve, edit, or reject.

## Step 4 — Submit (gated)

On approval, instruct the issue-filer agent to run:

```
gh issue create \
  --repo scientist-hq/<repo> \
  --title "<title>" \
  --body-file <draft-file>
```

No `--assignee`. No labels unless the user specified them. (Some templates auto-apply labels; that's fine.)

The agent returns the new issue URL.

## Step 5 — Hand back

Surface the new GH issue URL to the top-level skill. It will be needed for:

- Linking back to Sentry (R-02 gate, in W-01 step 6).
- Investigation (W-03), which references the GH issue in PR descriptions.

## Failure modes

- `gh` not authenticated → stop, ask the user to authenticate.
- Repo template ambiguous → ask, don't guess.
- Template requires fields the agent can't infer (e.g., "steps to reproduce" when reproduction is unclear) → leave a clearly-marked TODO in the draft and surface it for the user to fill in.
