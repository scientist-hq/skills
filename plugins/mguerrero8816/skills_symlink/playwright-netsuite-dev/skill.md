---
description: How to drive NetSuite dev 0 (account 1725327) with Playwright — a fully writable remote environment, what is forbidden, and how the login handshake with Mike works. Load before any dev 0 browser navigation, PDF template print, or SuiteScript check.
tools: Read, mcp__playwright__browser_navigate, mcp__playwright__browser_click, mcp__playwright__browser_type, mcp__playwright__browser_wait_for, mcp__playwright__browser_select_option, mcp__playwright__browser_snapshot, mcp__playwright__browser_take_screenshot, mcp__playwright__browser_evaluate
---

## The Account

NetSuite dev 0, account **1725327**. This skill covers that account only.

Landing page, already logged in:

```
https://1725327.app.netsuite.com/app/center/card.nl?sc=-29&whence=
```

Forbidden, with no exception: production (`4838887`) and every other account id. Dev 4 (`2709218`)
has its own read-only carve-out and its own skill — `Skill(playwright-netsuite-dev-4)`. This skill
grants nothing there, and dev 4 stays read-only.

The carve-out is `rules/t1-sacred/remote-env-carve-outs/netsuite-dev-0.md`. This skill is the
procedure for it, not a widening of it. Where the two disagree, the carve-out wins.

## Playwright Only

Reach NetSuite through the `mcp__playwright__*` tools and nothing else. Never `curl`, never `gh`,
never a REST, RESTlet, or SuiteTalk call, never a NetSuite MCP connector. A RESTlet you are testing
gets called by the app or by Mike, not by you.

## Mike Logs In

**Never type NetSuite credentials. Never ask for them. Never work through an SSO or 2FA step.**

1. Navigate to the landing URL above.
2. Read the snapshot. If the page shows the NetSuite dashboard, you are in — continue.
3. If it shows a login form, an "Enter your verification code" page, or a session-expired notice,
   **stop**. Tell Mike the session is not live and ask him to log in, then wait.
4. After Mike says he is in, navigate to the landing URL again before you check anything. Never
   trust the pre-login browser state.

A mid-task logout looks the same. Stop and hand back the same way — do not retry the navigation.

## What You May Change

The account is fully writable: transaction records, custom field values, Advanced PDF templates, and
SuiteScript files. Two habits keep that safe.

- **Say what you are about to write before you write it.** Name the record and the field.
- **Never overwrite an Advanced PDF template with a repo file.** Each environment's template has
  drifted from the repo copy. Apply the change to the template that is there.

Never use the account or role switcher. Switching moves you to an account this rule does not cover.

## Screenshots

Save to `/Users/mike/rx/rx/.claude/screenshots/`. Never inside either repo. Tell Mike the path.

A printed PDF opens in the browser's PDF viewer, which a DOM snapshot cannot read. Take a screenshot
to report what a template rendered.

## URL Patterns

Confirmed:

| Page | URL |
|---|---|
| Dashboard | `/app/center/card.nl?sc=-29&whence=` |
| Invoice record | `/app/accounting/transactions/custinvc.nl?id=<internal id>` |

All relative to `https://1725327.app.netsuite.com`.

For anything else — the Advanced PDF template list, a saved search, a script record — navigate from
the NetSuite menu or the global search box rather than guessing a URL. A wrong `.nl` path returns an
error page that reads like a permissions problem and wastes a round trip. Add a row above only after
you have loaded the URL and seen it work.

## Printing a PDF

Open the transaction record, then use its own Print action in the UI. Do not hand-build a
`hotprint.nl` URL. Wait for the viewer, screenshot it, and report the file path.
