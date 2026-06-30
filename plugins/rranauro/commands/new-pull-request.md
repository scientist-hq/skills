Create a GitHub pull request for the current branch following the RX team's PR
conventions and the repo's PR template, then start polling for Copilot's review.

This command follows the same conventions as `/rx:pr` (safety checks, label
selection, issue linking, draft creation) — it is self-contained, so it does not
invoke `/rx:pr`, but it must stay consistent with it. The two things it adds on
top of `/rx:pr` are: (1) the PR body is filled from the repo's PR template, and
(2) after the PR is created it kicks off Copilot-review polling.

**Step 0 — Ready the branch:**
- If there are uncommitted changes, run the `/rx:commit` skill first and confirm
  the branch is ready for a pull request.

**Step 1 — Safety checks (stop if any fail):**
1. **Not on main**: `git branch --show-current` — if `main` or `staging`, STOP.
2. **Clean working tree**: `git status` — if uncommitted changes remain, STOP and
   ask the user to commit or stash.
3. **Pushed**: `git log origin/main..HEAD --oneline` — if the branch isn't pushed
   (or is behind its upstream), `git push -u origin HEAD`.

**Step 2 — Gather context:**
- Read the commits and diff: `git log origin/main..HEAD --oneline` and
  `git diff origin/main...HEAD --stat`. Review ALL commits, not just the latest.
- Read any plan file matching the branch in `plans/` for context.
- **Find the issue number** in: the branch name (e.g. `37980-rfx-service-layer`),
  the plan file, or `$ARGUMENTS`. If none is found, ASK the user — the
  `VerifyIssue` CI check fails PRs without a linked issue.

**Step 3 — Determine labels:**
Use the same label set as `/rx:pr` (keep these in sync with that command rather
than inventing new ones):
- Type (pick one): `Type: Feature` (new functionality), `Type: Improvement`
  (enhances existing), `Type: Fix` (bug), `Type: Cleanup` (refactor),
  `Type: Infrastructure` (tooling), `Hotfix` (urgent prod fix).
- Add as applicable: `Migration` (DB migration included), `Style` (UI/design),
  `Accessibility`, `Dependencies`, `Internal` (exclude from release notes).
- Area as applicable: `Storefront`, `Backoffice`, `Accounting`, `Security`.
- If unsure, ASK.

**Step 4 — Build the body from the repo PR template:**
- Read `.github/PULL_REQUEST_TEMPLATE.md` and fill **its** sections verbatim — do
  not substitute the old `Summary/Details/Changes/Test plan` headings or add a
  generated-by footer. As of this writing the template sections are:
  - **Description** — what the PR does and which tickets it resolves. Include
    `Fixes #<issue>` here (the issue link the CI check requires). Confirm the
    changes don't break scripts, configuration rules, or dynamic forms
    (see `docs/Checking-Dynamic-Content.md`).
  - **User Impact** — what changes for users, and which users (Researcher,
    Supplier, Scientist Admin, etc.). Use "No user-facing changes" for internal
    work.
  - **Instructions** — numbered, specific QA steps for reviewers; reference real
    files/paths/URLs and what you ran to prove the change works.
  - **Screenshots** — images for UI changes; "N/A" otherwise.
- If the template file changes, follow the file — these section names are a
  snapshot, not the source of truth.

**Step 5 — Create the PR (draft):**
```bash
gh pr create \
  --title "<concise imperative title under 70 chars>" \
  --body "$(cat <<'EOF'
<body content following the template>
EOF
)" \
  --label "Type: ..." \
  --label "<area>" \
  --draft
```
- Create as **draft** unless the user says otherwise.
- Use `Fixes #N` to reference the issue. Add multiple `--label` flags as needed.

**Step 6 — Confirm:**
- Print the PR URL and a short summary: title, labels, linked issue, draft status.
- Remind: "Mark as ready for review when you're satisfied: `gh pr ready`."

**Step 7 — Start polling for Copilot review:**
GitHub Copilot reviews PRs automatically and usually takes 3–5 minutes. After
printing the PR URL, tell the user:
> "Starting `/loop 90s /rranauro:wait-copilot <PR#>` to poll for Copilot's review
> — you'll get a macOS notification when it's ready, then stop the loop and I'll
> run `/rranauro:review-copilot`."

Then invoke `/loop` via the Skill tool with args `90s /rranauro:wait-copilot <PR#>`
so polling begins immediately.

**Arguments:** $ARGUMENTS
If the user passed arguments, treat them as guidance for the PR title, scope, issue
number, or target branch (e.g., `/rranauro:new-pull-request ready for review` →
create non-draft and mention readiness).
