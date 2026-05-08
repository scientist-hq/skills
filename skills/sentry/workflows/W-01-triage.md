---
name: W-01 Triage a single Sentry issue
description: End-to-end flow for processing one Sentry issue — read, classify, identify owner, dedupe, decide, and either resolve-as-noise, link-to-existing, or spawn the file+investigate chain.
---

# W-01 — Triage a Single Sentry Issue

The top-level skill follows this when given a Sentry issue URL or ID. WORKFLOW.md is the canonical sequence; this file is the actionable checklist.

## Step 1 — Fetch

Use the Sentry MCP's read tools (specific tool names vary by MCP implementation — call whichever tools your MCP exposes for these data needs):

- Issue metadata: summary, status, assignee, project, first/last-seen, event count.
- Latest event: stack trace (with frames + in-app flags), breadcrumbs, tags, request context.
- Linked GH issues / PRs (Sentry's GitHub integration may already have linked one).

Output a one-screen summary to the user before moving on.

## Step 2 — Classify

Choose one:

- **noise** — bot user-agent, expected client error (e.g., user disconnected), third-party SDK noise that we don't own.
- **duplicate** — Sentry's GH integration already links an open issue, OR W-02 will likely find one (run W-02 to confirm before declaring duplicate).
- **new bug** — proceed to file + investigate.

If signals conflict (e.g., looks like noise but event count is climbing), surface the conflict and ask.

## Step 3 — Identify owner (always ask)

Per R-05 owner rule: do not infer. Propose a candidate based on:

- Top in-app stack frame's file path.
- Sentry project name.
- The user's working directory if they're already in a Scientist repo.

Then ask: "I think this belongs to `<repo>` — confirm or correct?" Wait for the user.

Do **not** name a specific person as owner here. R-03.

## Step 4 — Dedupe (W-02)

Run W-02 against the confirmed repo. Surface any matching open GH issues. If found, jump to Step 6 with outcome=duplicate.

## Step 5 — Decide

Based on classification:

- **noise** → Step 6 (resolve-as-noise).
- **duplicate** → Step 6 (link).
- **new bug** → spawn W-04 (file GH issue) **and** W-03 (investigation).

## Step 6 — Act on the decision

### noise

Draft the Sentry write: "I'd resolve as noise with comment '<reason>'. Approve?" R-02 gate. On approval, call the Sentry write tool. Done.

### duplicate

Recommend linking the Sentry issue to the existing GH issue. R-02 gate on the Sentry-side link. On approval, link via Sentry MCP. Done.

### new bug

1. Spawn **issue-filer** (W-04). Returns a draft issue body.
2. Show draft to user. On approval, agent submits via `gh issue create`.
3. Spawn **investigator** (W-03). Returns analysis + confidence + significant_decisions[].
4. If confidence is high and significant_decisions is empty: spawn **test-writer**. Show diff. On approval, spawn **fix-author**. Show draft PR. Done.
5. Otherwise: present findings, ask user how to proceed.
6. Recommend a Sentry write to link the new GH issue and PR back to the Sentry issue. R-02 gate.

## Step 7 — Wrap

Summarize for the user: what was done, what's pending review, what gates remain open.
