# Nightly Cron Triage Pattern

## Overview

Automated nightly scan of Dependabot alerts across scientist-hq repos. Runs as a cron job — no user interaction available.

## Triage Logic

For each open alert, compare the installed version against the vulnerable range:

1. **Get alert details**: package name, vulnerable_version_range, first_patched_version
2. **Check actual lockfile**: `grep '{gem} (' Gemfile.lock` (for rx: `rx/Gemfile.lock`)
3. **For JS deps**: check the lockfile. rx monorepo uses `pnpm-lock.yaml` in multiple subdirs (`ai-insights-frontend/`, `assistant-ui-frontend/`, `rx/`, `rx/micro-frontends/proposal-comparison-chat/`, `rx/micro-frontends/supplier-selection-chat/`). Format: `vitest@3.2.4:` followed by resolution metadata. Note: GitHub's API `manifest_path` field may report `package-lock.json` even when the project actually uses `pnpm-lock.yaml` — always check which lockfile actually exists. For version extraction, grep for `{package}@{version}:` pattern. For yarn: `yarn.lock` format is `version "X.Y.Z"` after the resolution line
4. **For Python deps** (rx monorepo): check `rx-dbt/superset/docker/requirements-local.txt` and `rx/requirements.txt`. Format is `package == X.Y.Z` or `package >= X, < Y`. Use `grep {package} {file}` to extract the pinned version.
4. **Compare versions**:
   - If installed version is OUTSIDE vulnerable range → dismiss as not_used
   - If installed version is IN vulnerable range → attempt upgrade

## Version Range Patterns

| Pattern | Meaning |
|---------|---------|
| `< 8.5.10` | All versions below 8.5.10 |
| `>= 6.0.2, < 6.0.4` | Versions 6.0.2 and 6.0.3 only |
| `<= 5.0.3` | All versions up to and including 5.0.3 |

## Config-Gated Vulnerabilities

Some CVEs only affect deployments using a non-default configuration. Example: puma CVE-2026-47736/47737 only affects `set_remote_address proxy_protocol: :v1`.

**Pattern:**
1. Read the advisory description — look for "Only deployments that explicitly enable X are affected"
2. `grep -r "{config_directive}" <clone>` to check if the repo uses it
3. If NOT found → dismiss with `dismissed_reason=not_used` and comment explaining the config isn't enabled:
   ```
   gh api repos/ORG/REPO/dependabot/alerts/N -X PATCH \
     -f state=dismissed -f dismissed_reason=not_used \
     -f dismissed_comment="Dismissed by BigMac: installed version X.Y.Z is in vulnerable range but CVE-XXXX-YYYYY only affects deployments using {config_directive} which {repo} does not configure"
   ```

This is distinct from "version not in range" dismissals — here the version IS in range but the vulnerable code path is never exercised.

## Advisory Threshold Downgrades

GitHub sometimes updates an advisory to lower the patch requirement (e.g., vitest CVE-2026-47429 originally required >= 4.1.0, later updated to >= 3.2.6). When this happens:

1. Old alert numbers may 404 (superseded) — treat as resolved, remove from state
2. New alert numbers appear in the open list with the updated range
3. Previously-blocked alerts may now be trivially patchable
4. **Comment on the existing GitHub issue** rather than filing a new one, explaining the advisory was updated and the fix path is now simpler
5. Update the state file entry's `reason` to reflect the new situation

## Upgrade Decision Tree

```
Alert is applicable?
├── NO → dismiss via API (dismissed_reason=not_used)
│   (includes config-gated CVEs where the config is not enabled)
└── YES
    ├── Patch bump (same minor) → attempt conservative upgrade, open PR
    │   ├── Ruby gem → `bundle update --conservative {gem}` (bootboot plugin auto-updates Gemfile_next.lock if installed; no separate DEPENDENCIES_NEXT=1 step needed for patch bumps)
    │   └── Python pip → edit requirements file, commit, push, PR
    ├── Minor bump → attempt upgrade, open PR, note in report
    └── Major bump → check for blockers
        ├── Companion gem ceiling? → document blocker, flag for team
        └── No blocker → attempt upgrade (higher risk, needs team review)
```

## Bootboot Single-Lockfile Check

When reviewing open Dependabot PRs for rx, check if the PR only modifies `Gemfile.lock` without also updating `Gemfile_next.lock`. Dependabot doesn't know about bootboot, so Ruby gem PRs ALWAYS need a fixup.

**Detection:** `gh pr diff {number} --name-only | grep -c 'Gemfile'` — if it returns 1 (only `Gemfile.lock`), comment on the PR:
```
⚠️ **Bootboot reminder**: This PR only updates `Gemfile.lock` but we dual-build with bootboot.
The `Gemfile_next.lock` also needs updating. Run: `DEPENDENCIES_NEXT=1 bundle lock`
```

Flag these in the nightly report under a `:warning: Needs bootboot fixup` section.

## PR Labels by Repo

