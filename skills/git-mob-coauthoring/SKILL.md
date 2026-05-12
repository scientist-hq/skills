---
name: git-mob-coauthoring
description: "Set git-mob co-authors so team members get credit on pair/mob commits and AI-assisted work."
---

# Git Mob Co-Authoring

When making commits on behalf of a team member (pair programming, AI-assisted coding, mob sessions), use git-mob to ensure `Co-authored-by:` credit.

## Setup

- `git-mob` installed via npm/homebrew
- `~/.git-coauthors` contains the team roster
- Global `prepare-commit-msg` hook at `~/.git-hooks/prepare-commit-msg` auto-injects co-author trailers
- Global hooks path: `git config --global core.hooksPath ~/.git-hooks`

## Team Roster

| Name               | Initials | Slack Handle |
|--------------------|----------|-------------|
| Rob Kaufman        | rk       | rob         |
| Chris Petersen     | cp       | chris       |
| Mumen Musa         | mm       | mumen       |
| Xavier Lange       | xl       | xavier      |
| tamsin woo         | tw       | tamsin      |
| Ron Ranauro        | rr       | ron         |
| Harrison Okins     | ho       | harrison    |
| Micah Iriye        | mi       | micah       |
| Hans Trautlein     | ht       | hans        |
| Steven McFarlane   | sf       | steven      |
| Maria Dubyaga      | md       | maria       |
| Crystal Richardson | cr       | crystal     |
| Lea Ann Bradford   | lb       | leaann      |
| Michael Guerrero   | mg       | michael     |
| Max                | mr       | max         |
| Alisha Evans       | ae       | alisha      |
| Gabriel Lyron      | gl       | gabriel     |
| Dylan Salay        | ds       | dylan       |
| Javier Pineda      | jp       | javier      |
| Salvador           | st       | salvador    |
| Summer             | sc       | summer      |
| Saruul Khasar      | sk       | saruul      |
| Adam Thayer        | at       | adam        |

## Workflow

### 1. Before Committing

1. Identify who should get co-author credit
2. Look up their initials from the roster
3. `cd` into the working directory
4. Set the mob: `git mob <initials>`

### 2. During Work

- All commits automatically get `Co-authored-by:` trailers via the prepare-commit-msg hook
- No manual trailer management needed

### 3. When Done

- Clear the mob when work is complete: `git solo`
- This prevents stale co-authors from leaking into future unrelated commits

### 4. AI-Assisted Coding (Claude Code, Codex, etc.)

- Do NOT add `Co-authored-by` trailers for AI assistants — the git-mob hook handles co-authoring
- The hook injects the correct human co-author automatically
- AI tools don't need to do anything special

## Commands Reference

```bash
git mob <initials>       # Set co-author(s)
git mob rk ho            # Multiple co-authors
git solo                 # Clear all co-authors
git mob-print            # Show current mob template
git mob -l               # List all available co-authors
git add-coauthor <init> "Name" email  # Add new team member
```

## Pitfalls

- `git mob` / `git solo` must be run from inside a git repository
- The prepare-commit-msg hook only fires for normal commits — `git commit --amend` and `git rebase` may not trigger it consistently
- If a repo has its own `.git/hooks/prepare-commit-msg`, the global hook won't run (local hooks take precedence unless the repo explicitly chains them)
- When force-pushing rewritten commits, co-author trailers survive the rewrite since they're in the commit message
