# Comment Preferences

## Keep Comments Short — 2 Lines Is the Ceiling

A header comment on a file, class, component, or method gets 2 lines of prose at most. An inline comment gets 1–2 lines. A longer explanation belongs in a design doc or the PR body.

- Keep comment lines below about 15% of a file.
- Comment only what a reader would otherwise break. An example is a line that looks like a mistake: a doubled CSS selector, a `reload` in a loop, or an ordering dependency.
- Do not explain what the code already says.
- Do not repeat what a sibling documents. Name the sibling and stop.
- Do not write about alternatives, history, or long rationale. State what is true now.

- ✅ GOOD:
  ```ruby
  # Writes the phase order into the nested set: `lft` is the only authority for sibling order and
  # nested attributes never move the tree. Mirrors SowTemplateLineGroups::ApplyOrder.
  ```
- ✅ GOOD (the line looks like a typo otherwise):
  ```js
  // The doubled class is deliberate: React hoists this above the Bootstrap link, so a single
  // class ties `.card` and loses on source order.
  ```

## Comments Belong to the File They Live In

A comment explains its own file. It never describes a file that depends on this one. A superclass does not mention its subclasses, a base does not list its callers, and a spec does not describe another spec. A comment can name a parent class, or a sibling that this file mirrors.

- ❌ BAD (in the superclass): `# ProposalTemplateMilestonesPresenter subclasses this for the template form, whose subject answers no organization.`
- ❌ BAD (in the proposal spec): `# Other half of the pair: proposal_template_milestones_presenter_spec.`
- ✅ GOOD (in the subclass): `# A template is provider-owned, so it has no quoted_ware and no organization for the base to resolve against.`

## Never Put Ticket or Issue IDs in Code Comments

A comment must explain itself without a link. Never refer to an issue or PR in a comment or a test description: no `#38117`, `see #38117`, `GH-38117`, or URL. Write the reason in the comment instead. Commit messages and PR bodies still reference issues.

- ❌ BAD: `// #38117 — a second Save button in a sticky bar at the top of the form.`
- ✅ GOOD: `// A second Save button in a sticky bar at the top so the user never has to scroll to save.`
- ❌ BAD: `describe('save-error UX + Save placement (#38117)', () => {`
- ✅ GOOD: `describe('save-error UX + Save placement', () => {`
