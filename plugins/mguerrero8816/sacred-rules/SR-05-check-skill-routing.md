# SR-05: Check Skill Routing Before Acting

**Level:** MUST follow — no exceptions, no overrides
**Category:** Workflow

## Rule

Before performing any non-trivial action, check the routing table in `~/skills/plugins/mguerrero8816/SKILL.md` for a matching skill and load it if one exists.

- Read the "When" column in SKILL.md and compare it against the current task
- If a matching skill file is found, read it before proceeding
- Only then begin the task

This applies to: pull requests, reviews, tickets, specs, debugging, integrations, design conversations, code quality work — any task that has a row in the routing table.

Do not skip this check because the task seems straightforward. The skill file may contain project-specific rules that override general behaviour.
