---
name: W-02 Dedupe against GH issues
description: Search the affected repo's open GitHub issues (issues only, not PRs) for matches by error signature before recommending a new issue be filed.
---

# W-02 — Dedupe Against GH Issues

## Goal

Avoid filing a duplicate. Catch the case where a teammate already filed an issue for this Sentry error.

## Scope

- Search **issues only**, not PRs. (Searching PRs is more expensive and the false-positive rate is high.)
- Search **open** issues by default. Optionally include recently-closed (last 90 days) if no open match — a closed-but-not-fixed dupe is still useful to surface.

## Inputs

- Confirmed affected repo (from W-01 step 3).
- Sentry issue: exception class, message, top in-app frame (file + symbol).
- Sentry issue ID (for cross-reference search — someone may have already mentioned the Sentry ID in an issue).

## Search strategy

Run multiple `gh` searches and union the results:

1. By Sentry issue ID:
   ```
   gh issue list --repo <owner/repo> --state open --search "<sentry-issue-id>"
   ```
2. By exception class + top frame symbol:
   ```
   gh issue list --repo <owner/repo> --state open --search "<ExceptionClass> <symbol>"
   ```
3. By exception message (first ~60 chars, quoted):
   ```
   gh issue list --repo <owner/repo> --state open --search "\"<message-prefix>\""
   ```

Each search is read-only; running them all is fine.

## Surfacing results

Present any matches to the user with:

- Issue number and title.
- Last-updated date.
- A one-line "why this might be a match" reasoning (which signal hit).

Let the user decide whether it's a real duplicate. Don't auto-classify as duplicate based on a fuzzy match.

## When nothing matches

Tell the user: "no open GH issues found by signature — proceed to file?" Then continue to W-04.

## Notes

- Repo names under Scientist.com are typically `scientist-hq/<repo>`. If unsure, ask.
- If `gh` isn't authenticated for the affected repo, stop and tell the user.
