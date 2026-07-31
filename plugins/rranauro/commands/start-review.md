# Start a PR Review (Worktree-First)


> **Profile first.** Before anything project-specific, read the dev-suite
> profile ([PROFILE.md](../PROFILE.md)): `<project>/.claude/dev-suite.json`,
> then `~/.claude/dev-suite.json`. Backticked keys (`repo.slug`,
> `commands.test`, …) and `{{placeholders}}` below refer to it. Detect from
> `git`/`gh` what the profile doesn't set; if an optional command is unset,
> skip that step and say so — never guess a stack-specific command.

Review flow: creates a dedicated worktree of the PR's head branch
so you can verify behavior in-browser without disturbing your active feature
branch. When the PR is your own, the command doubles as the
**comprehensive self-review** process — catch everything a colleague might
flag before they see it.

**Usage:** `/rranauro:start-review <pr_url_or_number>`

## Step 1: Read the PR

Use the GitHub MCP tools or `gh` CLI to fetch:
- PR number, title, author
- Base branch and head branch/ref
- Changed files (summary)
- Description and any review notes
- **The PR's intent** — author description *and* the linked ticket's acceptance criteria. This is the lens for every later finding.

Present a brief summary to the user, including the intent.

**Whose PR is this?** Compare the PR author to your own GitHub login —
`gh api user -q .login`, or `identity.gh_user` from the profile if set. That
comparison drives the two flows below; never hardcode a login. If the login
can't be resolved, treat the PR as a colleague's: the conservative branch,
since it withholds posting rather than publishing uninvited.

**Check whether the author already received a Copilot review**
(`gh api repos/{{repo.slug}}/pulls/<pr_number>/reviews` and
`.../pulls/<pr_number>/comments`, filtered for `copilot` login) and whether
the author *replied to or addressed* those comments — we assess that in the
colleague-PR flow below.

**If the PR is your own (self-review)**, note that the hook-posted
review almost always predates Copilot — it fires at `gh pr create`, and
Copilot takes ~2-5 min. So the existing review usually has no Copilot
reconciliation. If Copilot has since posted
(`gh api repos/{{repo.slug}}/pulls/<pr_number>/reviews` — filter for
`copilot` login) and reconciliation would be useful, offer to re-run
`${CLAUDE_PLUGIN_ROOT}/scripts/pr-review.sh` for a second pass that includes it. the user can
decline and work from the original.

## Step 2: Create the Review Worktree

```bash
mkdir -p {{repo.worktree_root}}
cd {{repo.workspace_root}}
git fetch origin pull/<pr_number>/head:pr-<pr_number>-review
git worktree add {{repo.worktree_root}}/{{repo.worktree_prefix}}-review-<pr_number> pr-<pr_number>-review
```

**Now fire the review, before provisioning.** Unless Step 3's existing-review
check already found one, start it detached so it runs in its own headless
context while `{{commands.worktree_init}}` installs deps — that provisioning takes
minutes, and the review has no reason to wait for it:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/pr-review.sh --detach --source start-review <pr_number>
```

Run it from `{{repo.workspace_root}}`, not the worktree — the script resolves
`repo.*` from `.claude/dev-suite.json` relative to its cwd, and that is what puts
artifacts in the home checkout instead of the throwaway worktree.

`--detach` returns immediately and logs to `~/.claude/logs/pr-review/<ts>-pr<n>.log`.
Tell the user the review is running and where the log is, then continue:

```bash
{{commands.worktree_init}} {{repo.worktree_root}}/{{repo.worktree_prefix}}-review-<pr_number>
```

- Worktree path: `{{repo.worktree_root}}/{{repo.worktree_prefix}}-review-<pr>/`
- Branch name: `pr-<pr>-review` (local, detached from the remote)

Tell the user:
- Worktree ready at `{{repo.worktree_root}}/{{repo.worktree_prefix}}-review-<pr>/`
- Open a new terminal, `cd` there, run `claude`
- To boot the app for in-browser testing: `{{commands.serve}} start` from the worktree root
- If a server is running in another worktree, `{{commands.serve}}` will warn and show migration differences before killing it

## Step 3: Get the Claude review

The review prompt lives in one place — `${CLAUDE_PLUGIN_ROOT}/scripts/pr-review.sh`. It
anchors findings to the PR's intent, applies the severity gate (nothing
observed in a running app is a verdict — only "suspected, needs in-app
check"), opportunistically reconciles any Copilot review, and scopes by
author: full categories for your own PRs, bugs and security only for everyone
else.

**First check whether a review already exists.** For the user's own PRs the
`pr-review-on-create` hook fires on `gh pr create` and posts the review as a
PR comment marked with `<!-- claude-pr-review -->`:

```bash
gh pr view <pr_number> --repo {{repo.slug}} --json comments \
  -q '.comments[] | select(.body | contains("<!-- claude-pr-review -->")) | .body'
