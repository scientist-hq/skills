---
name: github-hook-router
description: >
  Deterministic routing scripts for GitHub webhook events. These scripts
  run as the first step of a webhook agent, apply gate checks, and create
  kanban tasks for work that passes. Keeps webhook prompts minimal and
  moves all conditional logic out of LLM prompts into testable Ruby.
---

# GitHub Hook Router

Scripts that receive raw GitHub webhook events, apply deterministic gate checks,
and route qualifying events into the Hermes kanban board for async processing.

## Scripts

### `scripts/rubocop-preflight.rb`

Receives a raw GitHub `check_run` event. Creates a kanban task if a rubocop CI
failure needs fixing.

**Gate checks (exit 1 to skip):**
1. Event is a `check_run` with `conclusion: "failure"`
2. Check name matches rubocop/lint/analysis (case-insensitive)
3. Branch is not protected (main, master, develop, staging, production)
4. PR is not a draft
5. PR does not have a `no-auto-fix` label

**On pass (exit 0):**
Creates a kanban task assigned to `hermes` with the `fix-rubocop` skill,
workspace set to the repo path. The kanban worker handles git operations,
rubocop scoping, fixing, and pushing.

## Webhook Subscription Prompt

The webhook prompt that invokes this script should be minimal:

```
A GitHub webhook event was received.

Run the rubocop preflight router:

  export PATH="$HOME/.rbenv/shims:$PATH"
  ruby ~/src/skills/skills/github-hook-router/scripts/rubocop-preflight.rb '{__raw__}'

If exit code is non-zero: respond with the stderr output and stop.
Do NOT use send_message for skips.

If exit code is zero: the script created a kanban task.
Respond with "Queued rubocop fix" and the stdout output, then stop.
```

### Setting up the webhook subscription

```bash
hermes webhook subscribe rubocop-autofix \
  --event check_run \
  --secret "${RUBOCOP_WEBHOOK_SECRET}" \
  --deliver log \
  --prompt 'A GitHub webhook event was received.

Run the rubocop preflight router:

  export PATH="$HOME/.rbenv/shims:$PATH"
  ruby ~/src/skills/skills/github-hook-router/scripts/rubocop-preflight.rb '"'"'{__raw__}'"'"'

If exit code is non-zero: respond with the stderr output and stop.
Do NOT use send_message for skips.

If exit code is zero: the script created a kanban task.
Respond with "Queued rubocop fix" and the stdout output, then stop.'
```

## Adding New Routers

To handle other webhook events (e.g. PR review requests, deployment failures),
add a new script under `scripts/` following the same pattern:

1. Accept raw event JSON as first argument (or stdin)
2. Apply deterministic gates (exit 1 to skip)
3. Create a kanban task on pass (exit 0)
4. Keep it simple — let the kanban worker do the complex reasoning

## Repo Path Map

The scripts map `repository.full_name` to local checkout paths. Currently:

| Repository | Local Path |
|-----------|-----------|
| `scientist-hq/rx` | `~/src/rx/rx` |
| `scientist-hq/benchmate` | `~/src/benchmate` |
| `scientist-labs/benchmate` | `~/src/benchmate` |

To add a new repo, update the `REPO_MAP` constant in the script.
