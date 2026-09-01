# Output Formatting

## No ⏺ Bullet Prefix

Never prefix code, commands, or any output with the `⏺` character or any similar Unicode bullet/dot. Code and commands appear without decorative prefix characters.

## Long Tables Go in a Fenced Code Block

**A table with more than about six rows must be a pre-aligned plain-text table inside a fenced code block.** Use a markdown pipe table only for short tables. This covers every review summary table, every rollup, and every comparison list long enough to scroll.

The terminal draws the answer as it streams. It measures the column widths from the rows that arrive first, then repaints wider when a longer row arrives. A line that has scrolled out of the live region cannot be rewritten, so the early rows keep the old widths. The table then looks correct on screen and broken in the scrollback, with a narrow first row and an empty stub row at the seam. A code fence is never re-laid-out, so the widths hold.

Rules for the fenced table:

- Keep the total width at 78 characters or less.
- Pad every cell with spaces to a fixed column width. Put two spaces between columns.
- Write a header line. Do not add a row of dashes under it. The fence already separates the table from the prose.
- Do not use pipe characters or backticks inside the fence. A code fence shows them as literal text.
- Location cells hold the basename and line only.

- ✅ GOOD:
  ```
   #  Finding                          Location                     Sev   Status
   1  Decision col pre-filled Y        cir_import.rake:179          High  New
   2  Tie broken by JSON order         cir_import.rake:149          High  New
  10  Score uses raw name lengths      cir_import.rake:165          Med   Pre-ex
  ```

## Tables Too Wide for the Terminal

Print tables with full content. If the user says the table does not render correctly (it looks like a list, they ask why it is not a table, they ask you to reprint it), the rows are too wide for their terminal. Abbreviate file paths to the basename and shorten each cell until the table fits.

## Say "Tested", Not "Pinned"

Never use "pinned", "pinning", or "pins" to mean that a spec covers a behaviour. Say **tested** — or "there's a spec for it", "covered". This applies to review findings, explanations, PR bodies, and anything else user-facing.

The word appears in some comments and PR descriptions in this repo. That is not licence to adopt it — it reads as jargon, and it is not standard testing vocabulary.

- ❌ BAD: "The guard is pinned on the QG path but not the template path."
- ✅ GOOD: "The guard is tested on the QG path but not the template path."
- ❌ BAD: "There's a spec pinning the duplicate-name behaviour."
- ✅ GOOD: "There's a spec covering the duplicate-name behaviour."

**When the point is that a spec runs code without catching changes to it, spell that out — don't reach for another one-word label.** "Tested" alone would be wrong there, and substituting a different piece of jargon repeats the original mistake.

- ❌ BAD: "The seeder guard isn't pinned on the template path."
- ❌ BAD: "The seeder guard isn't characterized on the template path."
- ✅ GOOD: "The template-path spec runs the seeder guard but never checks the flat list, so reverting the guard leaves the spec green."

## Explaining Technical Things — Plain Words, Consequence First

Applies to any answer that explains code, a bug, or a change — not just formal recaps. The full recap skeleton lives in the `explain-issue` skill; these are the habits that apply everywhere.

**Lead with the plain-English claim, then the identifier.** Introduce a domain noun in ordinary words, with a real value, before naming the class or method. An identifier first makes the reader decode before they can care.

- ❌ BAD: "`MilestoneGroup#turn_around_time` is a `has_one`, so nested assignment raises on a mismatched id."
- ✅ GOOD: "Each group can carry a turnaround — '2–4 days'. The browser submits that record's id back on save, and if the record is gone, Rails raises."

**Spend the sentence on the consequence, and enumerate what's lost.** Name what the person using the app actually sees. The mechanism goes after, in support of it.

- ❌ BAD: "The submission was discarded."
- ✅ GOOD: "The supplier saw a 500 and lost every other change in that submission: the rename, the new rows, all of it."

**Prose over code blocks.** Quote a line only when its exact shape is the point. If the crux can be said — "the id came back pointing at nothing" — say it; a pasted predicate adds nothing actionable. Keep `file.rb:line` inline so it stays clickable.

**Bold inline lead-ins beat headings for anything under a screen.** `**The bug.**` opening a paragraph keeps a four-part explanation together; `###` headings turn six sentences into a document. Save real headings for genuinely long output.

**Bound the claim.** Say what did *not* change alongside what did, and date the problem — new to this branch, pre-existing, or latent, and what was checked to establish that. It's usually the reader's next question.

**Caveats and self-corrections go in a short closing list**, not buried mid-paragraph. A caveat inline reads as hedging; the same caveat as a closing bullet reads as thoroughness. This includes correcting advice given earlier in the conversation — see `corrections` guidance for tone, but do not omit it to avoid the correction.

## Answer the Question in the Fewest Sentences That Answer It Fully

**A direct question gets a direct answer. Name the one thing, then stop.** Lead with the answer itself — not the background that led to it, not the adjacent facts, not why the question is interesting. Two or three sentences is usually the whole reply.

Mike asks the same question again when the answer is buried. A repeated question is the signal that the previous answer was too long, not that it was unclear. Cut, do not expand.

- **Never inventory what you found while checking.** The comparison table, the file sizes, the related issue, the timeline — all of it is how the answer was reached, not the answer. Keep it out unless Mike asks how it was established.
- **One fact per question.** If the question is "what is X missing", name what X is missing. Do not also explain what X has instead, what ticket covers it, or what that implies, until asked.
- **No headings, no tables, no code fences for a short answer.** They signal a document. A direct answer is prose.
- **Do not re-explain a point already made.** If the answer appeared three replies ago, say it once more in its shortest form and stop.

**Examples** — asked "what is the vb file missing that the file you recommended has?":

- ❌ BAD: an eight-row table of every absent construct, the two files' line counts, a paragraph on the issue that tracks the port, and a closing paragraph on why the doc sentence is "empty rather than mislabeled"
- ✅ GOOD: "The `nsformat_currency` call. `invoice_pdf.html.js:527` has `${nsformat_currency(total)}`. `invoice_with_vb_reference.html.js` has none — it formats with `?string(",##0.00")` instead. The doc says the vb file uses `nsformat_currency`. It doesn't."

## Load Specific Skills Before Certain Actions

- Before calling any `mcp__playwright__` tool → invoke the `playwright-qa-rules` skill first
- Before writing or editing any file in `.claude/skills/` or `.claude/rules/` → invoke the `authoring` skill first
