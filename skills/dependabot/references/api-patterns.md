# Dependabot API Patterns

Common `gh api` queries and jq filters.

## List All Open Alerts (TSV)

```bash
gh api "repos/ORG/REPO/dependabot/alerts?state=open&per_page=100" \
  --jq '.[] | [.number, .security_advisory.severity, .security_vulnerability.package.name, .security_vulnerability.package.ecosystem, .security_vulnerability.vulnerable_version_range, .security_vulnerability.first_patched_version.identifier // "none", .security_advisory.summary] | @tsv'
```

## Count Open Alerts

```bash
gh api "repos/ORG/REPO/dependabot/alerts?state=open&per_page=100" --jq 'length'
```

## Group by Package (Summary View)

```bash
gh api "repos/ORG/REPO/dependabot/alerts?state=open&per_page=100" \
  --jq '[.[] | .security_vulnerability.package.name] | group_by(.) | map({package: .[0], count: length}) | sort_by(-.count)'
```

## Filter by Severity

```bash
gh api "repos/ORG/REPO/dependabot/alerts?state=open&severity=high,critical&per_page=100" \
  --jq '.[] | {number, package: .security_vulnerability.package.name, summary: .security_advisory.summary}'
```

## Filter by Ecosystem

```bash
gh api "repos/ORG/REPO/dependabot/alerts?state=open&per_page=100" \
  --jq '[.[] | select(.security_vulnerability.package.ecosystem == "rubygems")] | length'
```

## List Open Dependabot PRs

```bash
gh pr list --repo ORG/REPO --author app/dependabot --state open \
  --json number,title,url --limit 50
```

## Check PR CI Status

```bash
gh pr view <number> --repo ORG/REPO \
  --json title,mergeable,statusCheckRollup,additions,deletions,files,reviews \
  | jq '{title, mergeable, additions, deletions,
    files: [.files[].path],
    failing: [.statusCheckRollup[]? | select(.conclusion != "SKIPPED" and .conclusion != "SUCCESS") | {name, conclusion}],
    passing: [.statusCheckRollup[]? | select(.conclusion == "SUCCESS") | .name] | length}'
```

## Dismiss an Alert

```bash
gh api -X PATCH "repos/ORG/REPO/dependabot/alerts/ALERT_NUMBER" \
  -f state=dismissed -f dismissed_reason="fix_started"
# Reasons: fix_started, inaccurate, no_bandwidth, not_used, tolerable_risk
```

**Note:** Dismissing "fixed" alerts returns HTTP 409. This is expected — the alert auto-resolved.

## Pagination

Always use `per_page=100`. If you get exactly 100, fetch `&page=2`, etc.
Default is 30, which will silently truncate your inventory.
