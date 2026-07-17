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

## Unapprovable Binaries — `awk`, `sed`, `find -exec`

`awk`, `sed`, and `find -exec` are full scripting languages that can execute code (`system(...)`, file writes), so they can't be auto-approved and always prompt. For anything you'd reach for these for, use the Grep/Read tools instead (see above).

## Command Substitution and Shell Variables

Command substitution (`$(...)`, backticks) and runtime variable expansion (`"$f"`) mean the analyzer can't tell what a command will actually read or run, so it prompts even when every binary is otherwise allowed. Don't chain shell steps through a captured variable — let the Grep/Read tools carry the result between calls.

- ❌ BAD: `f=$(grep -rl "class Foo" app/); grep -n "def bar" "$f"`

## Keep Each Command on One Line

Newlines inside a single Bash call trigger a prompt. Chain sequential commands with `&&` (stop on failure) or `;` (continue regardless); for independent commands, make parallel Bash tool calls. Inside a quoted `rails runner` script, separate Ruby statements with `;`, not newlines.

- ❌ BAD: `cd rx`⏎`bundle exec rspec spec/foo_spec.rb`
- ✅ GOOD: `bundle exec rails runner 'u = Pg::User.find_by(email: "michael@scientist.com"); puts u.uuid'`

## No `#` Comments Inside Quoted Strings

A newline followed by `#` inside a quoted argument is flagged ("can hide arguments from path validation"). Use `puts` for anything you'd want a comment for — it's readable and passes validation.

- ❌ BAD: `bundle exec rails runner "# find the user\nu = Pg::User.find_by(...)"`
- ✅ GOOD: `bundle exec rails runner 'puts "find the user"; u = Pg::User.find_by(email: "michael@scientist.com")'`
