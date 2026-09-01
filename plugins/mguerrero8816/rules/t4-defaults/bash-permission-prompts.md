# Avoiding Bash Permission Prompts

Claude Code statically analyzes every Bash command before matching it against the allowlist. Anything it can't clear is kicked to a manual approval prompt — and in a subagent that prompt bubbles all the way up to the user, stalling the agent. One unapprovable sub-command poisons the whole compound: a single bad piece in an otherwise-harmless `echo … ; grep … ; …` chain forces approval on the entire command. The sections below are the recurring triggers and how to avoid each.

## Prefer the Grep/Read Tools for Code Inspection — Not Shell

For read-only inspection — searching for a symbol, reading a file, extracting a range of lines — use the dedicated **Grep** and **Read** tools, never `grep`/`awk`/`sed`/`find -exec` in Bash. They never prompt, and they hand you results between calls so you never need a shell variable to carry a path from one step to the next. Most of the triggers below only arise because a command shelled out for work these tools do cleanly.

- ❌ BAD: `grep -n "def foo" file.rb; awk '/def foo/,/^  end/' file.rb`
- ❌ BAD: `f=$(grep -rl "class Foo" app/); grep -n "def bar" "$f"`
- ✅ GOOD: Grep for `def foo` (`output_mode: "content"`, `-n: true`), then Read that file at the matched line range.
- ✅ GOOD: Grep for `class Foo` (`output_mode: "files_with_matches"`), then a second Grep with `path` set to the returned file.

## Run App Commands Directly — Never `cd` First

The session (and every subagent) already starts in `/Users/mike/rx/rx`, where the Rails app lives. Run `bundle exec` / `rails` / `rake` / `rspec` directly with no path prefix — assume the CWD is correct.

Never wrap a command in a directory-change guard — `cd /path && cmd`, `env -C /path cmd`, or a redirected fallback like `cd /path 2>/dev/null || cd /other`. Each triggers a prompt: `cd &&` / `||` for chaining, `env -C` and redirected forms because the working directory can't be statically analyzed (flagged "path resolution bypass"). This fires on *every* call regardless of the actual command.

- ❌ BAD: `cd /Users/mike/rx/rx && bundle exec rspec spec/foo_spec.rb`
- ❌ BAD: `cd /Users/mike/rx/rx 2>/dev/null || cd /Users/mike/rx` then `bundle exec rails runner '...'`
- ❌ BAD: `env -C /Users/mike/rx/rx bundle exec rails runner '...'`
- ✅ GOOD: `bundle exec rspec spec/foo_spec.rb`

If the CWD genuinely is not `/Users/mike/rx/rx`, stop and tell the user rather than adding a `cd` guard. For **git** commands in another directory, `git -C /path` is fine.

## Unapprovable Binaries — `awk`, `sed`, `xargs`, `find -exec`

`awk`, `sed`, `xargs`, and `find -exec` all run arbitrary commands or code (`system(...)`, file writes, a command per input line), so they can't be auto-approved and always prompt. For anything you'd reach for these for, use the Grep/Read tools instead (see above).

## Command Substitution and Shell Variables

Command substitution (`$(...)`, backticks) and runtime variable expansion (`"$f"`) mean the analyzer can't tell what a command will actually read or run, so it prompts even when every binary is otherwise allowed — **an allowlist entry for the outer command does not save it**. Don't chain shell steps through a captured variable — let the Grep/Read tools carry the result between calls, or split into two Bash calls and paste the first result into the second.

- ❌ BAD: `f=$(grep -rl "class Foo" app/); grep -n "def bar" "$f"`

### Never Substitute a Discovered Value Into a Command — Two Calls Instead

**Any time a command needs a value you don't know yet, that's two Bash calls, not one.** Call 1 discovers the value (`git diff --name-only`, `git ls-tree`, `gh pr view --json`, or a Grep). Read it out of the tool result. Call 2 writes it in literally. Paths from git are repo-root-relative and the CWD is `rx/`, so drop the leading `rx/` when you write them.

This is the single most common prompt trigger, and it recurs because the one-liner *feels* like one step. It isn't — every `$(...)` poisons the whole command.

**This is not only about file paths.** Commit SHAs, PR/issue numbers, record IDs, branch names, URL path segments — any of them substituted from a subshell trips `command_substitution` just the same. A `$(...)` buried inside an API URL is the easiest one to miss, because the command reads as a single lookup rather than two chained steps.

- ❌ BAD: `gh api /repos/scientist-hq/rx/commits/$(gh pr view 39617 --repo scientist-hq/rx --json headRefOid --jq .headRefOid)/check-runs --jq '...'`
- ✅ GOOD: call 1 — `gh pr view 39617 --repo scientist-hq/rx --json headRefOid --jq .headRefOid`, then call 2 — `gh api /repos/scientist-hq/rx/commits/a1b2c3d4/check-runs --jq '...'`
- ✅ BETTER: `gh pr checks 39617 --repo scientist-hq/rx` — one call, no SHA needed at all

