# RX Worktree Setup for Running Specs

## Problem

Git worktrees for rx (`git worktree add worktrees/<name> origin/main`) lack the environment config needed to run specs. The main checkout's `.env`, `config/database.yml`, and docker services are not automatically available.

## Required Setup

After creating a worktree, from the worktree's `rx/` subdirectory:

```bash
# 1. Symlink .env from main checkout (contains DB creds, etc.)
ln -s ~/src/rx/rx/.env .env

# 2. Symlink database.yml
ln -sf ~/src/rx/rx/config/database.yml config/database.yml

# 3. Ensure docker services are running (from the main repo root)
cd ~/src/rx && just docker
# This starts: elasticsearch (port 9201), postgres (port 32780), redis (6379), etc.

# 4. Set ELASTICSEARCH_URL when running specs (not in .env by default)
ELASTICSEARCH_URL=http://localhost:9201 bundle exec rspec spec/path/to/spec.rb
```

## Docker Services (from docker-compose.yml)

| Service | Port | Notes |
|---------|------|-------|
| elasticsearch | 9201:9200 | ES 9.2.0, single-node, xpack security disabled |
| postgres | 32780:5432 | PG 17.2, trust auth |
| redis | 6379:6379 | |
| cheminee | 4001:4001 | Chemical search engine |
| mailcrab | 1025/1080 | SMTP/web UI |

## Justfile Commands

| Command | What it does |
|---------|--------------|
| `just docker` | `docker-compose up -d` (starts all services) |
| `just test` | Full parallel test suite |
| `just run` | Docker + dependencies + overmind |
| `just reindex` | `rake searchkick:reindex:all` |
| `just bootstrap` | Full setup from scratch |

## Pitfall: spec_helper requires Elasticsearch

The `spec/spec_helper.rb` has a `before(:suite)` block that reindexes multiple models via Searchkick. If ES is not reachable, ALL specs fail with:

```
Elastic::Transport::Transport::Error: Couldn't connect to server
```

This is the #1 reason Claude Code sessions get stuck on rx specs in worktrees — they can't find ES because `ELASTICSEARCH_URL` isn't set and the default (port 9200) doesn't match docker-compose (port 9201).

## Pitfall: mise/Ruby version

Always run `eval "$(mise env)"` before bundle commands in worktrees to ensure the correct Ruby version (currently 3.3.x).

## Pitfall: Claude Code in worktrees

When delegating to Claude Code via `claude -p` in a worktree, Claude Code does NOT inherit your shell env. You must either:

1. **Prepend env vars in the prompt instructions:** Tell Claude to run `export ELASTICSEARCH_URL=http://localhost:9201` and `eval "$(mise env)"` before any bundle/rspec commands.
2. **Create the symlinks before launching Claude Code:** Symlink `.env` and `config/database.yml` as shown above.
3. **Ensure docker is running:** Run `just docker` from the main checkout (`~/src/rx`) before launching Claude Code.

All three are required. If any is missing, Claude Code will spend its entire turn budget failing to run specs.
