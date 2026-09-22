# Sentry Operations Reference

Operational details for working with the `scientist-inc` Sentry org — environment info, auth patterns, triage message formats, and the end-to-end resolution workflow.

## Environment

- **Sentry org**: `scientist-inc` (US region: `us.sentry.io`)
- **Projects**: `rx`, `benchmate`, `benchmate-tools`, `trial-insights`, `contractresearchmap`, `dracula`
- **GitHub integration**: registered under `assaydepot` (legacy name), integration ID `126670`

## Auth Pattern

**IMPORTANT:** Never interpolate tokens into command strings via f-strings or string concatenation — this leaks secrets into terminal approval messages visible in Slack. Always export to an env var first, then reference as `$VAR`.

```bash
# Using 1Password service account
export OP_SERVICE_ACCOUNT_TOKEN=$(grep OP_SERVICE_ACCOUNT_TOKEN ~/.env | cut -d= -f2-)
SENTRY_TOKEN=$(op read --no-newline "op://BotVault/SENTRY_AUTH_TOKEN/password")

# Direct curl
curl -s -H "Authorization: Bearer $SENTRY_TOKEN" \
  "https://us.sentry.io/api/0/issues/{NUMERIC_ISSUE_ID}/"
```

## Triage Slack Message Format

### Compact summary (initial post)

```
🦀 _Sentry Triage — <DATE>_

_Issue:_ <SHORT_ID> (<PERMALINK|link>)
_Error:_ `<TITLE>`
_Severity:_ <LEVEL>
_Recommendation:_ <ACTION>
<One or two sentence explanation of what happened and what should be done.>

_Reply "details" for full analysis · Reply "okay" to resolve as recommended_
```

### Expanded details (on "details" reply)

Include the full table (Project, Level, Priority, Occurrences, Users affected, First/Last seen), the classification with emoji, and extended analysis.

### Format preferences

- **No table in summary** — only shown on details request
- **No classification line in summary** — only shown on details request
- **Issue + link on one line** — `_Issue:_ RX-5QH (link)` not separate lines
- **Keep it tight** — one or two sentences max for the explanation
- **Classification emojis**: 🔇 Noise, 📋 Known/Duplicate, 🔥 Actionable

## Triage Classification Framework

1. **Noise**: Browser extensions, bot traffic, single-occurrence DOMExceptions, third-party script errors
2. **Known/Duplicate**: Matches existing GitHub issue or previously triaged Sentry issue
3. **Actionable**: First-party stacktrace, multiple users affected, or critical path (auth, checkout, API)

## End-to-End Resolution Workflow

When a triage item is actionable:

1. **Branch & Fix** — create a feature branch from `origin/main`, make the code change, commit with a message referencing the Sentry short ID (e.g. "Resolves RX-5HK")
2. **Create GitHub Issue** — match the repo's existing issue format, link the Sentry issue URL in the body
3. **Open PR** — include `Closes #<issue_number>` in the PR body so the issue auto-closes on merge
4. **Link in Sentry** — use the linking API (see `references/github-issue-linking-api.md`) to connect the Sentry issue to the GitHub issue
5. **Resolve in Sentry** — mark the Sentry issue resolved after fix is merged

### RX Issue Format

The rx repo has no formal issue templates. Follow the convention from existing issues:

```markdown
## Problem / Summary

<1-2 paragraphs: what's happening, link to Sentry issue>

## Solution

<Brief description of the fix approach>

## Acceptance Criteria

- [ ] <Verifiable outcome>
```

Include the Sentry link in the Problem section as `[RX-XXX](https://scientist-inc.sentry.io/issues/...)`.

## Cron-Based Polling (Automated Triage)

The `sentry-triage-poll` cron job (ID `ec59cf73424f`) polls every 10 minutes for new/escalating issues and delivers compact triage messages to `slack:C0B6CAX24TE`. It uses the script `~/.hermes/scripts/sentry-poll-new-issues.py` with state tracked in `.sentry-poll-state.json`.

**Key gotcha:** If the team says "we're not getting Sentry notifications," check `~/.hermes/logs/agent.log` for delivery errors — the job status will still show "ok" because the agent ran fine even when Slack delivery fails. See `references/sentry-cron-delivery-debugging.md` for full diagnostic steps.

## Posting Comments on Sentry Issues

```bash
curl -s -X POST "https://us.sentry.io/api/0/issues/{NUMERIC_ID}/comments/" \
  -H "Authorization: Bearer $SENTRY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text": "Comment text here"}'
```