```

If that returns a review, use it — don't re-run. It's the persistent copy and
it already lives where colleagues can see it.

**Otherwise collect the detached run.** Colleague PRs and second passes after
pushing fixes have no hook trigger, so Step 2 already started one. It writes to:

```
{{repo.workspace_root}}/{{repo.app_subdir}}/{{paths.reviews}}/pr-<pr_number>/claude-review.md
```

Wait for that file to appear rather than re-running the script — a second
invocation duplicates the work and the token spend. If it isn't there yet, say
so and check again; if it never arrives, read the tail of
`~/.claude/logs/pr-review/<ts>-pr<n>.log` for the failure and report it. A
detached run that dies is silent by construction — the log is the only place it
surfaces, so never assume success from the absence of an error.

If Step 2 was skipped (resuming an old session, worktree already existed), run
it in the foreground instead:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/pr-review.sh --source start-review <pr_number>
```

Posting is decided by authorship: the user's own PRs get the review posted as a
comment; colleague PRs write to the file above — the **absolute home path**,
never the worktree's `tmp/`, which is worktree-specific and destroyed on
teardown. Never pass `--post` on someone else's PR without the user saying so.

**Relay a ≤120-word TL;DR — do not re-expand the review.** Give the user a verdict
line, AC alignment, finding counts, the top concern (say so if it's
`suspected-from-code`), whether Copilot has weighed in, and the comment URL or
file path. Then stop. Do not paste findings or add commentary. the user reads the
TL;DR and asks for whatever detail he wants — at which point you pull only the
section he asked about. Everything else is pull, not push.

## Step 4: Generate the in-app walkthrough (always)

Every review drops a self-contained `walkthrough.html` so the in-app test
steps can be followed in the browser while you and the user discuss findings in
the terminal — without losing your place. Do this on **every** review, not
just complex ones.

**Always write it to the HOME repo, at an absolute path:**

```
{{repo.workspace_root}}/{{repo.app_subdir}}/{{paths.reviews}}/pr-<pr_number>/walkthrough.html
```

`mkdir -p` the dir first. Never write it into the worktree's `tmp/` — that
path is worktree-specific and vanishes on teardown; the home path is stable,
opens the same in the browser regardless of which worktree runs the app, and
survives worktree removal. It sits alongside `claude-review.md`.

Seed it from two sources:
- **The author's own in-app test instructions** (the PR "Instructions"
  section) — one checklist row per step. Default to these; don't invent your
  own steps unless the user asks.
- **The Claude review findings** (from the PR comment or the review file) —
  especially `suspected-from-code` ones
  that need an in-app check. Give each its own *starred* row with ✅/❌
  verdict buttons, so exercising the feature confirms or refutes it.

Requirements for the file (self-contained, no build step, no network):
- Inline `<style>` + `<script>` only; must open via `file://`.
- Header: PR number, title, author, and the **intent** (the review lens).
- A pinned "findings to verify" panel listing the reviewer's suspected items.
- An interactive checklist: one row per author test step; each row has a
  checkbox, a notes textarea, and (for finding-linked rows) verdict buttons.
- Persist **all** state in `localStorage` keyed by the PR number, so reloads
  and tab-switching never lose progress. Include a Reset button and a
  progress counter.

The non-obvious part is the data-driven, self-persisting skeleton — the rest
is presentation. Minimal shape to follow:

```html
<script>
const STEPS = [ /* {id, title, desc, watch?, star?} per author step + finding */ ];
const KEY = "pr<PR>-walkthrough-v1";
let state = JSON.parse(localStorage.getItem(KEY) || "{}");
function save(){ localStorage.setItem(KEY, JSON.stringify(state)); render(); }
function render(){ /* checkbox + <textarea> + (star ? verdict buttons) per STEP,
                     wired to state[step.id] = {done, note, verdict}; save() on change */ }
render();
</script>
```

Surface the `file://` path to the user and tell him it persists after worktree
teardown. Then walk him through the checklist per the colleague/self-review
flow below — defaulting to the author's own steps — ticking rows (or letting
him tick them) as you go.

## Step 5: Review Plan (optional)

If the PR is complex, consider creating a review-notes file at
`{{paths.plans}}/pr-<pr_number>-review-notes.md` to capture:
- Areas to scrutinize
- Test scenarios to verify in-browser
- Questions for the author

