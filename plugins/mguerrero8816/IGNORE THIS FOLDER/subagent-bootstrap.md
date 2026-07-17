---
description: Shared preamble to include verbatim in every subagent prompt. Bootstraps the subagent with the same tiered rules the main session loads at startup.
---

## Subagent Bootstrap — Read This First

Before doing anything else, load all personal rules in this order:

1. Read ALL files in `~/skills/plugins/mguerrero8816/rules/t1-sacred/` in numeric order (01 through 07)
2. Read `~/skills/plugins/mguerrero8816/SKILL.md`
3. Read ALL files in `~/skills/plugins/mguerrero8816/rules/t2-standards/`
4. Read ALL files in `~/skills/plugins/mguerrero8816/rules/t3-preferences/`
5. Read ALL files in `~/skills/plugins/mguerrero8816/rules/t4-defaults/` (if the directory exists)

Then check the SKILL.md routing table and load any skill files relevant to your specific task before proceeding.

You are a subagent — do not dispatch further agents.
