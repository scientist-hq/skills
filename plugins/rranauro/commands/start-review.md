# Start a PR Review (Worktree-First)

RX-specific review flow: creates a dedicated worktree of the PR's head branch
so you can verify behavior in-browser without disturbing your active feature
branch. When the PR is authored by `rranauro`, the command doubles as the
**comprehensive self-review** process — catch everything a colleague might
flag before they see it.

**Usage:** `/start-review <pr_url_or_number>`

## Step 1: Read the PR

Use the GitHub MCP tools or `gh` CLI to fetch:
- PR number, title, author
- Base branch and head branch/ref
- Changed files (summary)
- Description and any review notes

Present a brief summary to the user.

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
- Ticket URL + acceptance criteria, if known

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
worth acting on, run `/review-copilot <pr>` — it triages each Copilot
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
`/start-rx-review <pr>` on the updated HEAD for a diff-only second pass to
confirm nothing regressed.

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
