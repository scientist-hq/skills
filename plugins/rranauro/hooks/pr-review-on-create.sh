#!/usr/bin/env bash
# PostToolUse hook on `gh pr create`. Registered by hooks/hooks.json.
#
# Detects and delegates only — the prompt, auth, and footer live in
# pr-review.sh, so the hook, /rranauro:start-review, and manual re-runs share
# one reviewer.
#
# This fires in EVERY repo you open a PR from, which is intended: it also
# exercises the suite outside its home project. Consequence: reviews get posted
# to repos you may not control. SKIP_PR_REVIEW=1 turns it off.

set -u

[[ -n "${SKIP_PR_REVIEW:-}" ]] && exit 0

REVIEWER="${CLAUDE_PLUGIN_ROOT}/scripts/pr-review.sh"
[ -x "$REVIEWER" ] || exit 0

INPUT=$(cat)

RESULT=$(INPUT="$INPUT" python3 - 2>/dev/null <<'PY'
import json, os, re, sys
try:
    d = json.loads(os.environ.get("INPUT") or "{}")
except ValueError:
    sys.exit(0)
if d.get("tool_name") != "Bash":
    sys.exit(0)
cmd = (d.get("tool_input") or {}).get("command", "") or ""
if "gh pr create" not in cmd:
    sys.exit(0)
out = (d.get("tool_response") or {}).get("stdout", "") or ""
m = re.search(r'https://github\.com/[^\s]+/pull/\d+', out)
if not m:
    sys.exit(0)
print(m.group(0))
print(d.get("cwd") or "")
PY
)

[ -n "$RESULT" ] || exit 0

PR_URL=$(printf '%s\n' "$RESULT" | sed -n '1p')
CWD=$(printf '%s\n' "$RESULT" | sed -n '2p')
[ -n "$PR_URL" ] || exit 0
[ -n "$CWD" ] || CWD=$(pwd)

(
  cd "$CWD" 2>/dev/null || true
  "$REVIEWER" --detach --source "pr-review-on-create hook" "$PR_URL" >/dev/null 2>&1
) &

exit 0