| Repo | Available Labels |
|------|-----------------| 
| rx | `Type: Infrastructure`, `security`, `dependencies` |
| benchmate | `security`, `dependencies` (NO `Type: Infrastructure`) |

**Note:** GitHub labels are case-insensitive for matching but case-preserving for display. `--label "security"` and `--label "Security"` both work if the label exists with either casing. However, if the label doesn't exist at all, `gh issue/pr create` will error. Always handle label-not-found gracefully.

## State Tracking & Deduplication

The nightly cron uses `~/.hermes/state/dependabot-reported.json` to track previously-reported alerts. This avoids repeating full detail on alerts the team has already been told about.

**Behavior:**
- **New alerts**: Full triage. If blocked (requires human intervention), file a GitHub issue in the affected repo with all detail (CVE, severity, installed vs patched version, why blocked, remediation paths). Include the issue URL in the Slack report — NOT the full analysis.
- **Pre-existing alerts**: Brief reference to the GitHub issue only. If only pre-existing alerts exist and nothing changed, respond with `[SILENT]` to suppress delivery.
- **Resolved alerts**: Brief mention, then remove from state file.
- **Pre-existing with `github_issue: null`**: File the issue on this run, update state.

**Labels for filed issues:**
- rx: `Security`, `Dependencies`, `Type: Infrastructure`
- benchmate: `Security`, `Dependencies` (no `Type: Infrastructure`)

## Cron-Specific Gotchas

1. **Security approval gates**: `rm -rf /tmp/*` triggers approval prompts that block in cron mode (the "delete in root path" safety check fires for `/tmp`). Do NOT attempt to rm temp dirs — just leave them. `/tmp` is cleaned on reboot. Use `op run --env-file` pattern instead of exporting tokens to avoid similar gates.
2. **Shallow clones are sufficient**: `git clone --depth 1` for lockfile inspection. No need for full history.
3. **Branch naming**: Use `dependabot/bundler/{gem}-{version}` to get the linked-issue CI exemption automatically.
4. **Bundle auth in temp clones**: The shallow clone inherits SSH access but needs bundler credentials for private gems. `op run --env-file ~/.hermes/op.env --no-masking -- bundle update` handles this.
5. **Ruby version mismatch in temp clones**: rx requires a specific Ruby (e.g. 3.3.8) specified in `.tool-versions`/`mise.toml`. If the system Ruby doesn't match, `mise install ruby@X.Y.Z && mise use ruby@X.Y.Z` in the temp clone. This creates/modifies a `mise.toml` at the repo root — but since it's untracked by git, `git checkout -- mise.toml` will FAIL with "pathspec did not match". The safe pattern is to **only `git add` the specific lockfiles** (e.g. `git add rx/Gemfile.lock rx/Gemfile_next.lock`) rather than using `git add .` or trying to revert mise.toml. The file won't appear in `git status --short` unless it's tracked, so it's harmless as long as you stage selectively.
6. **Python dependency alerts in rx**: The rx monorepo has Python dependencies in `rx-dbt/superset/docker/requirements-local.txt`. These are simple pin edits (no lockfile resolution needed). Branch naming: `dependabot/pip/{package}-{version}`.
7. **Companion gem ceiling detection**: When `bundle update --conservative` reports "version stayed the same", check for ceiling blockers: `bundle exec ruby -e "require 'bundler'; Bundler.locked_gems.specs.each{|s| dep = s.dependencies.find{|d| d.name == '{target_gem}'}; puts \"#{s.name} (#{s.version}) requires {target_gem} #{dep.requirement}\" if dep}"`. Look for `< X.0.0` constraints that block the upgrade.
8. **macOS `sed -i` incompatibility**: On macOS, `sed -i 'pattern' file` fails — it requires `sed -i '' 'pattern' file`. For Python requirement pin edits, prefer using the Hermes `patch` tool instead of sed to avoid this issue entirely.
9. **Dependabot manifest_path is unreliable for pnpm**: GitHub reports `manifest_path: "assistant-ui-frontend/package-lock.json"` even when the project uses pnpm. Always verify by checking what lockfiles exist (`find <clone> -name "pnpm-lock.yaml" -o -name "package-lock.json" -o -name "yarn.lock"`). For version extraction from pnpm-lock.yaml, grep for `{package}@{version}:` pattern (e.g. `uuid@11.1.1:`) — this is the resolved version line.
10. **State file: remove resolved alerts**: When an alert shows `state: "fixed"` in the API response, remove it from the state file and mention it briefly in the report as resolved. Don't leave stale "fixed" entries accumulating.
11. **Alert supersession**: GitHub sometimes replaces an older alert with a new one for the same CVE (e.g. when the advisory is updated with a new patched version). The old alert number disappears from the open list and may return 404 from the API. When processing the state file, if an alert number is no longer in the open list AND no longer fetchable via the API, treat it as superseded/resolved. Remove it from state and note it briefly in the report. The new alert will be picked up as a fresh entry.
