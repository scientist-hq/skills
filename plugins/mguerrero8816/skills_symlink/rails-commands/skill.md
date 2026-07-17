---
description: How to run rails / rails runner / rake / rspec commands without triggering permission prompts — no cd, no comment lines, single-line quoting. Load before running any Rails app command.
---

## Avoiding Permission Prompts

Run app commands directly (no `cd`/`env -C` guard), keep each command on one line, and never put a `#` comment inside a quoted `rails runner` string (use `puts`). The full explanation and every trigger lives in the always-on **"Avoiding Bash Permission Prompts"** rule (`rules/t4-defaults/bash-permission-prompts.md`). Follow it.

## Quoting

Wrap the runner script in single quotes and use double quotes for string literals inside it — this avoids shell interpolation and keeps the whole command on one line.

- ✅ GOOD: `bundle exec rails runner 'p = Pg::Proposal.find_by(uuid: "abc123"); puts p.milestones.count'`
