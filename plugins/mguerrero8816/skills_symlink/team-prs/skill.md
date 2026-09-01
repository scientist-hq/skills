---
description: List all open PRs for the Labyrinth team, showing age, author, and URL for each.
---

## Team

Team name: **Labyrinth**
Members: `rranauro`, `mguerrero8816`, `micahiriye`, `mrobock`, `eyardley`
Org: `scientist-hq` — search **every repo in the org**, not just `rx`.

## Command

Org-wide search (`gh search prs`) doesn't expose `reviewRequests`/`reviews`, so this is two steps: first discover which repos each member has open PRs in (`--archived=false` drops archived repos here), then run the rich per-repo query over that repo set.

```bash
repos=$(for u in rranauro mguerrero8816 micahiriye mrobock eyardley; do gh search prs --owner scientist-hq --author "$u" --state open --draft=false --archived=false --json repository --jq '.[].repository.nameWithOwner'; done | sort -u)
for repo in ${(f)repos}; do
  for u in rranauro mguerrero8816 micahiriye mrobock eyardley; do
    gh pr list --repo "$repo" --author "$u" --state open --draft=false --json number,title,author,createdAt,url,reviewRequests,reviews,assignees
  done
done | jq -s '[.[][]] | sort_by(.createdAt)'
```

This returns a JSON array sorted oldest-first. Each item has: `number`, `title`, `author.login`, `createdAt`, `url`, `reviewRequests`, `reviews`, `assignees`. Derive the repo from `url` (`https://github.com/scientist-hq/<repo>/pull/<n>` → segment 5).

> Runs in zsh — `${(f)repos}` splits the discovered repo list on newlines. Keep the member lists as literal words (zsh doesn't word-split an unquoted `$var`).

## Output Format

The table must stay narrow enough to render in a terminal, so columns are aggressively abbreviated:

| Days | Repo | Users | Copilot | URL | Author | Title |
|------|------|-------|---------|-----|--------|-------|

- **Days**: number of days since `createdAt` — just the integer, no unit label.
- **Repo**: the repository name derived from `url`, truncated to 10 characters with a `…` appended if trimmed.
- **Users**: unique, comma-separated list combining reviewers (`reviewRequests[].login` + `reviews[].author.login`) and `assignees[].login`, excluding any logins containing `copilot` or `[bot]`, and excluding the PR's own `author.login`. Show `—` if empty.
- **Copilot**: check `reviews` for any entry whose `author.login` contains `copilot`. Show `Yes` if found, `-` if not.
- **URL**: the `url` field with the `https://` prefix stripped (e.g. `github.com/scientist-hq/rx/pull/38764`) — never truncate the rest; it must stay copy-pasteable.
- **Author**: `author.login`
- **Title**: truncate to 20 characters, appending `…` if trimmed

## Filtering

Exclude any PR open for more than 100 days — those are long-abandoned and only add noise. Drop them silently; do not list them or mention the count.

Sort oldest-first (already guaranteed by the command). If there are no open PRs left after filtering, say so.
