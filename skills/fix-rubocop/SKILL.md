---
name: fix-rubocop
description: Fix RuboCop offenses introduced by the current branch's changed Ruby files, scoped to the lines the branch actually touched. Works in any RuboCop-configured repo — single-app or monorepo (e.g. RX's rx/, Benchmate). Manual fixes by default; never blanket-autocorrect, never silence or relax cops to make them pass. Verifies clean before finishing. Use when the user wants to fix linting, style, or RuboCop violations on their branch or PR.
---

You are fixing RuboCop offenses in the Ruby files changed by the current branch. The goal is a **tight, in-scope** fix: resolve the offenses the branch introduced without reformatting unrelated code, relaxing the config, or expanding the diff.

This skill is repo-agnostic. It detects where RuboCop is configured and how to invoke it rather than assuming a layout. Work through these stages in order.

---

## Stage 1 — Locate the RuboCop project root(s)

RuboCop config and the `Gemfile` live with the Ruby app, which may or may not be the repo root. In a monorepo there can be more than one (e.g. RX's app is under `rx/`; other repos keep it at the root or under a subdir).

1. Find the config files: `git ls-files '.rubocop.yml' '**/.rubocop.yml'`. Each directory containing one is a candidate project root.
2. If none are tracked, fall back to the directory containing the nearest `Gemfile` that lists `rubocop`.
3. If neither exists and `bundle exec rubocop --version` / `rubocop --version` both fail, RuboCop isn't set up here — say so and stop.

For each project root, decide the invocation once:
- If its `Gemfile`/`Gemfile.lock` includes `rubocop` → use `bundle exec rubocop` from that directory.
- Otherwise → use a plain `rubocop` (global/standalone).

The rest of this skill writes `<rubocop>` for the chosen invocation and `<approot>` for the directory you run it from.

---

## Stage 2 — Determine the changed files

1. Detect the base branch:
   - `gh pr view --json baseRefName --jq '.baseRefName' 2>/dev/null` if a PR exists.
   - Else the repo default branch: `git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null` (strip the `origin/`).
   - Else fall back to `main`.
2. List changed Ruby files (added/modified, not deleted):
   ```
   git diff <base>...HEAD --name-only --diff-filter=d -- '*.rb' '*.rake' 'Gemfile' '*.gemspec'
   ```
3. Drop generated / config-excluded files — most importantly `db/schema.rb` and `db/structure.sql`. Don't hand-fix generated files.
4. **Group the remaining files by project root** (Stage 1). A single branch can touch Ruby under multiple roots in a monorepo; each root is linted with its own config and invocation, from its own directory. Pass each root paths relative to that root.
5. If no lintable Ruby files changed, report that and stop.

---

## Stage 3 — Capture the changed line ranges (scope guard)

This step keeps the diff tight. RuboCop reports **every** offense in a file you pass it — including pre-existing ones on lines your branch never touched. Fixing those expands the PR's scope and can mask someone else's intentional choice.

For each changed file, get the line ranges the branch actually modified:
```
git diff <base>...HEAD -U0 -- <file>
```
Read the `@@ -old +new @@` hunk headers — the `+` ranges are the lines you own. You'll use these in Stage 5 to decide what to fix vs. what to leave.

### Edge case: Metrics offenses on method-definition lines

`Metrics/MethodLength` and `Metrics/AbcSize` report on the `def` line of the method. If the branch added lines *inside* the method (pushing it over the threshold) but didn't touch the `def` line itself, the offense is still **in scope** — the branch caused it. Treat any Metrics offense on a method where the branch added lines to the method body as in-scope.

---

## Stage 4 — Run RuboCop on the changed files

For each project root, from `<approot>`:
```
<rubocop> --force-exclusion --format clang <file1> <file2> ...
```

- `--force-exclusion` makes RuboCop honor the config's `Exclude:` even when files are passed explicitly (so excluded/generated files are skipped).
- `--format clang` gives compact `path:line:col: severity: Cop: message` lines that map cleanly to your hunk ranges.

If a root has zero offenses, move on. If every root is clean, report that and stop.

---

## Stage 5 — Fix the offenses, in scope, by hand

For each offense:

1. **Decide if it's in scope.** Compare the offense line against the Stage 3 `+` ranges for that file.
   - **On a line the branch touched** → fix it.
   - **On an untouched line (pre-existing)** → leave it. Collect these into a "pre-existing, out of scope" list for the final summary. Don't fix them unless the user explicitly asks to clean the whole file.
2. **Read the surrounding code** before editing — understand intent, not just the cop.
3. **Fix manually with the Edit tool.** Prefer the smallest change that resolves the offense and reads like the surrounding code.

### Why manual, not `rubocop -A`

Do **not** run `--autocorrect-all` / `-A`. It rewrites every offense in the file — including the out-of-scope pre-existing ones — and some "safe" corrections still change behavior subtly. Manual edits keep you in scope and let you catch semantic shifts.

**Exception (gated):** for a large pile of purely-mechanical layout offenses (`Layout/*`, trailing whitespace, indentation) you may offer to run `<rubocop> -a <files>` (safe autocorrect only, `-a` not `-A`) — but only after telling the user, and afterward run `git diff` and confirm every changed line is one your branch already owned. If `-a` touched a pre-existing line, revert that hunk.

**When to skip Claude Code entirely:** If RuboCop reports only Layout cops (all `[Correctable]`) plus at most 1-2 simple Metrics offenses, fix directly with `rubocop -a` + manual method extraction rather than delegating to Claude Code. Claude Code adds 2+ minutes of startup overhead and burns API credits — overkill for mechanical fixes. Reserve Claude Code delegation for complex Lint/Style offenses that require understanding business logic.

### Cops that need a human eye (autocorrect can change behavior)

- `Custom/RailsEnv` (RX-specific) — flags `Rails.env == 'test'` or `Rails.env.production?` guards. The fix is NOT to disable the cop — it's to replace environment branching with behavior-driven logic (e.g. checking whether data exists rather than what env you're in). Common pattern: replace `unless Rails.env == 'test'` with a presence/emptiness check on the relevant data (e.g. `if token.permitted_subdomains.any?`). Also remove any corresponding `allow(Rails).to receive(:env)` stubs from specs — they become unnecessary when the code no longer branches on env.
- `Style/SafeNavigation` — `&.` is not always equivalent to a guarded `.`; check the nil semantics.
- `Style/RedundantReturn` / `Style/RedundantSelf` — usually fine, but read the method.
- `Lint/*` — these flag real bugs (unused vars, shadowed args, unreachable code). Fix the *logic*, don't just silence.
  - **Exception: Interface compliance (`Lint/UnusedMethodArgument`)** — when implementing a required interface (e.g., OpenTelemetry exporter, ActiveJob adapter, Rails engine hook) where the method signature is dictated by the contract but your implementation doesn't use all params, an inline `# rubocop:disable Lint/UnusedMethodArgument` is the correct fix. The param must stay in the signature for interface compliance; prefixing with `_` would work too but the disable is clearer about *why* it's unused. No justifying comment beyond the cop name is needed since the interface context is self-documenting.
