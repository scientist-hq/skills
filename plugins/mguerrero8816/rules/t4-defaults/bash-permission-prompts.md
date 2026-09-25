# Avoiding Bash Permission Prompts

Claude Code checks each Bash command against the allowlist before it runs. If the analyzer cannot read a command, it asks for approval. One bad part of a compound command makes the whole command prompt. In a subagent, the prompt stops the agent until Mike answers.

## Use the File Tools for Inspection

Use the Read tool to read files. Use the Grep tool to search, or a plain `grep` in Bash when the Grep tool is not available. Never use `awk`, `sed`, `xargs`, or `find -exec`. They can run arbitrary code, so they always prompt.

## Forms That Always Prompt

- `cd` before a command, `env -C`, or a `cd … || cd …` guard. The session starts in `/Users/mike/rx/rx`, so run `bundle exec …` directly. For git in another directory, use `git -C /path`.
- Command substitution with `$(...)` or backticks. This includes a value inside a URL.
- Shell variables and expansion: `"$f"`, `$?`, `${PIPESTATUS[0]}`, and a `for` loop variable.
- A script that runs by path (`bash foo.sh`, `./foo.sh`), and `chmod +x`.
- A newline inside one command, or a `#` after a newline inside a quoted string.
- A speculative `cmd 2>/dev/null || other-cmd` fallback, or an `ls` probe outside the project.

## What to Do Instead

- **A value you do not know yet:** use two calls. Call 1 finds the value. Call 2 contains it as literal text. Paths from git start with `rx/`. Remove that part, because the CWD is `rx/`.
- **The same command for a list of values:** make one call per value, in parallel. For a long list, use one `rails runner` call.
- **Exit status:** do not print it. The tool result already shows it.
- **Several statements:** put them on one line. Chain with `&&` or `;` only when the second step depends on the first. Send independent commands as parallel calls.
- **Comments in a `rails runner` string:** use `puts`.
- **A higher-level command:** look for one first. `gh pr checks 39617` needs no SHA.
- **Output filters:** use the tool's own flags, such as rubocop `--format simple --force-exclusion`, instead of a pipe to `grep` or `head`.

- ❌ BAD: `bundle exec rubocop --force-exclusion $(git diff --name-only main...HEAD | grep '\.rb$')`
- ✅ GOOD: call 1 `git diff --name-only --diff-filter=d main...HEAD`, then call 2 `bundle exec rubocop --force-exclusion --format simple app/models/foo.rb`
- ❌ BAD: `for n in 39731 39379; do gh pr checks $n --repo scientist-hq/rx; done`
- ✅ GOOD: two parallel calls, `gh pr checks 39731 --repo scientist-hq/rx` and `gh pr checks 39379 --repo scientist-hq/rx`

## When a Script Is Necessary

Put every case inside the script and run it one time, with no arguments. An approval covers only the exact path and arguments, so each new script or argument prompts again. Do not keep a reusable script in the session scratchpad, because its path changes each session. Run it with `bash foo.sh`, not with `chmod +x`.