**Look for a higher-level command before reaching for substitution.** Needing a subshell to feed a lower-level API is often a sign the tool already exposes what's wanted directly — `gh pr checks` instead of resolving a head SHA and hitting `/check-runs` by hand.

### Never Echo Exit Codes — the Tool Result Already Has Them

`$?`, `${PIPESTATUS[0]}`, and every other `${...}` form are parameter expansion and prompt as `expansion`, even bolted onto a command that would otherwise pass clean.

They are also redundant. The Bash tool reports exit status and stderr back automatically, and a failing command's own error text is usually more informative than its exit code. Appending status introspection reimplements what the harness already provides — and converts a silent call into an approval prompt to do it.

- ❌ BAD: `gh issue view 39476 --repo scientist-hq/rx 2>&1 | head -4; echo "exit=${PIPESTATUS[0]}"`
- ✅ GOOD: `gh issue view 39476 --repo scientist-hq/rx` — success or failure is already visible in the result

The same applies to probing whether something exists by checking a status code. Run the real command and read what comes back.

Reading a file on another branch (`git show <branch>:<path>`), linting changed files, running the changed specs: all the same shape.

- ❌ BAD: `git show my-branch:rx/db/migrate/$(git diff --name-only main...my-branch -- rx/db/migrate | head -1 | xargs basename) 2>/dev/null || git diff main...my-branch -- rx/db/migrate`
- ✅ GOOD: call 1 — `git diff --name-only main...my-branch -- rx/db/migrate`, then call 2 — `git show my-branch:rx/db/migrate/20260714000000_add_group_to_milestones.rb`
- ❌ BAD: `bundle exec rubocop --force-exclusion $(git diff --name-only main...HEAD --diff-filter=d | grep '\.rb$' | sed 's|^rx/||') 2>&1 | grep -B2 -A3 "^[A-Za-z].*\.rb:" | head -40`
- ✅ GOOD: call 1 — `git diff --name-only --diff-filter=d main...HEAD`, then call 2 — `bundle exec rubocop --force-exclusion --format simple app/models/foo.rb spec/models/foo_spec.rb`

Two more triggers visible in that first example, both avoidable:

- **`xargs` is unapprovable** — it executes an arbitrary command per input line, same category as `awk`/`sed`. There is never a reason to reach for `xargs basename`: you already have the path in the tool result, so just write the basename.
- **Don't pre-build a `|| fallback`.** A speculative `cmd 2>/dev/null || other-cmd` forces approval on the compound even when both halves are individually fine. Run the first command, look at the result, and run the fallback only if you actually need it.

Use the tool's own flags for scoping and output rather than post-filtering through `grep`/`sed`/`head` — e.g. rubocop's `--format simple` (or `--format offenses` for counts alone) is already terse, and `--force-exclusion` keeps excluded files quiet when they're passed explicitly.

### Never Write a `for` Loop — Fan Out Into Separate Calls

**When the same command has to run over a list of known values — PR numbers, issue numbers, filenames, branches — write one Bash call per value with the value spelled out literally. Never `for x in …; do cmd $x; done`.**

A loop variable is runtime expansion, so it prompts (flagged "simple_expansion") no matter how ordinary the body is — `gh pr checks` being allowlisted does not save `gh pr checks $n`. The loop buys nothing here: the values were already known when the command was written, so the only thing the loop compressed was typing, and it cost an approval prompt to do it. Independent calls also run in parallel and arrive as separate, individually readable results instead of one blob needing `echo "=== #$n"` separators to stay legible.

This is the same trap as path substitution, in a shape that doesn't look like it: because the list is hardcoded, the command *feels* fully specified. The analyzer still can't see through `$n`.

- ❌ BAD: `for n in 39731 39379 39369 39192; do echo "=== #$n"; gh pr checks $n --repo scientist-hq/rx; done`
- ✅ GOOD: four parallel Bash calls — `gh pr checks 39731 --repo scientist-hq/rx`, `gh pr checks 39379 --repo scientist-hq/rx`, …
- ❌ BAD: `for n in 37838 39365; do t=$(gh api "/repos/scientist-hq/rx/issues/$n" --jq '...'); echo "#$n -> $t"; done`
- ✅ GOOD: one call per number — `gh api /repos/scientist-hq/rx/issues/37838 --jq 'if .pull_request then "PULL REQUEST" else "issue" end'`

If the list is long enough that one-call-per-item is genuinely unreasonable, reach for a `rails runner` one-liner — **not** a shell script, which prompts on its own (see below).