- `Style/FrozenStringLiteralComment` — add the magic comment; make sure no string in the file is later mutated.
- `Custom/RailsEnv` — RX has a custom cop forbidding `Rails.env` checks. Replace with feature flags, class attributes, or presence-based logic. Common pattern: replace `unless Rails.env == 'test'` with a presence guard on the relevant data (e.g. `if collection.present?`), which is semantically better and removes the env coupling. Update specs to remove any `allow(Rails).to receive(:env)` stubs — they become unnecessary.

### Metrics offenses → refactor, never relax

`Metrics/MethodLength`, `Metrics/AbcSize`, `Metrics/ClassLength`, etc. are fixed by **extracting helper methods / decomposing**, not by bumping the cop's `Max`. If the repo defines team style rules (e.g. RX's Sacred Taste `ST-01` "methods under 15 lines", or a STYLE doc), follow them. If a method genuinely can't be split (e.g. a flat `case`), that's the rare case for a justified inline disable — see below.

---

## Stage 6 — Don't game the linter

These are violations of intent even when they make RuboCop green:

- **Never edit `.rubocop.yml`** to disable a cop or raise a limit so an offense disappears.
- **Never add entries to `.rubocop_todo.yml`** to defer your own new offenses. The TODO file is for legacy debt; new code should not add to it. (Regenerating it with `--regenerate-todo` is a config change — out of scope for this skill.)
- **Inline `# rubocop:disable Cop` only with a justifying comment**, and only when the offense is a false positive or a deliberate, defensible choice — not as a shortcut. Always pair with `# rubocop:enable` to scope it tightly.
  ```ruby
  # rubocop:disable Rails/SkipsModelValidations -- bulk backfill, validations run in the model spec
  Quote.where(...).update_all(status: 'accepted')
  # rubocop:enable Rails/SkipsModelValidations
  ```

