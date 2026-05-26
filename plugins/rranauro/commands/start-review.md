# Start a PR Review (Worktree-First)

RX-specific review flow: creates a dedicated worktree of the PR's head branch
so you can verify behavior in-browser without disturbing your active feature
branch. When the PR is authored by `rranauro`, the command doubles as the
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

**Check whether the author already received a Copilot review**
(`gh api repos/scientist-hq/rx/pulls/<pr_number>/reviews` and
`.../pulls/<pr_number>/comments`, filtered for `copilot` login) and whether
the author *replied to or addressed* those comments — we assess that in the
colleague-PR flow below.

**If the author is `rranauro` (self-review)**, check whether GitHub's
Copilot review has already posted comments
(`gh api repos/scientist-hq/rx/pulls/<pr_number>/reviews` — filter for
`copilot` login). If not, suggest the user wait ~2-5 min so the
`claude-reviewer` agent can reconcile against Copilot in one pass. The user
can override and proceed anyway.

## Step 2: Create the Review Worktree

```bash
cd /Users/ron/dev/scientist
git fetch origin pull/<pr_number>/head:pr-<pr_number>-review
git worktree add ./rx-review-<pr_number> pr-<pr_number>-review
~/bin/rx-worktree-init ./rx-review-<pr_number>
```

- Worktree path: `/Users/ron/dev/scientist/rx-review-<pr>/`
- Branch name: `pr-<pr>-review` (local, detached from the remote)

Tell the user:
- Worktree ready at `/Users/ron/dev/scientist/rx-review-<pr>/`
- Open a new terminal, `cd` there, run `claude`
- To boot the app for in-browser testing: `~/bin/rx-serve start` from the worktree root
- If a server is running in another worktree, `rx-serve` will warn and show migration differences before killing it

## Step 3: Dispatch the `claude-reviewer` agent

Spawn the `claude-reviewer` subagent with a self-contained prompt:

- `pr_number` — the PR under review
- `worktree_path` — `/Users/ron/dev/scientist/rx-review-<pr_number>/`
- **PR intent (required):** author description + ticket acceptance criteria. Instruct the agent to *anchor every finding to this intent* — a concern outside the PR's intent is at most a one-line question.
- **Severity gate:** no finding may be labeled a blocker/bug from diff-only reasoning. Anything not observed in a running app is **"suspected — needs in-app check,"** never a verdict. Findings are tiered: `confirmed-in-browser` / `suspected-from-code` / `nit`.

The agent reads the diff + changed files, opportunistically fetches any
Copilot review, writes `rx/tmp/reviews/pr-<pr_number>/claude-review.md`, and
returns a ≤200-word summary. It filters findings by author: for PRs
authored by `rranauro` it reports all four categories (bug, security, perf,
nit) plus Copilot reconciliation; for everyone else's PRs it reports only
bugs and security.

Relay the agent's summary to the user and surface the report path so the
user can open the full file.

## Step 4: Review Plan (optional)

If the PR is complex, consider creating a review-notes file at
`rx/plans/pr-<pr_number>-review-notes.md` to capture:
- Areas to scrutinize
- Test scenarios to verify in-browser
- Questions for the author

Since `rx/plans/` is symlinked across worktrees, these notes stay visible
from the home worktree too.

---

## Colleague PR flow (author ≠ `rranauro`)

The author is the subject-matter expert. Goal: confirm the PR does what it
intends, and surface genuine concerns as questions — not fix their code.

### Observe-first verification
- For any view/behavior change, **reproduce the intended flow before
  concluding anything.** Static analysis tells you *what to look at*, not
  *what to conclude*. (PR #36922 taught this: a confident diff-only "blocker"
  was refuted the moment the feature was exercised in-browser.)
- **Default to the author's own test instructions** — step Ron through them
  and check each off. Generate custom console snippets *only* if Ron asks.
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

## Self-review addendum (author == `rranauro`)

The steps below apply only when Ron is reviewing his own PR. Goal: catch
everything a colleague might flag, fix or discard it, and log the
decisions so reviewers see the thought already done.

### Step 5: Triage the claude-reviewer report

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

### Step 6: Act on Copilot's suggestions (if any)

If the claude-reviewer report flagged any Copilot comments as "Agree" or
worth acting on, run `/rranauro:review-copilot <pr>` — it triages each Copilot
comment, applies the valid ones in its own worktree, runs the affected
specs, and pushes.

Skip if all Copilot comments were "Disagree" or "Already covered" in the
reconciliation.

### Step 7: Fix the Claude-found issues

In the review worktree (or your feature worktree — your call):
- Apply edits
- `bundle exec rspec <changed specs>`
- `bundle exec rubocop <changed files>`
- Exercise the feature in-browser via `~/bin/rx-serve start` from the
  worktree root

### Step 8: Push fixes; optional second pass

Push your fixes. If the fix set was non-trivial, re-run
`/rranauro:start-review <pr>` on the updated HEAD for a diff-only second pass to
confirm nothing regressed.

---

## Drafting comments for Ron

- **Never post any comment without Ron's explicit permission.** Inline
  comments stay pending; never `submit_pending` unless he says submit/send.
- Frame findings as **questions** that leave the author latitude to
  acknowledge, defer as out-of-scope, or ignore — unless it's a degenerate
  case they genuinely should fix.
- **1-2 sentences max.** Avoid pipes `|`, tables, and heavy markup so Ron can
  paste straight into the GitHub review box.

---

## When Done

**Do not tear down the worktree automatically.** Ron may want to keep it as
a work-in-progress review sandbox across sessions. Ask first:

> "Review worktree `rx-review-<pr_number>` is still on disk. Remove it, or
> keep it for ongoing work?"

Only on explicit approval, run:

```bash
~/bin/rx-serve stop   # if still running
cd /Users/ron/dev/scientist
git worktree remove ./rx-review-<pr_number>
git branch -D pr-<pr_number>-review
```

Otherwise, leave it in place and remind the user of the teardown commands
for when they're ready.
