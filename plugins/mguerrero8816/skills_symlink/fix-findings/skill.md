---
description: How to fix a review finding. Scope the fix before you edit — most of what a re-review catches is what a careful read before the edit would have prevented.
---

## When to Use This

Load this when Mike asks you to fix one or more findings from a `/review`. Follow it for each finding, then run `Skill(re-review)` once the batch is done.

## The Failure This Prevents

A fix starts at the line the finding names. It grows only as far as the edit needs, then stops. Everything outside that radius stays unread — including the lines the fix has just made wrong.

Every check below moves a `re-review` check earlier, to the point where it costs one read instead of one rework.

## Step 1: Read the Whole File Before You Edit

Read the file end to end first. Do not read only the hunk or only the method.

You are looking for what your change is about to make untrue:

- Copy that describes the old behaviour.
- An icon, label, or colour that will now carry two meanings in one view.
- A comment that the change contradicts.

These lines never appear in a diff, so nothing downstream will show them to you.

## Step 2: Name the Principle in One Sentence

Write the rule the fix applies, in plain words, before you write code.

- "Do not offer a control that builds rows the request discards."
- "The exemption covers the one row the lock allows, not any row that names it."

A fix you cannot state as a rule is a fix you cannot check for completeness. If the sentence is hard to write, the finding is not understood yet.

## Step 3: Find the Siblings

Search for every other place that principle holds. Use the sentence from step 2 to decide what to search for.

Then decide, per sibling, whether it is in scope. Both answers are fine. Silence is not.

- In scope: fix it in the same edit.
- Out of scope: say so to Mike, with the reason.

**This is the most common hole.** A sibling looks correct on its own terms, because it was written before the principle existed. It only looks wrong once the principle is stated.

**Search in both directions.** Siblings are other readers of the same thing. Producers are everything that supplies it — callers, payloads, and above all allowlists: htmx `params:` filters, strong-parameter `permit` lists, serializer field lists, payload hashes built in a view. If the fix changes what a piece of code reads, every producer has to send it, and a producer that omits it shows nothing at all. That omission is the highest-severity thing this step catches.

## Step 4: Own the Whole Construct You Touch

When the edit changes one clause of a condition, one field in a list, or one branch of a case, read all of them.

Look hardest when you extract or rename. Moving three clauses into a new method makes all three yours, and a reviewer will read them as yours.

## Step 5: List the Branches, Then Write the Specs

Spec-first drives one spec: the failing test for the behaviour in the finding. It does not drive tests for the guard clauses you add on the way.

So before you edit, list every branch the fix will introduce — each `next`, each early `return`, each `blank?` guard. Each one gets a spec in the same edit, or an explicit note that it does not need one.

Add the branch specs at the same time as the fix. A branch left for later is a branch a re-review finds.

## Step 6: Edit Once

Make the whole scoped change in one pass. Then run the specs.

Prove each load-bearing spec catches a regression: revert the line it protects, confirm the spec fails, restore the line, and confirm `git diff` on that file is empty. Quote the failure as evidence.

## Step 7: Update What the Fix Invalidated

A fix can make something outside the code stale. Check these before you report:

- **The PR body's test plan** — a new spec file has to join the command in the test steps, and a changed flow has to match the steps that describe it.
- **A list that enumerates files or fields** anywhere else in the repo.

These go stale one fix at a time and nothing fails when they do.

## What to Tell Mike

With each fix, state:

- The principle, in the sentence from step 2.
- Any sibling or producer you left out, and why.
- Any branch you added without a spec, and why.
- Any divergence the fix creates that nothing currently reaches. "Not reachable today" is a status to record, never a reason to drop it — an unrecorded judgement is indistinguishable later from never having noticed.

Do not report the fix as done while a scope decision is still unstated. An unstated decision reads as an oversight, and after a re-review it is indistinguishable from one.
