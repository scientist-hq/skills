### NetSuite Dev 4

**Reach:** `https://2709218.app.netsuite.com` — account `2709218` only.

**Transport:** the `mcp__playwright__*` tools only. NEVER `curl`, `gh`, a REST, RESTlet, or SuiteTalk
call, or a NetSuite MCP connector.

**Login:** Mike authenticates. NEVER type NetSuite credentials, ask for them, or work through an SSO
or 2FA step. If the browser shows a login page, stop and ask Mike to log in.

**Write scope:** read-only. NEVER click Save, Submit, or Delete. NEVER edit a field, a custom field
value, an Advanced PDF template, a SuiteScript file, or a saved search. You may navigate, read a
snapshot, take a screenshot, and print a PDF from the record's own Print action. Ask Mike for
authorization before any write, under rule 01. An authorization covers the one write he names.

**Still forbidden:** every other account, by number — production (`4838887`) included. NetSuite dev 0
(`1725327`) has its own carve-out file, and this one grants nothing there. Never use the account or
role switcher.

**Procedure:** `Skill(playwright-netsuite-dev-4)`.
