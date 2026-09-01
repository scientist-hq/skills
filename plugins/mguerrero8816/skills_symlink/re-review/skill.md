---
description: Verification pass over a batch of review fixes. Confirms each fix did what it claimed and hands detection back to a full /review — run it before you report the work as done.
---

## When to Use This

Run this after you fix findings from a `/review`, once per batch, before you tell Mike the work is done.

**This is a verification pass, not a review.** It answers questions only this session can answer: did each fix cover what its own diagnosis described, are the deferred findings still correctly classified, and does each new spec actually fail when the code it protects is reverted. It does not hunt for new defects.

Detection is `/review`'s job, and Step 4 hands it back. Do not let this pass stand in for that — it has twice been run carefully and still missed defects that were in the branch from the first commit, because the person running it wrote the code and reads every line already knowing what it is for. Author-blindness is not curable by a longer checklist.

Do not skip it because every spec passes. A green suite proves each fix runs. It does not prove the fix matched the finding.

## Step 1: Establish What Changed

The subject is the **accumulated** change since the review ran — the union of every fix, committed or not. Not one fix at a time.

1. `git log --oneline` to find the commit the review ran against.
2. `git diff <that-sha>...HEAD` for the committed fixes.
3. `git status --short` and `git diff` for anything still in the working tree.

Read them together. Some defects exist only in the union — duplicated logic, a stale list, two names for one thing — because each change was correct alone.

## Step 2: Verify Each Fix Against Its Own Diagnosis

**Open what you wrote when you explained the finding, before you fixed it. Confirm the fix covers every consequence you described.**

This is the check that only this session can run, because only this session has the explanation. A finding explained as "several rows do X, one row does Y" and fixed only for Y is not fixed — and the analysis was already correct, so nothing later will re-derive it.

For each fix, state the principle it applies in one sentence, then confirm:

- Every consequence named in the explanation is addressed.
- Every sibling and producer you decided to leave out was a decision, not an omission.
- Every branch the fix added has a spec, or an explicit note that it does not need one.

## Step 3: Prove Each New Spec Catches a Regression

A spec that runs the code without checking it stays green when the code is reverted.

For each load-bearing spec added, revert the line it protects, run the spec, confirm it fails, restore the line, and confirm `git diff` on that file is empty. Report the failure message as evidence. Never claim a spec catches a regression you did not observe fail.

Watch for assertions weaker than they read — a negated `every`, an absence check a broken page also satisfies, an unbounded collection.

## Step 4: Re-Check the Deferred Findings

Go back to the original review's list. For each finding not fixed, confirm the reason still holds.

- A finding deferred to another ticket must still belong there.
- A finding dropped as invalid must still be invalid. The fixes may have changed what it rests on.
- A finding called pre-existing must still be pre-existing. Verify it against the base branch again if a fix touched that file.
- **Check whether new code re-applies a pattern already classified as pre-existing.** A new allowlist carrying unscoped foreign keys is a new instance, not the old one.

## Step 5: Hand Detection Back to `/review`

**Run `/review` over the branch after this pass, every time, before reporting.** Not when the batch looks large, and not as a suggestion the user can wave off — the author cannot substitute for a cold read, so skipping it means that read never happens.

The fixes are part of the branch now, so the same agents will read them alongside everything else, without knowing which lines are new.

Report what it found together with this pass's results.

## Latent Is Not Absent

**Every "this cannot be reached today" conclusion is recorded as a finding with that status. It is never a reason to drop it.**

Reasoning correctly that something is unreachable and then not writing it down is indistinguishable, later, from never having noticed. The same applies to a divergence a fix creates: if two places used to agree and now do not, that is a finding even when nothing currently reaches the difference.

## Step 6: Report

Use the same output shape as `/review` — see `review/skill.md`. Findings get one plain number sequence, one to three sentences each, and a `file.rb:line`.

Three additions for this pass:

- **Say who introduced each finding.** Split them: defects the fixes introduced, defects the `/review` in step 5 found, and findings carried over unchanged. Mike's first question is which of these are new since he last looked.
- **Say plainly when a fix has a hole.** Do not soften it and do not pad it with an apology. State the hole, its location, and what closes it.
- **List every scope decision you made while fixing** — a sibling left alone, a branch left unspecced, a divergence judged unreachable. An unstated decision is indistinguishable from an oversight.

If the pass finds nothing, say so in one line and name what you checked. Do not manufacture findings to justify the pass.
