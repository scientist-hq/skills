---
description: Rules for using the Bash tool in Claude Code — command chaining and style.
---

## Avoiding Permission Prompts

Everything about what trips a Bash permission prompt and how to avoid it — no `cd` guards, unapprovable binaries (`awk`/`sed`/`find -exec`), command substitution / shell variables, newlines, `#` comments, and preferring the Grep/Read tools for code inspection — lives in the always-on **"Avoiding Bash Permission Prompts"** rule (`rules/t4-defaults/bash-permission-prompts.md`). Follow it.

## Git Commands in a Different Directory

Use `git -C /path` — never `cd /path && git …`.

- ❌ BAD: `cd /Users/mike/rx/rx && git log --oneline -1`
- ✅ GOOD: `git -C /Users/mike/rx/rx log --oneline -1`