## Scripts Always Prompt — Fold the Cases In and Run Once

Invoking a script by path (`./foo.sh`, `bash foo.sh`, `/tmp/.../foo.sh arg`) always requires approval. The analyzer can't read the file, so it has no idea what will run — the contents being harmless is irrelevant, and there is no allowlist entry that generalizes.

Writing a script is therefore not an escape hatch from the loop rule. It trades one prompt shape for another, and the script version is worse when it's invoked repeatedly.

**Two rules when a script is genuinely warranted:**

- **Put every case inside the script and invoke it exactly once, with no arguments.** One approval covers the whole run. Calling the same script once per input is the same mistake as the `for` loop — N inputs, N prompts — with the added cost of a file on disk.
- **Never leave a reusable script in the session scratchpad.** That path embeds the session UUID (`…/claude-501/-Users-mike-rx-rx/<uuid>/scratchpad/…`), so it is different every session and "don't ask again" expires with the session. A script worth running twice belongs somewhere stable that can be allowlisted once.

- ❌ BAD: `verify_issue_check.sh 39741 "body A"`, then `verify_issue_check.sh 39741 "body B"`, then `… "body C"` — three prompts
- ✅ GOOD: script holds all three bodies and prints a labeled result per case; invoke it once — one prompt
- ✅ BETTER, when the logic is small: skip the script and run the underlying commands directly, unrolled, since those are individually allowlistable

Before writing a script at all, check whether the body is just a couple of allowlisted commands. If so, inline them — a script that wraps two `gh` calls has strictly more friction than the two `gh` calls.

### A Prior Approval Never Covers the Next Script

"Yes, and don't ask again" pins to the **exact path and arguments** that were on screen. A new filename, or the same script with a different argument, matches nothing and prompts again. So a habit of writing one throwaway script per test case guarantees a prompt per case no matter how many times the user has already approved — which reads to them as the approval being ignored, and is the fastest way to burn their patience.

If a second script is about to be written for the same investigation, that is the signal to stop and fold both into one script that runs every case in a single invocation.

- ❌ BAD: approve `verify_issue_check.sh 39741`, then write and run `check_real_pr.sh 39617` — a brand-new prompt
- ✅ GOOD: one script, all cases inside, invoked once with no arguments

Also never chain `chmod +x` onto the invocation. `chmod +x foo.sh; ./foo.sh` is two unapprovable pieces in one compound. Invoke the interpreter directly instead — `bash foo.sh` needs no executable bit — or set the mode with the Write tool's file, not a shell call.

## Keep Each Command on One Line

Newlines inside a single Bash call trigger a prompt. Chain sequential commands with `&&` (stop on failure) or `;` (continue regardless); for independent commands, make parallel Bash tool calls. Inside a quoted `rails runner` script, separate Ruby statements with `;`, not newlines.

- ❌ BAD: `cd rx`⏎`bundle exec rspec spec/foo_spec.rb`
- ✅ GOOD: `bundle exec rails runner 'u = Pg::User.find_by(email: "michael@scientist.com"); puts u.uuid'`

**This is not licence to chain unrelated commands** — see below. Chaining is for steps that are genuinely sequential *and* individually approvable.

## Never Weld Unrelated Commands Into One Call

A compound is only as approvable as its least approvable piece, so bundling an unrelated command into an otherwise-clean call converts a silent success into a prompt. Two commands belong in one call only when the second genuinely depends on the first. If they'd make sense in either order, they are independent — issue them as parallel Bash calls so the clean one runs unblocked and only the risky one can prompt.

- ❌ BAD: `ls /opt/homebrew/bin/bash /usr/local/bin/bash 2>/dev/null; gh api /repos/scientist-hq/rx/issues/39670 --jq '...'` — an environment probe and an API lookup, unrelated; the `ls` into `/opt/homebrew/bin` prompts and takes the `gh api` down with it
- ✅ GOOD: one Bash call for the `gh api`, and a separate call for the probe if it's needed at all

**Don't probe for binaries or paths speculatively.** `ls`-ing candidate install locations reads outside the project and prompts. Run the real command and read the error if it isn't there; a `2>/dev/null` on a probe is the same speculative-fallback smell as `cmd || other-cmd`.

This matters most in subagents, where the prompt bubbles up to the user and stalls the agent mid-run — a subagent should be especially conservative about what it bundles into one call.

## No `#` Comments Inside Quoted Strings

A newline followed by `#` inside a quoted argument is flagged ("can hide arguments from path validation"). Use `puts` for anything you'd want a comment for — it's readable and passes validation.

- ❌ BAD: `bundle exec rails runner "# find the user\nu = Pg::User.find_by(...)"`
- ✅ GOOD: `bundle exec rails runner 'puts "find the user"; u = Pg::User.find_by(email: "michael@scientist.com")'`
