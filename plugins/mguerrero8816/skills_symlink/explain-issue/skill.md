---
description: How to explain a single bug, vulnerability, or review finding in plain terms — what breaks, the concrete steps to cause it, and honest severity. Also holds the short recap format for "what did we just fix". Load when asked to explain, clarify, expand on, or summarize one issue or fix.
---

## When to Use This

Load this when Mike picks one issue and asks for it — "explain 1", "what's the problem with X", "why does that matter". It is for explaining a *defect*: something that is broken, exploitable, or wrong.

Do **not** volunteer this format. Findings are first presented as a short summary (one to three sentences plus location). The full explanation comes only when asked. See `review/skill.md` for how review output is staged.

For tracing how one thing leads to another — exception propagation, call flows, callback chains — use `explain-causation` instead. The two compose: this skill is the shape of the explanation, that one is the rule about file:line in a trace.

## Verify Before Explaining

Read the actual code first, on the branch in question. Never relay a subagent's finding or your own earlier summary as fact — confirm each claim against the file. If a claim doesn't hold up, say so and correct it rather than explaining a defect that isn't there.

### Verifying the claims is not verifying the repro

Every individual claim can be true while the steps still don't run. A permit accepting `:_destroy`, a model with no validation, and a UI that hides a button are three true facts that do **not** add up to a working attack if there's no route that reaches them.

Before writing steps, confirm the path is reachable end to end:

- **Is there a route and an action?** `rails routes -c <controller>` — an `edit` that redirects, or a missing `update`, kills anything that depends on submitting to it.
- **Does the client actually send that field?** Grep the component for the param name. A key in the permit proves the server would accept it, not that anything produces it.
- **Does the record exist at that point?** Nested attributes with an `id` on a brand-new parent raise `RecordNotFound` — steps that assume "save it first, then tamper" need a save path that persists what you're tampering with.
- **Walk the steps in order and name what carries state between them.** If step 3 needs a database id that step 1 never created, the repro is fiction.

If a step can't be reached, drop it and re-derive the finding from what *is* reachable. The remaining defect is often real but simpler and with a different fix — and a fix aimed at the unreachable path does nothing.

## The Short Version

When Mike asks what a fix did, or to summarize or recap one — "what did we just fix", "summarize that" — give the short version, not the six-part shape. It is also the right answer for a finding small enough that the full shape would pad it.

Four parts, each one to three sentences. No repro steps, no severity section, no code beyond the one line that is the crux.

1. **One-line opener, plain English.** What the change means in human terms, before any identifier. `Short version: we made a guard stop lying about whether a proposal has phases.`
2. **The method / the context.** What the code is for and who depends on it — enough that the bug lands.
3. **The bug.** What it did wrong, then the consequence in one sentence. Name the failure the reader would actually see ("saves clean with wrong totals and tax, no error"), not the mechanism.
4. **The fix.** The one line, and explicitly what did *not* change.

Then, only if either is true, a closing note:

- **It was latent, not live** — say so plainly, with what you checked to establish it. Never let a summary imply an outage that isn't one.
- **The recommendation changed during implementation** — say what you'd said, what implementing it revealed, and why the shipped fix differs. This belongs in the summary, not buried.

Keep it scannable in a terminal: short paragraphs, no table unless it genuinely compresses a before/after.

### What makes it readable

The four parts above are the skeleton. These are what Mike has called out as the difference between a recap that lands and one that doesn't — apply them on top of the structure, not instead of it.

