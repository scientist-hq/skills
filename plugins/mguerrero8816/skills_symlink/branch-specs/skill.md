---
description: Compile the list of specs the current branch adds against its base branch, with a one-sentence summary of each. Load when Mike asks which specs a branch or a PR added.
---

## Step 1 — Find the base branch

Never assume the base is `main`. Confirm the branch, then read the base off its PR.

```bash
git branch --show-current
```

```bash
gh pr view --json number,baseRefName,headRefName
```

A part branch (`-p2`, `-p3`) often targets the earlier part, not `main`. If the branch has no PR, ask Mike which branch it came from.

For a branch that is not checked out, read the base from the PR number — `gh pr view 40178 --json baseRefName` — then use `<base>...<branch>` in the commands below.

## Step 2 — List the added examples

Run the helper from `rx/`. It reads the base off the PR, so pass no argument. Give it the base branch as the one argument only when the branch has no PR.

```bash
python3 .claude/skills/branch-specs/spec_ranges.py
```

Each line comes back as `path:start-end  <the example line>`. The script covers RSpec under `spec` — every directory, and the view layer needs all of them: `spec/views` for a rendered template, `spec/components` for a ViewComponent, `spec/features` and `spec/system` for a page a user drives — and Vitest under `test/javascript` plus any `*.test.*` or `*.spec.*` beside a component. It also catches `it.each`, `it.only` and `it.skip`.

The three-dot range compares against the merge base, so a merge from the base branch adds no noise.

**Never list added spec files instead of added examples.** A branch usually adds examples to a spec file that already exists, so `--diff-filter=A` reports nothing on a branch that added 30 examples.

If the script fails, fall back to the diff itself and read the line numbers by hand:

```bash
git diff main...HEAD -- spec | grep -E "^(\+\+\+ b/|\+[[:space:]]*(it|specify|scenario|it_behaves_like)[[:space:](\"'])"
```

## Step 3 — Read each example

The description string alone does not always say what the example checks. Read the body of each example in the file. Keep the enclosing `describe` and `context` in view, because they name the subject.

The diff prints a repo-root path (`rx/spec/...`). Drop the `rx/` prefix when you read the file.

An interpolated description is one line but many examples — `it "stamps #{expected} on a #{proposal_type} ..."`. Name the values that the loop covers.

## Step 4 — Output

Group the list by file. Print the path once, then one numbered line for each example. The summary comes first, then the description string, then the line range.

```
spec/models/pg/quote_group_spec.rb
1. The save fails validation when the customer turns the lock on and the request holds no rows — 'refuses the lock when the request holds no line items' (1267-1274)
2. One flat row makes the locked request valid — 'accepts the lock when the request holds a line item' (1276-1281)

spec/presenters/quote_group_milestone_templates_presenter_spec.rb
3. The JSON carries false for an unlocked request — 'emits milestonesSupplierLock false on an unlocked request' (57-61)
```

- Lead with the summary sentence. The description string is code and reads as noise in front, so it goes second, in quotes.
- Close each line with the range the script printed, in parentheses.
- Number the examples in one run across the whole list. Do not restart the count at each file. Mike names a number to ask about one example, so a number must point at one example only.
- Give one number to each line the script returned. A table form or an interpolated description is one line and one number, and the summary says how many cases it covers.
- Write the path relative to `rx/` so it stays clickable.
- Never use a table. The summaries are sentences and do not fit a column.
- Close with the totals: the number of examples and the number of files.

## Step 5 — Audit the list

After printing the list, look across it for ground covered twice and for examples that could go without losing what they check. Report the findings under the totals. Do not edit a spec unless Mike asks.

Compare setups and assertions, not description strings. Two examples worded differently are the same test when the arrangement and the expectation both match.

Look for these, in this order:

- **The same test twice.** Identical setup and identical assertion. One goes.
- **A subset.** One example's setup is another's with a field removed, and both assert the same thing. Keep the one that also proves the extra field is irrelevant, or keep the narrower one and say what the wider one added.
- **A constant asserted against itself.** `expect(SOME_CONSTANT[0]).to eq 'Group'` restates the source. It catches a deliberate edit, not a defect. Say so and let Mike decide.
- **A precedence chain tested pairwise when it is transitive.** Three rungs need three ordered pairs, not every combination. Name the pairs that carry it and the ones that follow.
- **An assertion the enclosing context already guarantees.** A `context 'on a proposal'` block whose every example re-asserts that it is on a proposal.
- **A shared example that would replace a run of near-identical ones.** Say what the parameter would be.

For each finding, give: the numbers involved, what makes them the same, which to keep, and what is lost by dropping the other. When nothing is lost, say that plainly.

### Across layers, not just within the list

A test at a higher layer exercises everything under it. A request spec that renders a presenter covers that presenter's output; an action spec that calls a service covers that service's contract. So a unit example can be redundant even when nothing else in the list resembles it.

Check the layers the branch touched, from the outside in — request, action, presenter, model — and ask of each unit example whether a higher one already fails when the code under it breaks.

**Prove it by mutation. Do not reason about it.** Revert the change the example covers, run the higher-layer spec, and read whether it fails.

**Then check `git status` before you say anything else.** A `finally` restores after a crash but not after an interrupt — kill the process between the write and the restore and the mutation stays in the working tree, looking like a deliberate change. Verify the tree is clean as a separate step, every time, and never report a result while a mutation might still be on disk.

A higher-layer failure means the unit example is redundant. No failure means it is the only thing catching that defect — keep it, and say so.

**Run the same mutation again after dropping anything.** A drop is only lossless if the detection survives it. Report the count that proves it: which spec still fails, and how many examples. A spec that drops to zero failures after the drop is the signal that the example was the only thing holding that detection.

**A stub breaks the chain.** Where the higher layer stubs the thing under test — a presenter spec stubbing the model method it would otherwise call — the two layers do not overlap at all, however similar they read. Check the helper before calling anything redundant.

**Never propose a reduction that drops a branch of behaviour.** Two examples that differ only in a value are still two cases when that value is the thing under test — a locked field and an unlocked one are not duplicates. If a reduction would leave a rung, a state or an owner untested, it is not a reduction; leave it alone.

Close with a count: how many examples the branch adds, and how many the audit would leave.

Print nothing when the list is clean. A section reading "no duplication found" is noise.

## Rules

- One sentence for each example. Put the extra detail in the sentence you keep, or leave it out.
- Do not run the specs. This skill only compiles the list.
- A re-indented example reads as added. If the same description also appears as a removed line in that file, the example moved. Do not list it.
