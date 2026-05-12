# W-03: Batch Strategy

Group dependencies by coupling and risk. Never mix unrelated upgrades in one PR.

## Batching Rules

1. **Same framework = same batch.** All Rails gems together (activesupport, activestorage, actionview, railties, etc.). They share version lockstep.
2. **Same package, multiple alerts = one upgrade.** 14 rack alerts → one `bundle update rack`.
3. **Tightly coupled deps together.** nokogiri + rexml go together (nokogiri depends on rexml).
4. **Major version bumps get their own batch.** Devise 4→5, ViewComponent 3→4 — these need dedicated attention.
5. **Transitive deps with no direct usage = low risk.** net-imap, uri, etc. if your app doesn't use them directly.

## ⚠️ Strict PR Isolation

**Each PR must address exactly ONE dependency or ONE tightly-coupled group.** Do NOT bundle unrelated upgrades into the same PR, even if they touch the same lockfile.

**Bad:** A PR titled "Upgrade Rails to 7.2" that also bumps Devise 4→5. These are separate concerns with separate risk profiles and must be separate PRs.

**When a major version bump is forced by another upgrade:**
If upgrading dependency A *requires* upgrading dependency B to a new major version (e.g., `bundle update` fails without it):
1. **Preferred:** Create the dependent major upgrade as its own PR first, merge it, then do the original upgrade in a follow-up PR.
2. **If truly inseparable:** Include both in one PR but **prominently flag the major version bump** in the PR title AND description. Example title: `Security: Upgrade foo 1.2→1.3 (⚠️ requires bar 2.x→3.x major bump)`. The PR body must explain WHY the major bump is required and what breaking changes it introduces.

**Never silently include a major version bump.** Major bumps (X.0→Y.0) change APIs, remove deprecations, and can break production. They deserve explicit reviewer attention.

## Risk Classification

| Risk | Criteria | Examples |
|------|----------|----------|
| Low | Patch bump, no breaking changes, transitive dep | net-imap, rack (patch), uri |
| Medium | Minor version bump, some API changes, or framework security patch | Rails 7.1→7.2, nokogiri minor |
| High | Major version bump, or deeply integrated dep | Devise 4→5, ViewComponent 3→4 |

## Priority Order

1. Merge existing Dependabot PRs (free wins)
2. Dismiss already-patched alerts
3. Low-risk patch bumps (quick wins, many alerts resolved per PR)
4. High-severity alerts regardless of risk level
5. Major version bumps last (most prep work needed)

## Example Batch Plan

From the scientist-hq rx + benchmate remediation:

| Batch | Deps | Risk | Notes |
|-------|------|------|-------|
| 1 | Rails 7.1→7.2 | Medium | benchmate only; rx already on 8.0 |
| 2 | nokogiri + rexml | Low | Conservative update, no API changes |
| 3 | Devise 4→5 | High | benchmate clean; rx blocked by companion gem |
| 4 | net-imap | Low | Transitive dep, no direct usage |
| 5 | view_component 3→4 | Medium | rx only, audit for slot/preview usage |
| 6 | Small gems (rack, uri, etc.) | Low | Patch bumps, many alerts each |
| 7 | npm deps (next, etc.) | Low | Frontend lockfile only |

## Cross-Repo Considerations

When the same dependency needs upgrading in multiple repos:
- Create parallel PRs with the same batch name/number
- But don't assume the same version target — repos may be on different base versions
- rx (Rails 8.0) and benchmate (Rails 7.1) have very different upgrade paths

## Parallel Execution

Low-risk batches that don't touch the same files can run in parallel via `delegate_task`. Good candidates:
- Different repos (rx batch 6 + benchmate batch 6)
- Different ecosystems (Ruby batch + npm batch)
- Different lockfiles in a monorepo

Do NOT parallelize batches that modify the same Gemfile.lock — they'll produce conflicting lockfiles.

**`delegate_task` call syntax:**
```
delegate_task(tasks: [
  {goal: "Batch 6: Small gems on rx + benchmate", toolsets: ["terminal", "file", "web"]},
  {goal: "Batch 7: npm deps on rx", toolsets: ["terminal", "file", "web"]},
  {goal: "Batch 4: net-imap on rx + benchmate", toolsets: ["terminal", "file", "web"]},
])
```
