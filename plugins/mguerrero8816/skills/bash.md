---
name: bash
description: Rules for using the Bash tool in Claude Code — command chaining and style.
---

## Chain Commands Instead of Using Newlines

Never use newlines inside a single Bash tool call — newlines trigger permission prompts. Chain sequential commands with `&&` (stop on failure) or `;` (continue regardless). For independent commands, make parallel Bash tool calls instead.

- ❌ BAD: `cd rx\nbundle exec rspec spec/foo_spec.rb`
- ✅ GOOD: `cd rx && bundle exec rspec spec/foo_spec.rb`
