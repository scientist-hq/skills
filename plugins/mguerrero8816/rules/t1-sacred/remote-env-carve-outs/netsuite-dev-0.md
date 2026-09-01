### NetSuite Dev 0

**Reach:** `https://1725327.app.netsuite.com` — account `1725327` only.

**Transport:** the `mcp__playwright__*` tools only. NEVER `curl`, `gh`, a REST, RESTlet, or SuiteTalk
call, or a NetSuite MCP connector.

**Login:** Mike authenticates. NEVER type NetSuite credentials, ask for them, or work through an SSO
or 2FA step. If the browser shows a login page, stop and ask Mike to log in.

**Write scope:** full. Records, custom field values, Advanced PDF templates, and SuiteScript files.

**Still forbidden:** every other account, by number — NetSuite dev 4 (`2709218`) and production
(`4838887`) included. Never use the account or role switcher.

**Procedure:** `Skill(playwright-netsuite-dev)`.
