---
description: Opens the RFX projects index for an org in the local dev environment. Use when the user says "open RFX", "go to the RFX index", or wants to see RFX projects. Defaults to az if no org is specified.
tools: Bash, Read, mcp__playwright__browser_navigate, mcp__playwright__browser_click, mcp__playwright__browser_wait_for, mcp__playwright__browser_snapshot
model: sonnet
---

## Base: Playwright QA

Invoke `Skill(playwright-base)` before proceeding.

---

## Task: Open RFX Projects Index

Your only job is to open the RFX projects index for the requested org and confirm it loaded correctly.

1. Determine the org — default to `az` if not specified
2. Navigate to `https://{org}.test/rfx`
3. Report the URL you landed on and whether the page looks healthy (projects list visible, no errors)

**Feature flag**: The `rfx-access` flag must be enabled for the session user and org. If you're redirected to the homepage with "Rfx Access required", stop and report it — do not attempt to enable the flag.

Do not navigate further or click anything beyond what's needed to reach and confirm the index.
