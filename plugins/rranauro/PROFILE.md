# Dev-suite profile

These commands were written for one developer on one Rails monorepo. The
profile is what makes them work for anyone, anywhere. Every command reads it
before it does anything project-specific.

## Resolution order

First hit wins, per key:

1. `<project>/.claude/dev-suite.json` — the repo you're working in
2. `~/.claude/dev-suite.json` — your defaults across projects
3. The built-in defaults below

Copy `dev-suite.example.json` to either location and edit. Keys are merged, not
replaced wholesale: a project file that sets only `repo.slug` still inherits
your user-level `commands.test`.

## Keys

| Key | Default | What it's for |
|-----|---------|---------------|
| `identity.gh_user` | *(auto)* | Your GitHub login, used to tell your own PRs from a colleague's. Leave `null` to detect it at runtime via `gh api user -q .login` — that's correct for everyone and needs no config. |
| `repo.slug` | *(auto)* | `owner/name`. Leave unset to infer via `gh repo view`. |
| `repo.workspace_root` | *(git toplevel)* | The main checkout that holds sibling worktrees. Artifacts (reviews, plans) are written here so they survive worktree teardown — if you use worktrees, set this explicitly, or the fallback resolves to whichever worktree is current. |
| `repo.app_subdir` | `""` | Subdirectory holding the app, for monorepos where the framework root isn't the git root. `""` means the repo root is the app root. |
| `repo.worktree_prefix` | *(repo name)* | Prefix for worktree directory names — `<prefix>-<issue>-<slug>`. |
| `repo.default_branch` | *(remote HEAD)* | Base branch for PRs and diffs. |
| `paths.plans` | `"plans"` | Where plan files go, relative to `app_subdir`. |
| `paths.reviews` | `"tmp/reviews"` | Where review artifacts go, relative to `app_subdir`. |
| `commands.serve` | *(none)* | Command that boots the app for in-browser checks. Omit and the commands skip in-app verification steps rather than guessing. |
| `commands.worktree_init` | *(none)* | Hook run after creating a worktree (deps install, env linking). Omit to skip. |
| `commands.test` | *(none)* | Test runner, e.g. `bundle exec rspec`, `pnpm test`. |
| `commands.lint` | *(none)* | Linter, e.g. `bundle exec rubocop`, `pnpm lint`. |
| `commands.commit` | *(none)* | A slash command to delegate committing to, e.g. `/rx:commit`. Omit and the suite commits directly with `git`. |
| `commands.pr` | *(none)* | A slash command to delegate PR creation to, e.g. `/rx:pr`. Omit and the suite uses `gh pr create`. |

## Placeholder convention

Command files write profile values as `{{key.path}}` — `{{repo.workspace_root}}`,
`{{commands.test}}`. Substitute them before running anything; never echo a raw
`{{…}}` to the user or into a shell. A placeholder whose key resolves to nothing
means that step isn't configured: skip it and say why.

## Rules for commands reading this

- **Read the profile once, at the start.** Don't re-read per step.
- **Prefer detection over configuration.** Anything `gh` or `git` can answer at
  runtime — your login, the repo slug, the default branch — should be detected,
  with the profile as an override for the unusual case. Every key you can
  auto-derive is one a new user doesn't have to set before the suite works.
- **A missing optional command means skip the step, not guess it.** If
  `commands.test` is unset, say "no test command configured — skipping" rather
  than trying `bundle exec rspec` on a project that may not be Ruby.
- **Never write a project's real values back into the plugin.** The plugin ships
  `dev-suite.example.json` only; live profiles live in the project or the home
  directory.

## Rules for scripts reading this

Scripts parse it with the `python3` already required elsewhere in the suite.
Resolution is the same three-tier order, and the same detect-first principle:
`pr-review.sh` resolves the current GitHub user from `gh api user` and only
consults `identity.gh_user` as an override.

**An absent profile is the normal case, not an error.** The `pr-review-on-create`
hook ships with the plugin and fires in every repo you open a PR from, so
`pr-review.sh` routinely runs in projects that have no `dev-suite.json` at all.
It must fall through to detection and the built-in defaults without complaint —
never prompt, never fail, never write a profile on the user's behalf.
