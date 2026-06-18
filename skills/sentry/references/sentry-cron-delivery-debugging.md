# Sentry Cron Job Delivery Debugging

When the team reports "not getting Sentry notifications" but the cron job shows `last_status: ok`, the problem is almost always a **delivery failure** — the agent ran and classified correctly, but the Slack post failed.

## Key Diagnostic Steps

1. **Check agent logs for delivery errors:**
   ```bash
   grep "ec59cf73424f" ~/.hermes/logs/agent.log | grep -i "deliver\|error\|fail" | tail -20
   ```

2. **Common error: `channel_not_found`**
   - The bot was removed from the channel, or channel was recreated with a new ID
   - **Most likely cause for private channels:** The bot token is missing the `groups:read` OAuth scope. Without it, `chat.postMessage` returns `channel_not_found` for private channels even if the bot is "in" the channel via Socket Mode.
   - Interactive replies still work because Socket Mode pushes events directly to the bot — no channel lookup required. Only proactive posts (cron delivery) fail.
   - The `last_status: ok` is misleading — it reflects the *agent run*, not delivery
   - The `last_delivery_error` field on the cron job may show it, but check logs for history
   - Confirm by checking logs for the `missing_scope` error adjacent to `channel_not_found`:
     ```bash
     grep -B5 "channel_not_found" ~/.hermes/logs/agent.log | grep "missing_scope"
     # Look for: 'needed': 'groups:read'
     ```

3. **Verify current channel access:**
   ```bash
   # Try sending a test message directly
   send_message(target="slack:C0B6CAX24TE", message="🧪 Test delivery")
   ```

4. **Check recent output files for [SILENT] vs actual content:**
   ```bash
   # Find runs that produced actual triage content
   grep -rl "Sentry Triage" ~/.hermes/cron/output/ec59cf73424f/ | sort | tail -5
   
   # Check if those were delivered or went silent
   tail -5 <output_file>  # Look for [SILENT] at end
   ```

5. **Look at state file for polling health:**
   ```bash
   cat ~/.hermes/scripts/.sentry-poll-state.json | python3 -c "
   import json,sys; d=json.load(sys.stdin)
   print(f'Last poll: {d[\"last_poll\"]}')
   print(f'Seen IDs count: {len(d[\"seen_ids\"])}')
   "
   ```

## Job Details

- **Job ID:** `ec59cf73424f`
- **Name:** `sentry-triage-poll`
- **Schedule:** every 10 minutes
- **Deliver:** `slack:C0B6CAX24TE` (sentry triage channel)
- **Script:** `sentry-poll-new-issues.py`
- **State file:** `~/.hermes/scripts/.sentry-poll-state.json`

## Resolution: Missing `groups:read` Scope

When the root cause is a missing OAuth scope for private channels:

1. **Identify the issue:** Logs show `'error': 'missing_scope', 'needed': 'groups:read'` from `users.conversations` calls, AND `channel_not_found` from `chat.postMessage`.
2. **Fix:** A Slack workspace admin must:
   - Go to `https://api.slack.com/apps` → select the BigMac app
   - Navigate to **OAuth & Permissions** → **Bot Token Scopes**
   - Add `groups:read` scope
   - **Reinstall the app to the workspace** (required after scope changes)
3. **Verify:** After reinstall, trigger a manual cron run or wait for the next scheduled run with actual output. Check logs confirm "delivered to slack:CHANNEL via live adapter".

**Note:** The bot's current scopes (as of June 2026): `chat:write, channels:history, channels:read, groups:history, im:history, mpim:history, users:read, app_mentions:read, reactions:read, reactions:write, pins:read, pins:write, emoji:read, commands, files:read, files:write, im:write.topic, im:read, im:write`. Missing: `groups:read` (needed to enumerate/find private channels for proactive posting).

## Pitfalls

- **Socket Mode vs API asymmetry:** The bot can receive messages and reply in private channels via Socket Mode (events are pushed to it) even WITHOUT `groups:read`. But proactive posting via `chat.postMessage` requires the bot to "find" the channel first, which needs `groups:read`. This makes the failure invisible — "the bot is in the channel and can reply to me, so why can't it post?" is the exact symptom.
- The job reports `last_status: ok` even when delivery fails — **always check logs**
- `channel_not_found` can persist silently for days; the team won't know unless they notice the absence
- The state file tracks 500 seen IDs max — if delivery is broken for too long, issues get marked "seen" without ever being posted to the team
- After fixing access, trigger a manual run (`cronjob action=run job_id=ec59cf73424f`) to verify end-to-end
- The poll script produces **empty stdout** (no print) when there are no new issues → agent responds [SILENT] → no delivery attempt. So `channel_not_found` errors only appear in logs when there actually ARE new issues to deliver.
