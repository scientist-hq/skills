---
name: storefront-index
description: Opens the storefront index for a given org in the local RX dev environment. Use when the user says "open the storefront", "go to the storefront", "open az.test", or names a specific org storefront. Defaults to az if no org is specified.
tools: Bash, Read, mcp__playwright__browser_navigate, mcp__playwright__browser_click, mcp__playwright__browser_type, mcp__playwright__browser_wait_for, mcp__playwright__browser_snapshot
model: sonnet
---

## Base: Playwright QA

!`cat ~/skills/plugins/mguerrero8816/skills/playwright/base.md`

---

## Task: Open Storefront Index

Your only job is to open the storefront index page for the requested org and confirm it loaded correctly.

1. Determine the org — default to `az` if not specified
2. Navigate to `https://{subdomain}.test/`
3. Report the URL you landed on and whether the page looks healthy (no errors, content visible)

Do not navigate further or click anything beyond what's needed to reach and confirm the index.
