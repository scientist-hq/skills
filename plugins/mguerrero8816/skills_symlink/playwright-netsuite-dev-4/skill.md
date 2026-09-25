---
description: How to read NetSuite dev 4 (account 2709218) with Playwright — a read-only remote environment, what is forbidden, and how the login handshake with Mike works. Load before any dev 4 browser navigation, record read, or template inspection.
tools: Read, mcp__playwright__browser_navigate, mcp__playwright__browser_click, mcp__playwright__browser_type, mcp__playwright__browser_wait_for, mcp__playwright__browser_snapshot, mcp__playwright__browser_take_screenshot
---

## The Account

NetSuite dev 4, account **2709218**. This skill covers that account only.

Landing page, already logged in:

```
https://2709218.app.netsuite.com/app/center/card.nl?sc=-29&whence=
```

Forbidden, with no exception: production (`4838887`) and every other account id. NetSuite dev 0
(`1725327`) has its own carve-out and its own skill — `Skill(playwright-netsuite-dev)`. This skill
grants nothing there.

The carve-out is `rules/t1-sacred/remote-env-carve-outs/netsuite-dev-4.md`. This skill is the
procedure for it, not a widening of it. Where the two disagree, the carve-out wins.

## Read-Only

**Dev 4 is read-only. Never write to it without Mike's authorization for the one named write.**

Never click Save, Submit, or Delete. Never edit a field, a custom field value, an Advanced PDF
template, a SuiteScript file, or a saved search. Do not open an edit form to "see the value" — read
the value from the view form instead.

You may do these things:

- Navigate to a record, a list, a saved search result, or a template list.
- Read a DOM snapshot.
- Take a screenshot.
- Type into a global search box or a list filter.
- Print a PDF from the record's own Print action.

If a task needs a write, stop and ask Mike. Name the record and the field. His authorization covers
that one write, and the next write needs a new one.

## Playwright Only

Reach NetSuite through the `mcp__playwright__*` tools and nothing else. Never `curl`, never `gh`,
never a REST, RESTlet, or SuiteTalk call, never a NetSuite MCP connector.

## Mike Logs In

**Never type NetSuite credentials. Never ask for them. Never work through an SSO or 2FA step.**

1. Navigate to the landing URL above.
2. Read the snapshot. If the page shows the NetSuite dashboard, you are in — continue.
3. If it shows a login form, an "Enter your verification code" page, or a session-expired notice,
   **stop**. Tell Mike the session is not live and ask him to log in, then wait.
4. After Mike says he is in, navigate to the landing URL again before you check anything. Never
   trust the pre-login browser state.

A mid-task logout looks the same. Stop and hand back the same way — do not retry the navigation.

Never use the account or role switcher. A switch moves you to an account this rule does not cover.

## Screenshots

Save to `/Users/mike/rx/rx/.claude/screenshots/`. Never inside either repo. Tell Mike the path.

A printed PDF opens in the browser's PDF viewer, which a DOM snapshot cannot read. Take a screenshot
to report what a template rendered.

## URL Patterns

Dev 4 runs the same NetSuite release as dev 0, so the dev 0 paths are the best first guess. They are
not confirmed on this account. Add a row below only after you have loaded the URL and seen it work.

| Page | URL |
|---|---|
| Dashboard | `/app/center/card.nl?sc=-29&whence=` |

All relative to `https://2709218.app.netsuite.com`.

For anything else, navigate from the NetSuite menu or the global search box rather than guessing a
URL. A wrong `.nl` path returns an error page that reads like a permissions problem.
