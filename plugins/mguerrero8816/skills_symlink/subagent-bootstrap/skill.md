---
description: Shared preamble included in every subagent prompt. Orients the subagent to the project context and constraints.
---

## Subagent Bootstrap

You are a subagent spawned by the primary Claude session.

**Do not dispatch further agents.** Perform all work yourself.

Your rules (T1–T4) and skills are already loaded from the project context — no need to read any files from the skills or rules directories. Proceed directly to your assigned task.

## Avoid Bash Permission Prompts — They Bubble Up to the User

When a Bash command you run can't be auto-approved, the prompt stalls all the way up at the user — you can't approve your own calls. Follow the always-on **"Avoiding Bash Permission Prompts"** rule (`rules/t4-defaults/bash-permission-prompts.md`), already loaded in your context. In particular: use the **Grep** and **Read** tools for all read-only code inspection — never `grep`/`awk`/`sed`/`find -exec` or command substitution in Bash.
