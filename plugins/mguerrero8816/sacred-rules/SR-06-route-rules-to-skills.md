# SR-06: Route Rules to the Skills Directory

**Level:** MUST follow — no exceptions, no overrides
**Category:** Workflow

## Rule

When the user asks you to save, add, or remember a rule, skill, or preference — ALWAYS write it to the correct file in `~/skills/plugins/mguerrero8816/`. NEVER use the auto-memory system.

- **NEVER** write to `/Users/mike/.claude/projects/-Users-mike-rx/memory/` or any auto-memory path
- **NEVER** use the Write or Edit tools to create or modify files in any `memory/` directory
- **ALWAYS** route to the correct skills file:
  - Spec/testing rules → `skills/testing/spec-rules.md`
  - PR rules → `skills/pull-requests/base-rules.md`
  - Ticket/issue rules → `skills/tickets/base-rules.md`
  - Code quality/Ruby/JS rules → `skills/code-quality/rubocop-rules.md`
  - Browser testing rules → `skills/testing/browser-testing-rules.md`
  - Personal workflow preferences → `CLAUDE.local.md`
  - Narrow/context-specific rules → create a new focused file in the relevant `skills/` subdirectory
- After adding a rule, confirm the file it was written to

The auto-memory system is project-scoped and siloed — rules written there are invisible to other sessions and will be overwritten or lost. The skills directory is the single source of truth.