- **Bold inline lead-ins, not `###` headings.** `**The bug.**` opening a paragraph keeps four sections inside one screen. Real headings turn a six-sentence recap into a document.
- **Usually no code block at all.** The rule above allows one crux line; the better default is prose. If the crux is "the id came back pointing at nothing", say that — a snippet of the predicate adds nothing a reader can act on. Reach for the line only when its exact shape is the point.
- **Define the domain noun in plain words, with a real value, before any identifier.** "Each group can carry a turnaround ('2–4 days')" earns the rest of the paragraph. `MilestoneGroup#turn_around_time` does not.
- **Spend the sentence on the loss, not the mechanism, and enumerate it.** "The supplier saw a 500 and lost every other change in that submission: the rename, the new rows, all of it" beats "the submission was discarded." The specifics are what make it feel real.
- **Date the bug.** Say plainly whether the change under review is what made it reachable, whether it predates the branch, or whether it was latent. This is usually the reader's next question.
- **Make the fix sound inevitable.** If it follows a rule the codebase already applies elsewhere, say so — "same rule the other two levels already follow" tells him it's consistent, not bolted on.
- **State what did *not* change,** in the same breath as the fix. It's the fastest way to bound the blast radius.
- **Put caveats and corrections in a short closing list.** Including corrections to your own earlier advice — see the recommendation-changed note above. A caveat buried mid-paragraph reads as hedging; the same caveat as a closing bullet reads as thoroughness.

## The Shape

Six parts, in this order. Skip a part only when it genuinely doesn't apply. Use this when Mike asks to *explain* a finding — for a recap of a fix, use the short version above.

### 1. The setup — what is supposed to happen

State the promise being made, in the language of the people involved, before any code. Who is protected, from what, and what they've been told.

> A customer marks a phase as **Required**. The promise is: the supplier must deliver a proposal that includes that phase with at least one line item. They can't drop it.

### 2. The steps to cause it

Numbered, concrete, in order. Real URLs, real field names, real values. If there is more than one route in, label them as versions and give the simplest first.

Say up front what access or skill the steps need — clicking through the UI, editing the DOM, crafting a request, database access. That distinction is most of the severity.

> 1. Supplier opens `/quoted_wares/27/proposals/new?react_milestones=1`.
> 2. Opens devtools, finds the card `<div>` for "Setup & Dosing", deletes that element.
> 3. Clicks Submit.

### 3. Why the existing guard doesn't catch it

Only when there *is* a guard that looks like it should. Name it, quote the one line that lets the case through, and say why that line is reasonable on its own terms — then why it leaves the hole.

Being fair to the code is the point. A guard that's wrong for a defensible reason is a different problem from one that's just wrong, and it changes the fix.

### 4. What actually goes wrong

The consequence in the user's world, not the system's. Then one concrete instance with plausible names.

> Concretely: customer mandates a "Safety Testing" phase. Supplier drops it. Customer accepts a proposal they believe covers safety testing because they mandated it. It doesn't.

### 5. Severity, honestly

A short section under its own heading. Say what makes it *hard* to hit and what limits the damage — then say whether that mitigation actually holds. Do not inflate, and do not let a real mitigation quietly close the issue if it doesn't cover the case that matters.

> This isn't something a supplier stumbles into. It takes deliberately editing the page, and the customer still has to accept the proposal.
>
> But "the customer must accept it" is weak cover here — the whole point of the flag is so the customer *doesn't* have to re-check. That's the assurance being sold, and nothing on the server backs it.

### 6. Fix

What closes it, and what it doesn't close. If part of the problem needs work beyond the fix, name that separately rather than implying one patch covers everything.

## Style

- **Plain words over jargon.** "The supplier can delete a phase the customer required" beats "nested attributes permit unauthorized destruction."
- **Code only when it's the crux.** One to three lines, the exact line that matters. Never paste a method to show context — describe the context instead.
- **`file.rb:line` for anything Mike might open.** Inline, not in a list at the end.
- **No severity labels as a substitute for explaining.** "High" tells him nothing he can act on.
- **Headings, short paragraphs.** He's reading in a terminal.

## Non-Defect Explanations

If the thing being explained is not a defect — how a feature works, why the code is written a certain way — this shape doesn't fit. There are no repro steps and no severity. Explain it directly.
