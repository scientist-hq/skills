---
description: Rules for running bundle exec commands in the RX repo — always run from the correct subdirectory.
---

## Always Run from the rx Subfolder

The Rails application lives at `/Users/mike/rx/rx/`, which is the session CWD. Run all `bundle exec` commands directly from there with no path prefix — never prepend `cd` or `env -C`. See the always-on **"Avoiding Bash Permission Prompts"** rule (`rules/t4-defaults/bash-permission-prompts.md`) for this and the other prompt triggers.

If the working directory genuinely is not `/Users/mike/rx/rx`, stop and tell the user rather than adding a `cd` guard:

> "I need to run this from `/Users/mike/rx/rx` — please open Claude from that directory (use `rxclaude`) and try again."

Applies to all bundle commands: `bundle exec rails`, `bundle exec rspec`, `bundle exec rubocop`, `bundle exec rails runner`, etc.
