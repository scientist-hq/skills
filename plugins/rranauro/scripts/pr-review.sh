#!/usr/bin/env bash
# Review a GitHub PR with a headless `claude -p` session.
#
# Single source of truth for the PR-review prompt. Three entry points:
#   1. a PostToolUse hook on `gh pr create` — your own PRs, posts a PR comment
#   2. /rranauro:start-review               — colleague PRs (file output only)
#   3. manual re-run after pushing fixes    — second pass on updated HEAD
#
# Ships with the rranauro plugin. Inside a Claude session the path is
# "${CLAUDE_PLUGIN_ROOT}/scripts/pr-review.sh"; the hook resolves it from the
# plugin cache (see the resolver in hooks/pr-review-on-create.sh).
#
# Usage: pr-review.sh [options] <pr-url-or-number>
#
#   --repo <owner/name>   default: inferred from cwd by gh
#   --detach              run in background; log to ~/.claude/logs/pr-review
#   --post                post the review as a PR comment
#   --no-post             write to a local file instead
#   --source <label>      provenance label for the footer (default: manual)
#   --model <id>          default: claude-opus-5
#
# Posting default: post when the PR author is you (self-review), write to
# file otherwise. Your login is detected via `gh api user`; override with
# identity.gh_user in the profile. We never post to a colleague's PR without an explicit --post —
# outward-facing comments on someone else's work are the user's call, not the tool's.

set -uo pipefail

# --- Profile ------------------------------------------------------------------
# Project profile wins over user profile wins over detection. See PROFILE.md.
# Everything here is optional: with no profile at all the script still works,
# because identity and repo are detected from gh at runtime.
profile_get() {
  python3 - "$1" <<'PY' 2>/dev/null
import json, os, sys
key = sys.argv[1].split(".")
for path in (
    os.path.join(os.getcwd(), ".claude", "dev-suite.json"),
    os.path.expanduser("~/.claude/dev-suite.json"),
):
    try:
        with open(path) as fh:
            node = json.load(fh)
    except Exception:
        continue
    for part in key:
        if not isinstance(node, dict) or part not in node:
            node = None
            break
        node = node[part]
    if node not in (None, ""):
        print(node)
        break
PY
}

ME=""
MODEL="claude-opus-5"
SOURCE="manual"
REPO=""
DETACH=0
POST="auto"
PR_ARG=""

while [ $# -gt 0 ]; do
  case "$1" in
    --repo)    REPO="$2"; shift 2 ;;
    --detach)  DETACH=1; shift ;;
    --post)    POST="yes"; shift ;;
    --no-post) POST="no"; shift ;;
    --source)  SOURCE="$2"; shift 2 ;;
    --model)   MODEL="$2"; shift 2 ;;
    -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
    *)         PR_ARG="$1"; shift ;;
  esac
done

[ -n "$PR_ARG" ] || { echo "error: no PR given" >&2; exit 1; }

# --- Resolve PR ---------------------------------------------------------------
if [ -z "$REPO" ]; then
  case "$PR_ARG" in
    https://github.com/*)
      REPO="$(printf '%s' "$PR_ARG" | sed -E 's#https://github.com/([^/]+/[^/]+)/pull/.*#\1#')" ;;
    *)
      REPO="$(profile_get repo.slug)"
      [ -n "$REPO" ] || REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)" ;;
  esac
fi
[ -n "$REPO" ] || { echo "error: could not resolve repo" >&2; exit 1; }

PR_NUM="$(printf '%s' "$PR_ARG" | grep -Eo '[0-9]+$')"
[ -n "$PR_NUM" ] || { echo "error: could not parse PR number from '$PR_ARG'" >&2; exit 1; }
PR_URL="https://github.com/${REPO}/pull/${PR_NUM}"

AUTHOR="$(gh pr view "$PR_NUM" --repo "$REPO" --json author -q .author.login 2>/dev/null)"
[ -n "$AUTHOR" ] || { echo "error: could not fetch PR #${PR_NUM} in ${REPO}" >&2; exit 1; }

# Who am I? Detected, not configured — `gh api user` is right for every
# developer without setup. identity.gh_user is an override for the odd case
# (a shared bot account, a second login).
ME="$(profile_get identity.gh_user)"
[ -n "$ME" ] || ME="$(gh api user -q .login 2>/dev/null)"

