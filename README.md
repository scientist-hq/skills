# skills

Scientist.com's central catalog of Claude Code skills, slash commands, and agents.

The repo serves two distribution pipelines side by side:

| Tree | Purpose | Install |
|------|---------|---------|
| `skills/` | Knowledge skills (sacred rules, patterns, workflows). Multi-agent — works with Claude Code, Cursor, Cline, Codex, and 50+ others via [skills.sh](https://skills.sh). | `npx skills add scientist-hq/skills` |
| `plugins/` | Claude Code-specific plugins (slash commands, agents, hooks). Each plugin's commands are namespaced as `/<plugin>:<command>` automatically. | `/plugin marketplace add scientist-hq/skills` then `/plugin install <plugin>@scientist-hq-skills` |

Use whichever fits your tools. Most Claude Code users install both.

## Install — knowledge skills (`skills/`)

```bash
npx skills add scientist-hq/skills
```

Drops `rx` and `sentry` knowledge packages into `./.agents/skills/` in your current project. Multi-agent compatible.

## Install — Claude Code plugins (`plugins/`)

In a Claude Code session, register the marketplace once and install the plugins you want:

```
/plugin marketplace add scientist-hq/skills
/plugin install rx@scientist-hq-skills
/reload-plugins
```

After install, commands appear in the `/` menu as `/<plugin>:<command>`. The `rx` plugin's commands are invoked as `/rx:architect`, `/rx:pr`, `/rx:commit`, etc.

### Available plugins

- **`rx`** — Team-blessed RX workflow commands (architect, implement, review, test, qa, pr, commit, bug, explain, explore, infra, learn, post-review, recap, bump). The canonical Scientist.com command set for the RX Rails monorepo. Most devs working in RX should install this.
- **`rranauro`** — Worktree-first RX ticket lifecycle: architect, start-ticket, start-review, wait-copilot, update-main-pr, review-copilot, cleanup-worktree, worktree-gc. Personal-share plugin, opt-in — install if this workflow style suits you.

Full list lives in [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json).

### Namespacing — why this matters

Plugin commands are always namespaced as `/<plugin>:<command>` automatically by Claude Code. The canonical demonstration: both `rx` and `rranauro` ship an `architect.md` command — same filename, very different agents — and they coexist without collision:

- `rx/commands/architect.md` → invoke as `/rx:architect` (team's Senior Rails Architect)
- `rranauro/commands/architect.md` → invoke as `/rranauro:architect` (personal architectural-discussion variant)
- Your own personal command at `~/.claude/commands/architect.md` → still invoke as `/architect` (no collision with either plugin)

A plugin cannot claim the bare `/foo` slot — only files in `~/.claude/commands/` or a project's `.claude/commands/` can. That makes collisions structurally impossible and lets developers keep their own defaults un-namespaced while sharing freely under their plugin namespace.

## Contributing

Plugins fall into two governance tiers. The distinction lives in the review process and the naming convention, not in directory prefixes.

### Team-blessed plugins (e.g. `plugins/rx/`, `plugins/sentry/`)

For commands or agents the whole team should be able to install. Conventions:

- Named after a logical team or topic (a noun: `rx`, `sentry`, `infra`, …).
- PR to a team plugin needs sponsor + 1 reviewer approval; the team's sponsor curates the bar for inclusion.
- Adding a command here makes it broadly available but never automatic — every dev still opts in via `/plugin install`.

### Personal-share plugins (e.g. `plugins/rranauro/`)

For commands an individual developer wants to share without making them team policy. Conventions:

- Named after the developer's handle (`rranauro`, …) — short, easy to type, no prefix.
- Author-only review; PR exists for visibility and CI checks.
- Encourages experimentation. A command that proves widely useful can be PR'd into a team plugin later.

### `skills/` — multi-agent knowledge skills

Keep using the existing skills.sh structure (`skills/<name>/SKILL.md` + subfiles). Knowledge artifacts that should work across agents belong here, not in a plugin.

## Plugin layout reference

```
plugins/<plugin-name>/
  .claude-plugin/
    plugin.json         # name, description, author
  commands/             # /<plugin>:<command-name>
    foo.md
  agents/               # optional
  skills/               # optional — plugin-private skill content
  hooks/                # optional
```

See [`plugins/rx/`](plugins/rx/) for the canonical team-plugin example and [`plugins/rranauro/`](plugins/rranauro/) for the personal-share pattern.
