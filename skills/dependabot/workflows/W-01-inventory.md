# W-01: Full Inventory of Open Alerts

Pull ALL open Dependabot alerts. The API paginates at 30 by default — always use `per_page=100`.

## Step 1: Fetch alerts

```bash
gh api "repos/ORG/REPO/dependabot/alerts?state=open&per_page=100" \
  --jq '.[] | [.number, .security_advisory.severity, .security_vulnerability.package.name, .security_vulnerability.package.ecosystem, .security_vulnerability.vulnerable_version_range, .security_vulnerability.first_patched_version.identifier // "none", .security_advisory.summary] | @tsv'
```

If you get exactly 100 results, paginate: `&page=2`, `&page=3`, etc.

## Step 2: Group by package

Many alerts are duplicates — e.g., 14 rack alerts all fixed by one bump, or 26 next alerts from one outdated lockfile.

```bash
gh api "repos/ORG/REPO/dependabot/alerts?state=open&per_page=100" \
  --jq '[.[] | .security_vulnerability.package.name] | group_by(.) | map({package: .[0], count: length}) | sort_by(-.count)'
```

Present the grouped view first, then detail view on request.

## Step 3: Cross-reference installed versions

For each affected package, check what's actually installed:

```bash
# Ruby
grep -E "^    (gem_name) " Gemfile.lock

# npm/pnpm
grep "package@" pnpm-lock.yaml | head -5
```

If the installed version already meets the patch target, the alert is stale and will auto-close.

## Step 4: Find all lockfiles (monorepos)

```bash
find . -name "Gemfile.lock" -o -name "pnpm-lock.yaml" -o -name "yarn.lock" -o -name "package-lock.json"
```

rx is a monorepo with multiple lockfiles across different subdirectories. Alerts may come from any of them.

## Pitfalls

- **Don't filter `state=open` vs `state=fixed` on first pass if user wants full picture.** Fixed alerts from auto-merged Dependabot PRs are useful context.
- **Don't include fixed alerts when reporting counts.** Default API call (no `state` param) returns ALL alerts. Users compare your count to the GitHub UI which shows open only.
- **Duplicate alerts are common.** Same CVE can appear multiple times for different lockfiles or version ranges. Note these when presenting.
