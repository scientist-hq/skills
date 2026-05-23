---
description: List all open PRs for the Labyrinth team, showing age, author, and URL for each.
---

## Team

Team name: **Labyrinth**
Members: `rranauro`, `mguerrero8816`, `micahiriye`, `mrobock`, `eyardley`
Repo: `scientist-hq/rx`

## Command

Run one query per member and combine the results:

```bash
for user in rranauro mguerrero8816 micahiriye mrobock eyardley; do
  gh pr list --repo scientist-hq/rx --author "$user" --state open --draft=false --json number,title,author,createdAt,url,reviewRequests,reviews
done | jq -s '[.[][]] | sort_by(.createdAt)'
```

This returns a JSON array sorted oldest-first. Each item has: `number`, `title`, `author.login`, `createdAt`, `url`, `reviewRequests`, `reviews`.

## Output Format

Present results as a markdown table:

| Days | Reviewers | Copilot | URL | Author | Title |
|------|-----------|---------|-----|--------|-------|

- **Days**: number of days since `createdAt` — just the integer, no unit label.
- **Reviewers**: comma-separated list of `login` values from `reviewRequests`, excluding any logins containing `copilot` or `[bot]`. Show `—` if empty.
- **Copilot**: check `reviews` for any entry whose `author.login` contains `copilot`. Show `Yes` if found, `-` if not.
- **URL**: the full `url` field — never truncate.
- **Author**: `author.login`
- **Title**: truncate to 60 characters, appending `…` if trimmed

Sort oldest-first (already guaranteed by the command). If there are no open PRs, say so.
