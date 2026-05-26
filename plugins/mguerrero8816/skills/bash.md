---
description: Rules for using the Bash tool in Claude Code — command chaining and style.
---

## Chain Commands Instead of Using Newlines

Never use newlines inside a single Bash tool call — newlines trigger permission prompts. Chain sequential commands with `&&` (stop on failure) or `;` (continue regardless). For independent commands, make parallel Bash tool calls instead.

- ❌ BAD: `cd rx\nbundle exec rspec spec/foo_spec.rb`
- ✅ GOOD: `env -C /Users/mike/rx/rx bundle exec rspec spec/foo_spec.rb`

## Avoid `cd` Before Commands

Using `cd /path && command` triggers a security prompt in Claude Code. Use directory-aware alternatives instead:

**For git:** use `git -C /path`
- ❌ BAD: `cd /Users/mike/rx/rx && git log --oneline -1`
- ✅ GOOD: `git -C /Users/mike/rx/rx log --oneline -1`

**For bundle exec and other commands that need a working directory:** use `env -C /path`
- ❌ BAD: `cd /Users/mike/rx/rx && bundle exec rails runner "..."`
- ✅ GOOD: `env -C /Users/mike/rx/rx bundle exec rails runner "..."`

## No `#` Comments Inside Quoted Rails Runner Strings

A newline followed by `#` inside a quoted argument triggers a security prompt ("can hide arguments from path validation"). Use `puts` instead — it's readable and passes validation.

- ❌ BAD: `bundle exec rails runner "\n# move project\np.update_column(...)"`
- ✅ GOOD: `bundle exec rails runner "puts 'move project'; p.update_column(...)"`