Since `{{paths.plans}}/` is symlinked across worktrees, these notes stay visible
from the home worktree too.

---

## Colleague PR flow (author ≠ you)

The author is the subject-matter expert. Goal: confirm the PR does what it
intends, and surface genuine concerns as questions — not fix their code.

### Observe-first verification
- For any view/behavior change, **reproduce the intended flow before
  concluding anything.** Static analysis tells you *what to look at*, not
  *what to conclude*. (PR #36922 taught this: a confident diff-only "blocker"
  was refuted the moment the feature was exercised in-browser.)
- **Default to the author's own test instructions** — step the user through them
  and check each off. Generate custom console snippets *only* if the user asks.
- **Trust the author's setup.** Don't triage or fact-check their instructions
  (a scope that errors locally, etc.) — work around it quietly; it's not ours
  to pin.
- After any side conversation, **re-state the in-app checklist** so we can
  resume checking it off.

### Assess Copilot (don't fix)
- If the author received a Copilot review, assess whether they **addressed**
  its comments, and give our own read on each.
- May run `/rranauro:review-copilot <pr>` in **analysis-only** mode (triage
  each comment) — **never the fix-it dialog.** We do not fix another person's
  PR.

---

## Self-review addendum (author == you)

The steps below apply only when the user is reviewing his own PR. Goal: catch
everything a colleague might flag, fix or discard it, and log the
decisions so reviewers see the thought already done.

### Step 6: Triage the Claude review

For each finding, decide one of:
- **Fix** — apply the change
- **Discard** — with a one-line reason
- **Defer** — tracked as a follow-up ticket

Maintain a running note in the PR description under a **"Self-review
notes"** heading so colleagues can see what's already been considered:

```markdown
## Self-review notes
- Addressed: N+1 in `site_panel#show`, missing index on `site_requests.scope_id`
- Discarded: suggested rename of `ItemScope#matches?` — existing callers
  rely on the current name
- Deferred to #35639: extract `GridPanel::Scopes` presenter
```

### Step 7: Act on Copilot's suggestions (if any)

If the Claude review flagged any Copilot comments as "Agree" or
worth acting on, run `/rranauro:review-copilot <pr>` — it triages each Copilot
comment, applies the valid ones in its own worktree, runs the affected
specs, and pushes.

Skip if all Copilot comments were "Disagree" or "Already covered" in the
reconciliation.

### Step 8: Fix the Claude-found issues

In the review worktree (or your feature worktree — your call):
- Apply edits
- `{{commands.test}} <changed specs>`
- `{{commands.lint}} <changed files>`
- Exercise the feature in-browser via `{{commands.serve}} start` from the
  worktree root

### Step 9: Push fixes; optional second pass

Push your fixes. If the fix set was non-trivial, re-run
`/rranauro:start-review <pr>` on the updated HEAD for a diff-only second pass to
confirm nothing regressed.

---

## Drafting comments for the user

- **Never post any comment without the user's explicit permission.** Inline
  comments stay pending; never `submit_pending` unless he says submit/send.
- Frame findings as **questions** that leave the author latitude to
  acknowledge, defer as out-of-scope, or ignore — unless it's a degenerate
  case they genuinely should fix.
- **1-2 sentences max.** Avoid pipes `|`, tables, and heavy markup so the user can
  paste straight into the GitHub review box.

---

## When Done

**Do not tear down the worktree automatically.** the user may want to keep it as
a work-in-progress review sandbox across sessions. Ask first:

> "Review worktree `{{repo.worktree_prefix}}-review-<pr_number>` is still on disk. Remove it, or
> keep it for ongoing work?"

Only on explicit approval, run:

```bash
{{commands.serve}} stop   # if still running
cd {{repo.workspace_root}}
git worktree remove --force {{repo.worktree_root}}/{{repo.worktree_prefix}}-review-<pr_number>   # --force if a run dirtied generated files
git branch -D pr-<pr_number>-review
git worktree prune
rm -rf {{repo.worktree_root}}/{{repo.worktree_prefix}}-review-<pr_number>   # untracked residue (tmp/, node_modules) git leaves behind
```

The review artifacts (`claude-review.md` + `walkthrough.html`) live in the
**home** repo at `{{paths.reviews}}/pr-<pr_number>/`, so worktree removal does
**not** touch them — they persist across sessions. Remove that dir separately
only if the user asks to clear the artifacts too:

```bash
rm -rf {{repo.workspace_root}}/{{repo.app_subdir}}/{{paths.reviews}}/pr-<pr_number>
```

Otherwise, leave the worktree in place and remind the user of the teardown
commands for when they're ready.
