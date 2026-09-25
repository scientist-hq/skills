# Output Formatting

## No ⏺ Bullet Prefix

Never put `⏺` or a similar Unicode bullet before code, commands, or other output.

## Long Tables Go in a Fenced Code Block

A table with more than about six rows must be a plain-text table in a fenced code block. The terminal can show a long markdown table with broken column widths in the scrollback. Use a markdown pipe table only for a short table.

- Keep the width at 78 characters or less.
- Pad each cell to a fixed column width, with two spaces between columns.
- Write a header line, but no row of dashes.
- Do not use pipes or backticks inside the fence.
- In a location cell, write only the basename and the line.

- ✅ GOOD:
  ```
   #  Finding                          Location                     Sev   Status
   1  Decision col pre-filled Y        cir_import.rake:179          High  New
  10  Score uses raw name lengths      cir_import.rake:165          Med   Pre-ex
  ```

Print full content in each cell. If Mike says that a table does not render correctly, it is too wide. Shorten the cells until it fits.

## Say "Tested", Not "Pinned"

Never use "pinned", "pinning", or "pins" to mean that a spec covers a behavior. Say "tested", "covered", or "there's a spec for it". When a spec runs code but does not catch a change to it, say that in full words. Do not use a different one-word label.

- ❌ BAD: "The guard is pinned on the QG path but not the template path."
- ✅ GOOD: "The guard is tested on the QG path but not the template path."
- ✅ GOOD: "The template-path spec runs the seeder guard but never checks the flat list, so reverting the guard leaves the spec green."

## Explaining Technical Things

These habits apply to any explanation of code, a bug, or a change. The full recap format is in the `explain-issue` skill.

- **Plain claim first, identifier second.** Name the thing in ordinary words, with a real value, before you name the class or method.
- **Consequence first.** Say what the person who uses the app sees, and list what they lose. Put the mechanism after that.
- **Prose over code blocks.** Quote a line only when its exact shape is the point. Keep `file.rb:line` inline.
- **Bold lead-ins, not headings,** for anything shorter than one screen.
- **Bound the claim.** Say what did not change. Say whether the problem is new to the branch, pre-existing, or latent, and how you know.
- **Caveats and corrections go in a short closing list.** Do not omit a correction of earlier advice.

- ❌ BAD: "`MilestoneGroup#turn_around_time` is a `has_one`, so nested assignment raises on a mismatched id."
- ✅ GOOD: "Each group can carry a turnaround — '2–4 days'. The browser submits that record's id back on save, and if the record is gone, Rails raises."
- ❌ BAD: "The submission was discarded."
- ✅ GOOD: "The supplier saw a 500 and lost every other change in that submission: the rename, the new rows, all of it."

## Answer the Question in the Fewest Sentences That Answer It Fully

Lead with the answer. Two or three sentences is usually the whole reply. If Mike asks the same question again, the last answer was too long. Make the next one shorter.

- Do not list what you found on the way to the answer.
- Answer only the fact that Mike asked for.
- Use no headings, tables, or code fences in a short answer.
- Do not explain a point again after you made it.

- ✅ GOOD (asked "what is the vb file missing that the file you recommended has?"): "The `nsformat_currency` call. `invoice_pdf.html.js:527` has `${nsformat_currency(total)}`. `invoice_with_vb_reference.html.js` has none — it formats with `?string(",##0.00")` instead."

## Load Specific Skills Before Certain Actions

- Before any `mcp__playwright__` tool, invoke the `playwright-qa-rules` skill.
- Before you write or edit a file in `.claude/skills/` or `.claude/rules/`, invoke the `authoring` skill.
