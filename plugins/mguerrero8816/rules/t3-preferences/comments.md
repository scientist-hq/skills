# Comment Preferences

## Keep Comments Short — 2 Lines Is The Ceiling

**A header comment on a file, class, component, or method gets at most 2 lines of prose. Inline comments get 1–2.** If an explanation needs more than that, it belongs in a design doc or PR body, not in the source.

- **Never exceed ~15% comment lines in a file.** If it's higher, the comments are doing narration instead of carrying information — cut until it isn't.
- **Comment only what a reader would otherwise break.** The load-bearing case is a line that looks like a mistake and would get "cleaned up" wrongly — a doubled CSS selector, a `reload` inside a loop, an ordering dependency. Those earn a comment. Code that already reads clearly does not.
- **Don't restate what a sibling already documents.** If a parallel class/component explains the shape, name it and stop: `Mirrors SowTemplateLineGroups::ApplyOrder — see that class for why each step is shaped this way.`
- **Don't explain what the code says.** No comment for `padding: 0` on an element with no padding, no restating a method name in prose, no listing the fields a method sets.
- **Cut alternatives, history, and rationale essays.** Why the other approach was rejected, what a value used to be, how the framework works internally — none of it stays. State what is true now.

**Examples:**
- ❌ BAD (18-line header essay re-deriving another class's five gotchas, plus a paragraph on why numbering is per-scope, plus a parenthetical comparing it to an unrelated subsystem)
- ✅ GOOD:
  ```ruby
  # Writes the phase order into the nested set: `lft` is the only authority for sibling order and
  # nested attributes never move the tree. Mirrors SowTemplateLineGroups::ApplyOrder.
  ```
- ✅ GOOD (inline, earns its place — looks like a typo otherwise):
  ```js
  // The doubled class is deliberate: React hoists this above the Bootstrap link, so a single
  // class ties `.card` and loses on source order.
  ```

## Comments Belong to the File They Live In

**A comment explains the file it sits in — never a file that depends on this one.** A superclass does not mention its subclasses, a spec does not describe another spec, a base does not list its callers.

The test: does a reader of *this* file need the line to understand *this* code? If it only helps someone hunting for the other file, delete it — they will be reading that file, not this one.

- **Pointing outward is fine when this file depends on the thing.** Naming a parent class, or the sibling whose shape this one mirrors, answers a question this reader actually has. Naming a child answers one they don't.
- **Whatever differs lives with the specific case, not the general one.** What a subclass changes is documented in the subclass; what a spec covers is documented in that spec.
- **Applies to specs as much as to code.** No "the other half of this pair is in …", no inventory of which sibling spec covers what.

**Examples:**
- ❌ BAD (in the superclass): `# ProposalTemplateMilestonesPresenter subclasses this for the template form, whose subject answers no organization.`
- ❌ BAD (on a method a subclass overrides): `# Overridden on the template subclass.`
- ❌ BAD (in the proposal spec): `# Other half of the pair: proposal_template_milestones_presenter_spec.`
- ✅ GOOD (in the subclass, about itself): `# A template is provider-owned, so it has no quoted_ware and no organization for the base to resolve against.`

## Never Put Ticket / Issue IDs in Code Comments

Code comments must be self-contained. Describe *what* the code does and *why* — never point to a GitHub issue/PR number as the explanation. A reader should never have to open GitHub to understand a comment.

- Applies to all languages and all comment kinds (Ruby, JS/TS, ERB/HAML, block comments, inline comments, and RSpec/Jest `describe`/`context`/`it` strings).
- Covers every form of reference: `#38117`, `(#38117)`, `see #38117`, `GH-38117`, issue/PR URLs.
- If the *why* lives in a ticket, summarize that reasoning inline instead of linking to it.
- This is about **comments and test descriptions**, not commit messages or PR bodies — those still reference issues normally (the linked-issue CI check needs them).

**Examples:**
- ❌ BAD: `// #38117 — a second Save button in a sticky bar at the top of the form.`
- ✅ GOOD: `// A second Save button in a sticky bar at the top so the user never has to scroll to save.`
- ❌ BAD: `// Reuse seam: when #37244 / #37575 land a second validator, consider extracting.`
- ✅ GOOD: `// Reuse seam: when the supplier-proposal and QG validators land, consider extracting.`
- ❌ BAD: `describe('save-error UX + Save placement (#38117)', () => {`
- ✅ GOOD: `describe('save-error UX + Save placement', () => {`
