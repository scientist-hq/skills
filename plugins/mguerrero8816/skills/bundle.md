---
name: bundle
description: Rules for running bundle exec commands in the RX repo — always run from the correct subdirectory.
---

## Always Run from the rx Subfolder

The Rails application lives at `/Users/mike/rx/rx/` (nested `rx` directory). All `bundle exec` commands must be run from there — never from the parent `/Users/mike/rx/`.

- ❌ BAD: `bundle exec rails runner "..."` from `/Users/mike/rx`
- ✅ GOOD: `cd rx && bundle exec rails runner "..."` from `/Users/mike/rx`
- ✅ GOOD: `bundle exec rails runner "..."` if already in `/Users/mike/rx/rx`

Applies to all bundle commands: `bundle exec rails`, `bundle exec rspec`, `bundle exec rubocop`, `bundle exec rails runner`, etc.
