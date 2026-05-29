---
description: Rules for using the Bash tool in Claude Code — command chaining and style.
---

## Chain Commands Instead of Using Newlines

Never use newlines inside a single Bash tool call — newlines trigger permission prompts. Chain sequential commands with `&&` (stop on failure) or `;` (continue regardless). For independent commands, make parallel Bash tool calls instead.

- ❌ BAD: `cd rx\nbundle exec rspec spec/foo_spec.rb`
- ✅ GOOD: `bundle exec rspec spec/foo_spec.rb` (CWD is already correct)

## Avoid `cd` and `env -C` Before Commands

Both `cd /path && command` and `env -C /path command` trigger permission prompts in Claude Code — `cd &&` for chaining, `env -C` because it cannot be statically analyzed.

**Subagents already inherit the session CWD (`/Users/mike/rx/rx`) — run commands directly without any path prefix.**

- ❌ BAD: `cd /Users/mike/rx/rx && bundle exec rspec spec/foo_spec.rb`
- ❌ BAD: `env -C /Users/mike/rx/rx bundle exec rspec spec/foo_spec.rb`
- ✅ GOOD: `bundle exec rspec spec/foo_spec.rb`

**For git commands in a different directory:** use `git -C /path` (this is fine)
- ❌ BAD: `cd /Users/mike/rx/rx && git log --oneline -1`
- ✅ GOOD: `git -C /Users/mike/rx/rx log --oneline -1`

**For non-git commands that genuinely need a different directory:** use absolute paths as arguments where possible. If CWD must change, there is no clean option — flag it rather than triggering a prompt.

## No `#` Comments Inside Quoted Rails Runner Strings

A newline followed by `#` inside a quoted argument triggers a security prompt ("can hide arguments from path validation"). Use `puts` instead — it's readable and passes validation.

- ❌ BAD: `bundle exec rails runner "\n# move project\np.update_column(...)"`
- ✅ GOOD: `bundle exec rails runner "puts 'move project'; p.update_column(...)"`
