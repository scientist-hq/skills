> **Profile first.** Before anything project-specific, read the dev-suite
> profile ([PROFILE.md](../PROFILE.md)): `<project>/.claude/dev-suite.json`,
> then `~/.claude/dev-suite.json`. Backticked keys (`repo.slug`,
> `commands.test`, …) and `{{placeholders}}` below refer to it. Detect from
> `git`/`gh` what the profile doesn't set; if an optional command is unset,
> skip that step and say so — never guess a stack-specific command.

Create a GitHub pull request for the current branch following the project's PR
conventions and its PR template, then start polling for Copilot's review.

If the profile sets `commands.pr`, that command owns the house conventions
(safety checks, label selection, issue linking, draft creation) and this one
must stay consistent with it — it is self-contained and does not invoke it. The
two things it adds are: (1) the PR body is filled from the repo's PR template,
and (2) after the PR is created it kicks off Copilot-review polling.

**Step 0 — Ready the branch:**
- If there are uncommitted changes, run `commands.commit` if the profile sets
  one (otherwise commit directly with `git`) and confirm the branch is ready for
  a pull request.

**Step 1 — Safety checks (stop if any fail):**
1. **Not on a protected branch**: `git branch --show-current` — if it matches
   `repo.default_branch` (or a release branch like `staging`), STOP.
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
Read the repo's actual labels with `gh label list --limit 100` and pick from
those — never invent a label, and never assume another project's taxonomy.
- Pick one type label if the repo has a type axis (e.g. a `Type: *` family).
- Add applicable cross-cutting labels (migration, style, accessibility,
  dependencies, release-notes exclusions).
- Add an area label if the repo uses them.
- If the profile sets `commands.pr`, keep this selection consistent with that
  command rather than diverging.
- If unsure, ASK.

**Step 4 — Build the body from the repo PR template:**
- Read `.github/PULL_REQUEST_TEMPLATE.md` and fill **its** sections verbatim — do
  not substitute the old `Summary/Details/Changes/Test plan` headings or add a
  generated-by footer. As of this writing the template sections are:
  - **Description** — what the PR does and which tickets it resolves. Include
    `Fixes #<issue>` here (the issue link the CI check requires). Confirm the
    changes don't break adjacent configuration or generated content the
    project calls out in its contributing docs.
  - **User Impact** — what changes for users, and which user roles. Use the
    role names the project's own docs use. "No user-facing changes" for internal
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
