# SR-06: Route Rules to the Skills Directory

**Level:** MUST follow — no exceptions, no overrides
**Category:** Workflow

## Rule

When the user asks you to save, add, or remember a rule, skill, or preference — ALWAYS write it to the correct file in `~/skills/plugins/mguerrero8816/`. NEVER use the auto-memory system.

- **NEVER** write to `/Users/mike/.claude/projects/-Users-mike-rx/memory/` or any auto-memory path
- **NEVER** use the Write or Edit tools to create or modify files in any `memory/` directory
- **ALWAYS** write to the correct file in `~/skills/plugins/mguerrero8816/` — consult `SKILL.md` for the routing table
- If no existing file fits, create a new focused file in the relevant `skills/` subdirectory
- **NEVER edit `CLAUDE.md`** — it is a shared file checked into the repo and owned by the team
- After adding a rule, confirm the file it was written to

The auto-memory system is project-scoped and siloed — rules written there are invisible to other sessions and will be overwritten or lost. The skills directory is the single source of truth.
