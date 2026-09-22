---
name: dependabot
description: Triage and resolve Dependabot security alerts across Scientist.com repos. Covers full lifecycle — inventory, changelog review, spec hardening, batched upgrades, CI fix patterns, and PR hygiene.
---

# Dependabot Security Alert Remediation

Load this file first, then load workflows and references as needed.

## When to Use

- Dependabot alerts need triaging or fixing
- Security PRs from Dependabot need review/merge
- Dependency upgrades need planning across repos
- CI is failing on security upgrade PRs

## Workflow

| ID | Step | File |
|----|------|------|
| W-01 | Full inventory of open alerts | workflows/W-01-inventory.md |
| W-02 | Review existing Dependabot PRs | workflows/W-02-review-existing-prs.md |
| W-03 | Batch upgrades by risk and coupling | workflows/W-03-batch-strategy.md |
| W-04 | Per-batch execution (changelog → specs → upgrade → verify) | workflows/W-04-batch-execution.md |
| W-05 | Fix common CI failures | workflows/W-05-ci-fix-patterns.md |

## References

| File | Content |
|------|---------|
| references/api-patterns.md | gh API queries, jq filters, pagination |
| references/bootboot.md | Dual-lockfile upgrades with bootboot (rx-specific) |
| references/linked-issue-exemption.md | Fix linked-issue CI checks for Dependabot branches |
| references/rails-72-upgrade.md | Rails 7.1→7.2 specific CI failures and fixes |
| references/major-version-blockers.md | Companion gem ceiling detection and resolution |
| references/nightly-cron-triage.md | Automated nightly triage: version comparison, dismissal, cron gotchas |
| references/viewcomponent-4.md | ViewComponent 3→4 breaking changes and audit checklist |

## Key Principles

1. **Read the changelog BEFORE upgrading.** Compare breaking changes against actual codebase usage. A "minor" bump can break everything if you use a deprecated API.
2. **Harden specs BEFORE upgrading.** Write tests on the CURRENT version that exercise the dependency's behavior. These are your canary — if they pass before and after, the upgrade is safe.
3. **⚠️ One concern per PR — strict isolation.** Each PR addresses exactly ONE dependency or tightly-coupled group. A Rails PR must not also bump Devise. If a major bump is forced by another upgrade, split into two PRs or flag it loudly. Use `bundle update --conservative` religiously. See W-03 for full rules.
4. **Batch by coupling, not by severity.** Rails gems go together. Nokogiri + rexml go together. Don't mix framework upgrades with unrelated patches.
5. **Low-risk first.** Merge existing Dependabot PRs (free wins) → dismiss already-patched → patch bumps → minor bumps → major bumps.

## Scientist-Specific Context

- **rx** is a monorepo — git root ≠ Rails app root. The Rails app is at `rx/` within the repo. Run git commands from repo root, bundle commands from `rx/`.
- **rx** is on Rails 8.0.x. **benchmate** is on Rails 7.1→7.2 upgrade path.
- **rx uses bootboot** for dual-lockfile builds. Every gem upgrade must update BOTH `Gemfile.lock` AND `Gemfile_next.lock`. See references/bootboot.md.
- Both repos use `hattan/verify-linked-issue-action@v1.1.5` for linked-issue checks — Dependabot branches need exemption (see references/linked-issue-exemption.md).
- Both repos use `brakeman` with `--ensure-no-obsolete-ignore-entries` — stale ignores fail CI.
- Private gems are hosted on `rubygems.pkg.github.com/scientist-hq` — bundle needs GitHub auth.
- `.tool-versions` specifies Ruby via mise. On machines with system Ruby 2.6, run `eval "$(mise env)"` before any bundle commands.
- **Label names differ by repo.** `"Type: Infrastructure"` exists on rx but NOT on benchmate. For benchmate, use only `"security"` and `"dependencies"`. Always handle label-not-found errors gracefully (retry without the missing label). Note: labels are case-insensitive for matching on GitHub's side.
- **Dismissal API for false positives:** When installed version is outside the vulnerable range, dismiss via:
  ```
  gh api repos/scientist-hq/{repo}/dependabot/alerts/{n} -X PATCH \
    -f state=dismissed -f dismissed_reason=not_used \
    -f dismissed_comment="Dismissed by BigMac: installed version X.Y.Z is not in vulnerable range A.B.C"
  ```