# Unknown login is treated as "not mine": the conservative side of the fork,
# since the consequence is writing to a file instead of posting to someone
# else's PR.
if [ "$POST" = "auto" ]; then
  if [ -n "$ME" ] && [ "$AUTHOR" = "$ME" ]; then POST="yes"; else POST="no"; fi
fi

if [ -n "$ME" ] && [ "$AUTHOR" = "$ME" ]; then
  SCOPE="full — bug, security, perf, standards, nit"
else
  SCOPE="bugs and security only — omit perf/standards/nit sections entirely"
fi

# --- Force subscription auth --------------------------------------------------
# Hooks and shells inherit whatever is exported. If ANTHROPIC_API_KEY is set
# (e.g. from ~/.zshrc) the headless `claude -p` below silently bills to the API
# account instead of the Max subscription. Unset it so the CLI falls back to the
# OAuth login in ~/.claude/.
#
# The footer always reads plain "subscription" — the rail is what matters, and
# the PR comment is public. Whether a key happened to be exported is local
# environment trivia; it goes to the log only.
AUTH="subscription"
AUTH_NOTE=""
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  AUTH_NOTE=" (ANTHROPIC_API_KEY was set and unset)"
  unset ANTHROPIC_API_KEY
fi
unset ANTHROPIC_AUTH_TOKEN ANTHROPIC_BASE_URL

# --- Provenance footer --------------------------------------------------------
# Computed here because the shell knows the invocation context and the headless
# session does not. Appended verbatim so every review self-reports where it came
# from, on what, and — critically — which billing rail it used.
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"

FOOTER="

