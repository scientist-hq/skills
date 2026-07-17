---
description: Rules for running bundle exec commands in the RX repo — always run from the correct subdirectory.
---

## Always Run from the rx Subfolder

The Rails application lives at `/Users/mike/rx/rx/`. All `bundle exec` commands must run from there.

Before running any `bundle exec` command, check the working directory. If not in `/Users/mike/rx/rx`, stop and tell the user:

> "I need to run this from `/Users/mike/rx/rx` — please open Claude from that directory (use `rxclaude`) and try again."

Never prepend `cd` or `env -C` to navigate there — alert instead.

Applies to all bundle commands: `bundle exec rails`, `bundle exec rspec`, `bundle exec rubocop`, `bundle exec rails runner`, etc.

## No `#` Comments Inside Rails Runner Strings

A newline followed by `#` inside a quoted `rails runner` argument triggers a security prompt. Use `puts` instead.

- ❌ BAD: `bundle exec rails runner "\n# find the user\nuser = Pg::User.find_by(...)"`
- ✅ GOOD: `bundle exec rails runner "puts 'find the user'; user = Pg::User.find_by(...)"`
