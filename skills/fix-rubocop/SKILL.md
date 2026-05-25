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

### Cops that need a human eye (autocorrect can change behavior)

- `Style/SafeNavigation` — `&.` is not always equivalent to a guarded `.`; check the nil semantics.
- `Style/RedundantReturn` / `Style/RedundantSelf` — usually fine, but read the method.
- `Lint/*` — these flag real bugs (unused vars, shadowed args, unreachable code). Fix the *logic*, don't just silence.
- `Style/FrozenStringLiteralComment` — add the magic comment; make sure no string in the file is later mutated.

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
