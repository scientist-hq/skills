---
name: mguerrero8816
description: Personal skills and workflow rules for Mike Guerrero working on the RX Rails platform. Load this file first, then load specific skills as needed for the task at hand.
---

# Personal Skills — Mike Guerrero

## ⛔ Sacred Rules — ALWAYS load these immediately, before anything else

These are non-negotiable. Load all four at the start of every session regardless of task.

| ID | Rule | File |
|----|------|------|
| SR-01 | No remote environments — never rxp, rxs, or any remote server | `sacred-rules/SR-01-no-remote-environments.md` |
| SR-02 | No unauthorized git operations — never commit, push, or checkout | `sacred-rules/SR-02-no-unauthorized-git-ops.md` |
| SR-03 | No unauthorized GitHub changes — never edit others' PRs or issues | `sacred-rules/SR-03-no-unauthorized-github-changes.md` |
| SR-04 | No unsolicited code changes — never edit code without explicit instruction | `sacred-rules/SR-04-no-unsolicited-code-changes.md` |
| SR-05 | Check skill routing before acting — read SKILL.md and load any matching skill first | `sacred-rules/SR-05-check-skill-routing.md` |

---

Then load the specific skill file for the current task.

## Pull Requests

| When | File |
|------|------|
| Creating, editing, or interacting with any PR | `skills/pull-requests/pr-rules.md` |
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
| Creating or interacting with any ticket or issue | `skills/tickets/general.md` |
| Creating a bug issue | `skills/tickets/create-bug-issue.md` |

## Testing

| When | File |
|------|------|
| Writing or debugging any RSpec spec | `skills/testing/spec-rules.md` |
| Using Playwright or verifying UI flows in the browser | `skills/testing/browser-testing-rules.md` |
| Creating test data for organizations | `skills/testing/test-data-organization.md` |
| Creating test data for requests (quote groups / quoted wares) | `skills/testing/test-data-request.md` |
| Creating test data for proposals (SOW / amendments) | `skills/testing/test-data-proposal.md` |
| Creating test data for purchase orders (CPO / PPO) | `skills/testing/test-data-purchase-order.md` |
| Creating test data for users | `skills/testing/test-data-user.md` |

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
| Diagnosing or fixing errors on the provider invoices page | `skills/debugging/fix-billing-invoices.md` |

## Design

| When | File |
|------|------|
| Designing a new feature or discussing architecture | `skills/design/design-doc.md` |
| Taking screenshots for PRs, docs, or demos | `skills/design/feature-screenshots.md` |
| Working on anything that touches the request page display | `skills/design/request-page-anatomy.md` |

## Code Quality

| When | File |
|------|------|
| Bumping a gem version or working on a Dependabot ticket | `skills/code-quality/gem-bump.md` |
| Writing RuboCop-clean Ruby or fixing style violations | `skills/code-quality/rubocop-rules.md` |
| Working on commission fee cap logic | `skills/code-quality/fee-cap-rules.md` |
