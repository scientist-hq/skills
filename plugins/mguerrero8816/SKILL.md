---
name: mguerrero8816
description: Personal skills and workflow rules for Mike Guerrero working on the RX Rails platform. Load this file first, then load specific skills as needed for the task at hand.
---

# Personal Skills — Mike Guerrero

## ⛔ Sacred Rules — ALWAYS load these immediately, before anything else

These are non-negotiable. Load all four at the start of every session regardless of task.

| ID | Rule | File |
|----|------|------|
| 01 | No remote environments — never rxp, rxs, or any remote server | `rules/t1-sacred/01-no-remote-environments.md` |
| 02 | No unauthorized git operations — never commit, push, or checkout | `rules/t1-sacred/02-no-unauthorized-git-ops.md` |
| 03 | No unauthorized GitHub changes — never edit others' PRs or issues | `rules/t1-sacred/03-no-unauthorized-github-changes.md` |
| 04 | No unsolicited code changes — never edit code without explicit instruction | `rules/t1-sacred/04-no-unsolicited-code-changes.md` |
| 05 | Check skill routing before acting — read SKILL.md and load any matching skill first | `rules/t1-sacred/05-check-skill-routing.md` |
| 06 | Route rules to the skills directory — never use auto-memory | `rules/t1-sacred/06-route-rules-to-skills.md` |
| 07 | Load tiered rules (T2/T3/T4) at session start | `rules/t1-sacred/07-load-tiered-rules.md` |

---

Then load the specific skill file for the current task.

## Maintenance

| When | File |
|------|------|
| Cleaning up accumulated Claude auto-memory | `skills/cleanup-memory.md` |

## Skill Authoring

| When | File |
|------|------|
| Writing a new skill or rule for this plugin | `skills/authoring.md` |

## Pull Requests

| When | File |
|------|------|
| Creating, editing, or interacting with any PR | `skills/pull-requests/base-rules.md` |
| About to run or step through a PR's manual tests | `skills/pull-requests/pr-test-preflight.md` |
| Executing PR test steps | `skills/pull-requests/run-pr-tests.md` |
| Opening a hotfix PR (urgent production fix) | `skills/pull-requests/open-hotfix-pr.md` |
| Opening a Bootstrap 5 migration PR | `skills/pull-requests/open-bs5-pr.md` |
| Opening a panel-to-card migration PR | `skills/pull-requests/open-panel-card-pr.md` |
| Opening a code cleanup/removal PR | `skills/pull-requests/open-cleanup-pr.md` |
| Opening a PR targeting the staging branch | `skills/pull-requests/open-staging-pr.md` |

## Reviews

| When | File |
|------|------|
| Reviewing a pull request | `skills/reviews/review-pr.md` |

## Tickets

| When | File |
|------|------|
| Creating or interacting with any ticket or issue | `skills/tickets/base-rules.md` |
| Creating a bug issue | `skills/tickets/create-bug-issue.md` |

## Testing

| When | File |
|------|------|
| Writing or debugging any RSpec spec | `skills/testing/spec/spec-rules.md` |
| Using Playwright or automating browser flows (general) | `skills/playwright/qa-rules.md` |
| Opening the storefront for an org | `skills/playwright/storefront-index.md` |
| Creating a new request from the storefront | `skills/playwright/storefront-create-request.md` |
| Opening the proposal form for a request | `skills/playwright/open-proposal-form.md` |
| Creating and submitting a proposal | `skills/playwright/create-proposal.md` |
| Creating a purchase order from a proposal | `skills/playwright/create-purchase-order.md` |
| Creating a change order against an existing PO | `skills/playwright/create-change-order.md` |
| Sending a PO to NetSuite via the browser | `skills/playwright/send-po-to-netsuite.md` |
| Setting up a customer legal entity for NetSuite | `skills/playwright/setup-legal-entity.md` |
| Creating a configuration rule via the admin UI | `skills/playwright/create-configuration-rule.md` |
| Creating test data for organizations | `skills/testing/spec/test-data-organization.md` |
| Creating test data for requests (quote groups / quoted wares) | `skills/testing/spec/test-data-request.md` |
| Creating test data for proposals (SOW / amendments) | `skills/testing/spec/test-data-proposal.md` |
| Creating test data for purchase orders (CPO / PPO) | `skills/testing/spec/test-data-purchase-order.md` |
| Creating test data for users | `skills/testing/spec/test-data-user.md` |
| Creating test users in development (Rails console, manual QA) | `skills/testing/qa/test-users.md` |

## Integrations

| When | File |
|------|------|
| Sending a PPO/CPO to NetSuite or troubleshooting NetSuite PO sync | `skills/integrations/netsuite-ppo-sync.md` |
| Working on NetSuite SuiteScript files | `skills/integrations/netsuite-scripts.md` |
| Creating a customer invoice from a PO without NetSuite | `skills/integrations/create-invoice-from-po.md` |

## Debugging

| When | File |
|------|------|
| Something is broken or behaving unexpectedly after a change | `skills/debugging/change-investigation.md` |
| A page has an error or isn't rendering correctly | `skills/debugging/fix-page-errors.md` |
| A feature renders in some places but not others | `skills/debugging/partial-context-mismatch.md` |
| Diagnosing or fixing errors on the provider invoices page | `skills/debugging/fix-billing-invoices.md` |

## Design

| When | File |
|------|------|
| Designing a new feature or discussing architecture | `skills/design/design-doc.md` |
| Taking screenshots for PRs, docs, or demos | `skills/design/feature-screenshots.md` |
| Working on anything that touches the request page display | `skills/design/request-page-anatomy.md` |

## Features

| When | File |
|------|------|
| Working on or finding test data for the preferred suppliers feature | `skills/preferred-suppliers.md` |

## Database

| When | File |
|------|------|
| Fixing, debugging, or extending any ActiveRecord query | `skills/query-building.md` |

## tmux

| When | File |
|------|------|
| Sending commands to any tmux pane | `skills/tmux.md` |

## Bash

| When | File |
|------|------|
| Using the Bash tool in Claude Code | `skills/bash.md` |
| Running any bundle exec command | `skills/bundle.md` |

## Explanations

| When | File |
|------|------|
| Asked to trace exception propagation, service call flows, or callback chains | `skills/explain-causation.md` |

## Searchkick

| When | File |
|------|------|
| Working with any Searchkick model or Elasticsearch indexing | `skills/searchkick.md` |

## Migrations

| When | File |
|------|------|
| Writing or running any database migration | `skills/migrations.md` |

## Code Quality

| When | File |
|------|------|
| Bumping a gem version or working on a Dependabot ticket | `skills/code-quality/gem-bump.md` |
| Working on commission fee cap logic | `skills/code-quality/fee-cap-rules.md` |

## CSS

| When | File |
|------|------|
| Working on CSS styling, link underlines, or inline element decoration | `skills/css.md` |

## URLs

| When | File |
|------|------|
| Constructing or providing any development URL for the RX app | `skills/rx-urls.md` |