---
<sub>Generated by \`pr-review.sh\` via \`${SOURCE}\` on host \`$(hostname -s)\` · worktree \`${REPO_ROOT}\` · branch \`${BRANCH}\` · model \`${MODEL}\` · auth **${AUTH}** · $(date -u +%FT%TZ)</sub>"

# --- Delivery -----------------------------------------------------------------
# Artifacts land in the main checkout, not the current worktree — a worktree's
# tmp/ dies with it. repo.workspace_root is what makes that survive teardown;
# without it we fall back to the current git root, which is correct for a
# single-checkout project and merely fragile for a worktree user.
WORKSPACE_ROOT="$(profile_get repo.workspace_root)"
WORKSPACE_ROOT="${WORKSPACE_ROOT/#\~/$HOME}"
[ -n "$WORKSPACE_ROOT" ] || WORKSPACE_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

APP_SUBDIR="$(profile_get repo.app_subdir)"
REVIEWS_REL="$(profile_get paths.reviews)"
[ -n "$REVIEWS_REL" ] || REVIEWS_REL="tmp/reviews"

OUT_DIR="${WORKSPACE_ROOT}${APP_SUBDIR:+/$APP_SUBDIR}/${REVIEWS_REL}/pr-${PR_NUM}"
OUT_FILE="${OUT_DIR}/claude-review.md"

if [ "$POST" = "yes" ]; then
  DELIVERY="Post the review as a PR comment: pipe the body into \`gh pr comment ${PR_URL} --body-file -\`."
else
  DELIVERY="Do NOT post anything to GitHub. Write the review to \`${OUT_FILE}\` (\`mkdir -p\` the directory first). This PR is authored by someone else; posting is the user's decision, not yours."
fi

# --- Prompt -------------------------------------------------------------------
# Written for a senior engineer in the project's stack. Name the specific
# instance and why it matters here; no tutorials on framework basics.
PROMPT="You are running headlessly to review pull request ${PR_URL} (author: ${AUTHOR}).

Gather:
1. \`gh pr view ${PR_NUM} --repo ${REPO} --json title,body,author,files\` — title, body, changed files.
2. \`gh pr diff ${PR_NUM} --repo ${REPO}\` — the full diff.
3. The PR's linked ticket, if the body references one — its acceptance criteria are part of the intent.
4. Opportunistically, any Copilot review: \`gh api repos/${REPO}/pulls/${PR_NUM}/reviews\`, filtering for a \`user.login\` containing \`copilot\`. If one exists, fetch its comments via \`.../reviews/<id>/comments\`. If none exists yet, skip silently — do not wait or retry.

Review principles:
- **Anchor every finding to the PR's intent** (author description + ticket ACs). Any mature codebase has latent side-effect bugs; concerns outside this PR's intent flood the signal. One outside the intent is at most a one-line question.
- **No diff-only blockers.** You read code, not a running app. Anything you have not seen fail is 'suspected — needs in-app check', not a verdict. Reserve confident calls for the unambiguous (clear nil deref, missing auth check).
- **The author is the subject-matter expert.** Frame findings as questions that leave latitude to acknowledge, defer, or ignore.
- **Check the diff against the repo's documented conventions** in any CLAUDE.md files that apply to the changed paths — cite the specific rule when the diff breaks one. Review the change, not the codebase.
- Skip style nits and anything rubocop already enforces.

Scope for this PR: ${SCOPE}.

Write the review in this shape. The body MUST begin with these two lines, exactly:

    <!-- claude-pr-review -->
    ## Automated review by Claude Opus 5

The HTML comment is a stable marker that /rranauro:review-copilot uses to find this review (it is posted under a human gh user, not a bot login, so login filtering does not work). Do not omit or alter it.

Then:

**Intent** — 1-2 sentences on what this PR is for. If intent is unknown, say so.
**AC alignment** — meets | partial | gaps, plus one line on what looks unaddressed.
**Migrations & associations** — list any schema migration or new/changed model association, then flag only the odd ones (missing index on an FK or queried column, a \`dependent:\` that cascades further than intended, a non-concurrent index, a locking default/backfill). If routine, say 'nothing unexpected' — do not pad.
**New models & modules** — inventory of new models/modules/services/concerns, one-line purpose each, or 'none'. Note only if one lands somewhere discouraged (\`Pg::\` namespace, business logic in a model or controller instead of app/services/).
**### Inline findings** — for anything tied to a line, start the bullet with \`**\\\`<path>:<line>\\\`** — <finding>\` so /rranauro:review-copilot can dedup against Copilot's inline comments by (path, line). Tag each \`[suspected-from-code]\` or \`[confirmed]\`.
**### General notes** — broader observations not tied to a line.
**Copilot reconciliation** — only if a Copilot review was found. Per comment: Agree (roll into your findings, do not double-count) / Disagree (one line why) / Already covered. Also flag anything significant Copilot missed. Copilot reasons from the diff too, so agreeing with it does not promote a finding to a verdict.
**Questions for author** — open-ended, for anything that may be a deliberate design choice.

Omit any section that would be empty rather than writing 'N/A'.

The body MUST end with exactly the following footer, verbatim, as its final lines — do not alter, reflow, or omit it:
${FOOTER}

Delivery: ${DELIVERY}

Do not modify any files in the working tree."

# --- Run ----------------------------------------------------------------------
LOGDIR="$HOME/.claude/logs/pr-review"
mkdir -p "$LOGDIR"
LOG="$LOGDIR/$(date +%Y%m%d-%H%M%S)-pr${PR_NUM}.log"

CLAUDE_BIN="$(command -v claude || true)"
[ -n "$CLAUDE_BIN" ] || CLAUDE_BIN="$HOME/.local/bin/claude"

# Log the diff size so an unexpectedly expensive run is visible after the fact.
# Resolve the base from the remote HEAD rather than assuming main, so a stacked
# branch still reports something meaningful. Advisory only — no auto-downgrade.
CHANGED="$(
  base_ref="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)"
  [ -n "$base_ref" ] || base_ref="origin/main"
  mb="$(git merge-base HEAD "$base_ref" 2>/dev/null)" || exit 0
  [ -n "$mb" ] || exit 0
  git diff --shortstat "$mb" 2>/dev/null | tail -1
)"

echo "$(date -u +%FT%TZ) pr=${PR_URL} author=${AUTHOR} source=${SOURCE} model=${MODEL} auth=${AUTH}${AUTH_NOTE} post=${POST} changed=[${CHANGED}]" >>"$LOG"

if [ "$DETACH" = "1" ]; then
  nohup "$CLAUDE_BIN" -p --model "$MODEL" --max-turns 15 --dangerously-skip-permissions "$PROMPT" \
    >>"$LOG" 2>&1 </dev/null &
  disown
  echo "review of PR #${PR_NUM} running in background; log: $LOG"
else
  "$CLAUDE_BIN" -p --model "$MODEL" --max-turns 15 --dangerously-skip-permissions "$PROMPT" 2>&1 | tee -a "$LOG"
  [ "$POST" = "no" ] && echo "review written to: $OUT_FILE"
fi

exit 0
