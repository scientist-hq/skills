# Webhook Preflight Script — Kanban Producer Architecture

## Status: In Progress (PR #20 open on scientist-hq/skills, 2026-06-10)

## Problem

The rubocop-autofix webhook prompt carries ~40 lines of deterministic conditional logic that the LLM regularly fumbles: draft checks, repo path resolution, git checkout, CI log parsing, race-condition detection, line-scoping. All of this is better handled by a script.

## Architecture (current)

```
GitHub check_run → Tailscale Funnel (port 8644) → Hermes webhook → Agent (massive prompt)
```

No filter proxy exists. The file at `~/webhook-logs/filter-proxy.rb` was a dead path that was abandoned.

## Architecture (target): Script as Kanban Producer

```
GitHub check_run → Tailscale Funnel (8644) → Hermes webhook
                                                    ↓
                                          Minimal agent runs preflight script
                                                    ↓ exit 1 → done (skip, zero cost)
                                                    ↓ exit 0 → script created a kanban task
                                                                      ↓
                                                              Dispatcher picks up task
                                                                      ↓
                                                              Worker agent (fix-rubocop skill)
                                                                      ↓
                                                              Fix → commit → push → notify
```

**Key insight:** The script doesn't return JSON to the webhook agent — it creates a kanban task directly via `hermes kanban create`. The webhook agent's only job is to run the script and stop. The real work happens in a kanban worker with full retry/audit/dedup support.

## Why Kanban (vs. returning to webhook agent)

| Feature | Kanban | Return-to-agent |
|---------|--------|-----------------|
| Dedup | `--idempotency-key` (branch+SHA) | Must check git log (fragile) |
| Retry on crash | Automatic (dispatcher re-queues) | Lost, wait for next event |
| Audit trail | SQLite (comments, events, runs) | Only session logs |
| Human intervention | `kanban block`, comments | No mechanism |
| Rate limiting | Natural (dispatcher concurrency cap) | Must self-limit |
| Skip cost | Same (~2-4k tokens to run script) | Same |
| Extra latency | ~30-60s (dispatcher poll) | None |

## Decisions (confirmed)

1. **Shared checkout** — use `~/src/rx/rx` and `~/src/benchmate` directly (worktrees are a separate future upgrade)
2. **Always use LLM** — even for layout-only fixes, route through the agent (no script-only fast path)
3. **Script location** — `skills/fix-rubocop/scripts/rubocop-preflight.rb` in the skills repo
4. **Agent invocation** — Kanban task (dispatcher spawns worker)

## Script: `skills/fix-rubocop/scripts/rubocop-preflight.rb`

PR: https://github.com/scientist-hq/skills/pull/20

Arguments:
```bash
ruby ~/src/skills/skills/fix-rubocop/scripts/rubocop-preflight.rb \
  --repo "scientist-hq/rx" \
  --branch "feature-xyz" \
  --check-name "rubocop" \
  --conclusion "failure" \
  --head-sha "abc123def" \
  --details-url "https://github.com/..."
```

### Exit codes
- `0` — Task created (kanban task JSON on stdout)
- `1` — Skipped (reason on stderr)
- `2` — Error (details on stderr)

### Gate checks (exit 1 → no task, agent stops)

1. Conclusion is not "failure" → skip
2. Check name doesn't match `/rubocop|lint|analysis/i` → skip
3. Branch is `main`, `develop`, `master` → skip
4. PR is draft → skip
5. PR has `no-auto-fix` label → skip
6. HEAD SHA mismatch after fetch (stale event) → skip

### Kanban task creation (exit 0)

```bash
hermes kanban create \
  "Fix rubocop: ${repo_short} #${pr_number} (${branch})" \
  --assignee backend-eng \
  --body "$json_payload" \
  --skill fix-rubocop \
  --skill claude-code \
  --workspace "dir:${repo_path}" \
  --idempotency-key "rubocop-fix-${repo}-${branch}-${sha_short}" \
  --max-runtime 30m \
  --created-by rubocop-preflight \
  --json
```

The `--idempotency-key` includes HEAD SHA, so:
- Same branch + same SHA → deduped (returns existing task)
- Same branch + new SHA → new task

### Task body (JSON payload for the worker)

```json
{
  "repo_path": "/Users/developer/src/rx/rx",
  "git_root": "/Users/developer/src/rx",
  "repo_full_name": "scientist-hq/rx",
  "branch": "feature-xyz",
  "base_branch": "main",
  "head_sha": "abc123def",
  "pr_number": 1234,
  "pr_author": "orangewolf",
  "all_layout_only": true,
  "total_in_scope_offenses": 5,
  "out_of_scope_offenses": 3,
  "files": [...],
  "notify_channel": "slack:C0B29JZSYHF"
}
```

## Simplified Webhook Prompt (target)

```
A GitHub CI check_run event was received.

Run the rubocop preflight script:

  export PATH="$HOME/.rbenv/shims:$PATH"
  ruby ~/src/skills/skills/fix-rubocop/scripts/rubocop-preflight.rb \
    --repo "{repository.full_name}" \
    --branch "{check_run.check_suite.head_branch}" \
    --check-name "{check_run.name}" \
    --conclusion "{check_run.conclusion}" \
    --head-sha "{check_run.head_sha}" \
    --details-url "{check_run.details_url}"

If exit code is non-zero: respond with the stderr output and stop.
Do NOT use send_message for skips.

If exit code is zero: the script already created a kanban task.
Respond with "Queued kanban task for rubocop fix" and the script's stdout, then stop.
```

## Kanban Worker Behavior

The dispatcher spawns a worker with `fix-rubocop` + `claude-code` skills. The worker:

1. Reads the task body (JSON payload)
2. `cd` to `repo_path`, confirms branch
3. If `all_layout_only`: runs `bundle exec rubocop -a`
4. Otherwise: uses claude code for complex offenses
5. Re-runs rubocop to verify clean
6. Commits `"fix: auto-fix rubocop violations"` and pushes
7. Posts results to `notify_channel` via `send_message`
8. Calls `kanban_complete`

## Implementation Steps

1. ✅ Write `rubocop-preflight.rb` (PR #20)
2. Ensure `backend-eng` profile exists for dispatch
3. Test against real failing branch end-to-end
4. Update webhook subscription with minimal prompt
5. Update fix-rubocop SKILL.md Webhook-Triggered Mode
6. End-to-end test

## Logs

All script decisions logged to `~/webhook-logs/rubocop-preflight.log`

## Full plan document

See `~/Knowledge/plans/rx/rubocop-webhook-script-preflight.md` for extended rationale, edge cases, and future upgrades.
