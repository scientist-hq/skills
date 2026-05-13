---
name: rx
description: Coding standards and patterns for the Scientist.com RX Rails platform. Includes sacred rules (must-follow), taste preferences, and reference implementations.
---

# RX Skills Navigation

Load this file first, then load specific rules/patterns as needed for the task at hand.

## Sacred Rules (MUST follow — violations block merge)

| ID | Rule | File |
|----|------|------|
| SR-01 | No raw SQL — use ActiveRecord exclusively | sacred-rules/SR-01-no-raw-sql.md |
| SR-02 | Business logic in services — never in models or controllers | sacred-rules/SR-02-service-objects.md |
| SR-03 | N+1 prevention — always use includes/preload | sacred-rules/SR-03-no-n-plus-one.md |
| SR-04 | Strong migrations — all migrations must be safe | sacred-rules/SR-04-strong-migrations.md |
| SR-05 | No Pg:: namespace for new models | sacred-rules/SR-05-no-pg-namespace.md |
| SR-06 | Authorization checks on every controller action | sacred-rules/SR-06-authorization-checks.md |
| SR-07 | Money gem for all monetary values | sacred-rules/SR-07-money-gem.md |
| SR-08 | ActiveStorage only — no Paperclip for new code | sacred-rules/SR-08-no-paperclip.md |

## Sacred Taste (SHOULD follow — improve quality, not blockers)

| ID | Preference | File |
|----|-----------|------|
| ST-01 | Methods under 15 lines | sacred-taste/ST-01-method-length.md |
| ST-02 | Stimulus over custom JS | sacred-taste/ST-02-stimulus-over-custom-js.md |
| ST-03 | HTMX-first for dynamic interactions | sacred-taste/ST-03-htmx-first.md |
| ST-04 | Presenters for view logic | sacred-taste/ST-04-presenters-for-views.md |
| ST-05 | Minimal factory setup in tests | sacred-taste/ST-05-factory-minimalism.md |
| ST-06 | Pagy for pagination | sacred-taste/ST-06-pagy-pagination.md |

## Sacred Rules (cont.)

| ID | Rule | File |
|----|------|------|
| SR-09 | Every PR must link to an issue or preceding PR (VerifyIssue CI) | references/verify-issue-ci-check.md |

## Infrastructure References

| Topic | File |
|-------|------|
| Bootboot dual-lockfile setup & sync procedure | references/bootboot-lockfiles.md |
| VerifyIssue CI check — PR linking requirement | references/verify-issue-ci-check.md |

## Patterns (Reference implementations from the RX codebase)

| ID | Pattern | File |
|----|---------|------|
| PT-01 | Service object template | patterns/PT-01-service-pattern.md |
| PT-02 | Presenter template | patterns/PT-02-presenter-pattern.md |
| PT-03 | RSpec test template | patterns/PT-03-rspec-pattern.md |
| PT-04 | Migration template | patterns/PT-04-migration-pattern.md |
| PT-05 | Searchkick integration | patterns/PT-05-searchkick-pattern.md |
| PT-06 | External service integration (VCR) | patterns/PT-06-integration-pattern.md |
