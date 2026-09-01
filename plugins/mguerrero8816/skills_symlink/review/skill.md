---
description: Reviews a pull request — dispatches parallel security, general, and integration review subagents, plus formatting check for your own PRs.
---

## Step 1: Determine PR Ownership

Run `gh pr view [PR_NUMBER_OR_URL]` and check the author against:
- Email: `michael@scientist.com`
- Names: `Michael`, `Mike`, `Michael Gorsuch`

## Step 2: Dispatch Review Agents

Dispatch these 3 agents in parallel using the Agent tool:

1. **Security review** — prompt: `"Review PR [URL] for security and data safety issues. Invoke Skill(review-security) for your full instructions."`
2. **General review** — prompt: `"Review PR [URL] for general code quality. Invoke Skill(review-general) for your full instructions."`
3. **Integration review** — prompt: `"Review PR [URL] for integration-seam defects. Invoke Skill(review-integration) for your full instructions."`

### Scale the fleet to the diff

Three agents is the floor, not the answer for every PR. Attention thins across a large diff, and a reviewer who has read 700 lines is not reading the 701st carefully.

Run `gh pr diff [PR] --name-only` and count the files first:

| Files changed | Dispatch |
|---------------|----------|
| Up to ~8 | the 3 above |
| ~9 to ~20 | the 3 above, plus a second general reviewer scoped to a named half of the diff |
| More than ~20 | the 3 above, plus one general reviewer per coherent area — controllers/actions, views/JS, specs |

When you split by area, say so in each prompt: `"Restrict your review to <these files>."` Overlap is fine and cheap; a gap is not.

Say in the output how many agents ran and how the diff was split. A reader needs to know whether a quiet area was reviewed or merely unassigned.

Collect all results and present them grouped by agent, with a rolled-up summary table at the end sorted by severity.

**Keep the presented output at summary level.** Each finding gets a heading, one to three sentences of what's wrong, and the `file.rb:line`. Do not include reproduction steps, attack walkthroughs, or severity essays in the review output — the point of the review is a scannable list of what needs attention.

### Number the findings in one plain sequence

Findings are numbered `1, 2, 3, …` continuing across both agents' sections and into the summary table — never per-agent counters, and never a prefixed or compound label.

- ❌ BAD: `S1`, `G1`, `SEC-2`, `1a`, `S2/G3`
- ✅ GOOD: security findings are 1–6, general findings continue at 7, and the table rows reuse those same numbers

When both agents report the same issue, give it **one** number in whichever section it fits best and note the overlap in prose ("both agents reached this"). Do not list it twice under two labels. A number identifies exactly one finding, so "explain 4" is never ambiguous.

### The summary table carries the file location

Every row names where the finding lives. Columns are `#`, Finding, Location, Severity, Status — in that order.

- **Location is the basename and line only** — `build.rb:378`, never `rx/app/actions/proposals/build.rb:378`. The full path is already inline in the finding's own section above.
- **Never move the locations into a separate list under the table.** A reader scanning the rollup must not have to match numbers against a second list to find out what file a finding is in.
- Keep the Finding cell to a short noun phrase so the row still fits the terminal. The sentences belong in the finding's section, not the table.
- When a finding spans two files, name the one the fix lands in.

### Mark pre-existing findings in the rollup

A finding that predates the PR still appears, in its section and in the table, with **pre-existing** stated on it. Keep the two groups visually separate — findings the PR introduced are what the author has to act on before merge; pre-existing ones are information, and their fixes usually belong in their own PR. Verify the claim against the base branch before making it; see `review-instructions`.

## Step 3: Formatting Review (Own PRs Only)

If the PR is authored by Michael/Mike, check that it follows the PR conventions:
- Is it a draft PR?
- Does it have the correct title format?
- Does it have appropriate labels?
- Does the description follow the required sections?
- Are test instructions complete?
- Are URLs using the correct base domain?
- Is the screenshot table present?

Skip formatting review entirely for PRs authored by others.

## After the Review: Explaining a Finding

When Mike picks one out — "explain 1", "why does that matter", "what's the problem with X" — invoke `Skill(explain-issue)` and follow it. Verify the finding against the actual code on the branch first; do not relay the subagent's account as fact.

On request only. Never expand a finding into that format unprompted.

## Fixing a Finding

When Mike asks you to fix findings, invoke `Skill(fix-findings)` and follow it per finding. It scopes each fix before the edit, which is where most re-review findings are cheapest to prevent.

## After the Fixes: Re-Review

Once the batch is done, invoke `Skill(re-review)` before you report the work as complete. A passing suite proves each fix works; it does not review the fix.

Run it once per batch, not once per fix.