If a cop seems genuinely wrong for the whole project, surface it to the user as a config discussion — don't decide it unilaterally inside a fix.

---

## Stage 7 — Verify

Re-run RuboCop on the same files, per project root:
```
<rubocop> --force-exclusion <file1> <file2> ...
```
The only offenses allowed to remain are the **pre-existing, out-of-scope** ones you deliberately left in Stage 5. If any offense on a line your branch touched remains, fix it and re-verify. Loop until in-scope offenses are zero across all roots.

> Note: RuboCop only lints Ruby. It does not cover `.haml`/`.erb` views (that's `erb_lint`/`haml-lint`, if configured) or JS/CSS. If the user's "linting" complaint is about those, say so — it's outside this skill.

---

## Stage 8 — Finish

1. **Summary** — a short table: file, line, cop, what changed.
2. **Out-of-scope list** — any pre-existing offenses left untouched, so the user can decide separately.
3. **One-line commit message** for the work, e.g. `Fix RuboCop offenses in supplier approval service`.

Do **not** commit, stage, or push — leave git workflow to the user unless they explicitly ask.

---

## Batch / Cron Mode — Fixing PRs automatically

When running as an automated cron job scanning multiple PRs (e.g. hourly rubocop fixer):

1. **Identify failing PRs**: Use `gh pr list --repo <org/repo> --state open --json number,headRefName,statusCheckRollup,author` and filter for checks named `rubocop` (or `lint`) with `conclusion: "FAILURE"`.
2. **Use git worktrees** to check out each branch without disturbing the main checkout:
   ```
   git fetch origin <branch> <base>
   git worktree add /tmp/<repo>-<pr_number> origin/<branch>
   cd /tmp/<repo>-<pr_number>
   git checkout -b <branch> origin/<branch>
   ```
3. **Run Stages 1–7** normally within the worktree.
4. **Commit and push**: In batch mode, commit with a clear message and co-author the PR author:
   ```
   git commit -m "Fix RuboCop offenses in <description>" \
     --author="BigMac <57731843+scientist-service@users.noreply.github.com>" \
     --trailer="Co-authored-by: Author Name <author@users.noreply.github.com>"
   git push origin <branch>
   ```
5. **Clean up worktree**: `git worktree remove /tmp/<repo>-<pr_number>`

### Pitfalls in batch mode

- **Commit already applied on remote**: After rebasing, git may report "skipped previously applied commit" — this means another actor (or a previous webhook run) already pushed the same fix. Verify rubocop is clean and skip the push; report as "already fixed" rather than erroring.
- **Checks still IN_PROGRESS**: Skip PRs where the rubocop check hasn't completed yet (`status: "IN_PROGRESS"`). Re-check on the next run.
- **Empty statusCheckRollup**: Some PRs show no checks at all (CI not triggered). These can't be identified as failing — skip them unless the user explicitly asks to lint them.
- **Stale FAILURE after fix already pushed**: When prior automation (or a human) already pushed a rubocop fix, the `statusCheckRollup` still shows `conclusion: "FAILURE"` until CI re-runs on the new commit. This is the *most common* outcome in batch mode when automation is active. After checkout, always run rubocop locally on the changed files BEFORE attempting fixes. If zero in-scope offenses remain, log "already resolved" and move on — don't waste time or create empty commits.
- **rbenv PATH**: Always `export PATH="$HOME/.rbenv/shims:$PATH"` before running bundle/rubocop in worktrees, since worktrees don't inherit shell init.
- **`--format json` can timeout on large projects**: RuboCop's JSON formatter is significantly slower than `--format clang`. In RX specifically, `--format json` on even 10 files can exceed 90s. Use `--format clang` and parse the output textually. If you need structured data, run clang format and parse `path:line:col: severity: Cop: message` lines.
- **Safe autocorrect (`-a`) for Layout cops is fine**: When all offenses are `Layout/*` (indentation, alignment, end-alignment), running `rubocop -a` is safe and dramatically faster than manual edits. Only avoid `-A` (unsafe autocorrect). After `-a`, re-run to catch any remaining non-correctable offenses (like `Metrics/*`).
- **Metrics offenses after autocorrect**: `rubocop -a` won't fix `Metrics/AbcSize` or `Metrics/BlockLength`. These need manual extraction of helper methods. Check the ABC score — if it's only slightly over (e.g., 35.86/35), extracting one inner loop into a method usually resolves it.

---

## Webhook-Triggered Mode — Fixing CI Failures in Real Time

When triggered by a GitHub `check_run` webhook (rubocop CI failure), the flow is simpler than batch mode because you already know the exact branch and repo:

1. **Validate the event**: Only act on `conclusion: "failure"` + check name containing "rubocop" (case-insensitive). Log skips to `~/webhook-logs/rubocop-webhook-skips.log`.
2. **Checkout the branch**: `git fetch origin && git checkout -B <branch> origin/<branch>` (use `-B` to force-reset to remote HEAD; avoids divergence issues from prior local commits or force-pushes on the branch)
3. **Identify changed files**: `git diff origin/main...HEAD --name-only --diff-filter=d -- '*.rb' '*.rake'`
4. **Run RuboCop on changed files only** (in batches if needed — clang format, not JSON). **If rubocop reports 0 offenses, STOP — the fix was already pushed** (race condition with another actor or a prior webhook run). Report "already resolved" and skip all remaining steps.
5. **Fix**: Use `-a` for Layout cops, then manually fix remaining Metrics/Lint offenses.
6. **Verify**: Re-run RuboCop on the same files — must show 0 offenses.
7. **Commit and push**: Use message `"fix: auto-fix rubocop violations [ci skip-hierarchical]"` to avoid infinite CI loops.

**Key difference from batch/cron mode**: No worktree needed (you're operating on the branch directly), no PR author lookup needed for co-authoring (this is a service fix), and the `[ci skip-hierarchical]` trailer prevents the rubocop fix from re-triggering downstream checks.

### Pitfalls in webhook mode

- **`git stash` before branch switch**: If the working tree has uncommitted changes from a prior run (e.g. a previous rubocop fix attempt on a different branch), `git checkout -B` will refuse. Run `git stash` first, then `git checkout -B <branch> origin/<branch>`.
- **`git pull` on diverged branches fails**: When the local branch has prior commits that differ from remote (e.g. force-push happened), `git pull` will refuse. Always use `git checkout -B <branch> origin/<branch>` instead of `git checkout <branch> && git pull` — this unconditionally resets to remote HEAD.
- **Race condition: fix already pushed**: Between webhook delivery and your fix attempt, another actor (human or prior automation run) may push the same fix. After `git checkout -B <branch> origin/<branch>`, always re-run rubocop on the changed files BEFORE attempting any fix. If it's already clean, report "already resolved" and skip commit/push. Don't waste time trying to autocorrect files that have no offenses.
- **Wrong branch context after checkout**: When switching branches in a monorepo, verify `git branch --show-current` matches your target before committing. If rubocop `-a` ran while on the wrong branch (e.g. a previously checked-out branch), those changes land in the wrong place. Always confirm branch identity immediately before `git add`/`git commit`.
- **CI log not yet available via `gh run view`**: When a `check_run` webhook fires with `conclusion: failure`, the run may still be marked "in progress" by the time you query it (race between webhook delivery and log finalization). If `gh run view --log-failed` returns "still in progress", try the direct job log API instead: `gh api repos/<org>/<repo>/actions/jobs/<job_id>/logs` — this often works even when the parent run is still "in progress" because the specific job has completed. Parse the output with `grep -E "(offense|\.rb:.*[CWE]:)"`. If neither log source works, run rubocop locally on the branch's changed files — the local output is authoritative since CI uses the same config.
- **Monorepo path confusion**: In the RX monorepo, `git diff` paths include the `rx/` prefix (e.g. `rx/app/controllers/...`) because git operates from the monorepo root (`~/src/rx`). But rubocop must run from the Rails root (`~/src/rx/rx`) with paths relative to *that* directory (e.g. `app/controllers/...`). Strip the `rx/` prefix when passing files to `bundle exec rubocop`. Similarly, `git add` must use monorepo-relative paths (with the `rx/` prefix) when run from `~/src/rx`.
- **Bundle install before rubocop**: On long-lived branches or after switching branches, `bundle exec rubocop` may fail with `Could not find <gem> in locally installed gems`. Run `bundle install` first. Budget ~30s for this in automation timeouts.
- **CI reports offenses not reproduced locally**: CI uses `reviewdog` with `filter_mode: added` — it only reports offenses on *newly added lines*. Local `rubocop` reports ALL offenses in the file. When CI reports a cop (like `Style/EndlessMethod`) that local rubocop doesn't flag, check if the local rubocop version/config differs from CI's. If local rubocop shows 0 offenses on that file, trust local — the CI-only offense may be a reviewdog false positive or version mismatch.
- **Custom/RailsEnv fix strategy**: When fixing `Custom/RailsEnv`, prefer a semantic/data-driven guard over introducing `class_attribute` test toggles. E.g., `unless Rails.env == 'test'` around a subdomain check → `if token.permitted_subdomains.present?`. This approach: (1) satisfies the cop, (2) makes tests pass without env stubs, (3) improves the design by making behavior depend on data state, not deployment environment. Always check the corresponding spec for `allow(Rails).to receive(:env)` stubs that become dead code after the fix.
- **Safe autocorrect is sufficient for Layout cops**: When all offenses are `Layout/*` (all marked `[Correctable]`), `rubocop -a` is safe and fast — no need to delegate to Claude Code. Reserve Claude Code for complex Lint/Style/Metrics offenses.
- **Unresolved merge conflict markers (`Lint/Syntax`)**: If rubocop reports `Lint/Syntax: unexpected token tLSHFT` with `<<<<<<<` in the output, the file contains unresolved merge conflict markers. This is NOT an auto-fixable offense — it requires the PR author to resolve the conflict and choose between implementations. Report it and stop; do not attempt to pick a side.
- **Check status is IN_PROGRESS**: When the initial batch scan found the PR via `conclusion: "FAILURE"` but by the time you check it's `IN_PROGRESS` (e.g. a new push happened between scan and checkout), the old failure is stale. Still run rubocop locally — if there are only non-fixable issues (merge conflicts, pre-existing offenses), report and move on rather than wasting time waiting for CI to re-conclude.
- **Stale local commits from prior fix attempts**: After `git fetch`, the local branch may have extra "rubocop" commits from a previous automated run that diverged from the remote (e.g. the author force-pushed). `git checkout -B <branch> origin/<branch>` handles this by resetting to remote HEAD, but verify with `git rev-parse HEAD` vs `git rev-parse origin/<branch>` that they match before proceeding.
- **`[Errno 24] Too many open files` in batch mode**: When processing multiple PRs via worktrees in rapid succession, the terminal tool may hit OS file descriptor limits. If a command fails with this error, simply retry — it's transient. If persistent, clean up worktrees between PRs (`git worktree remove`) before creating the next one.
- **Repo org discovery**: Always derive the org/repo from `git remote -v` in the checkout rather than guessing. RX is `scientist-hq/rx`, not `scientist-inc/rx`. Use: `git remote get-url origin | sed 's|.*github.com[:/]||;s|\.git$||'` to extract `org/repo`.
- **No webhook payload available (skill load failure)**: If the triggering webhook payload isn't accessible (e.g. the delegating skill failed to load), fall back to scanning open PRs for rubocop failures: `gh pr list --repo <org/repo> --state open --json number,headRefName,statusCheckRollup | jq ...`. If zero failures are found, log to `~/webhook-logs/rubocop-webhook-skips.log` and exit cleanly — this is the expected race-condition outcome (fix already pushed between webhook fire and agent execution).
- **Check workflow naming varies by repo**: RuboCop may run as a standalone workflow named "rubocop" or as a job inside "Analysis", "Specs", "Lint", etc. When scanning for failures, check both `workflowName` and individual check names in `statusCheckRollup`. Use case-insensitive matching: `test("rubocop|lint|analysis";"i")`.

### Planned: Kanban-Producer Preflight Script (PR #20)

The webhook-triggered mode is being migrated to a **preflight script + kanban** architecture:

1. Webhook agent runs `rubocop-preflight.rb` (at `skills/fix-rubocop/scripts/rubocop-preflight.rb`)
2. Script handles all deterministic logic (gates, git, rubocop, line-scoping)
3. If work needed: script calls `hermes kanban create` with pre-digested JSON + idempotency key
4. Dispatcher spawns a worker agent with `fix-rubocop` + `claude-code` skills loaded
5. Worker reads JSON body, fixes offenses, commits, pushes, notifies Slack

Benefits over current approach: automatic retry on crash, dedup via idempotency key (no duplicate work from rapid-fire webhooks), full audit trail in kanban SQLite, human intervention via `kanban block`.

The webhook prompt shrinks to ~10 lines: "run script, stop."

See `references/webhook-preflight-plan.md` for the full plan, decisions, and target architecture.

**Note:** There is NO filter proxy in use. The file at `~/webhook-logs/filter-proxy.rb` is dead code from an abandoned approach. The current flow is: GitHub → Tailscale Funnel (port 8644) → Hermes webhook → Agent.

See also: `references/batch-pr-workflow.md`, `references/webhook-preflight-plan.md`
