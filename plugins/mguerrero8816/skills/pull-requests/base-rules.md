---
description: Universal rules for all pull request creation including draft mode, ticket linking, branch safety checks, labeling, URL generation, and required PR description format.
---

# General Pull Request Rules

## Ticket Linking

**🚨 CRITICAL: ALWAYS link a PR to a ticket — never create an unlinked PR 🚨**

Before writing the PR description:
1. Search GitHub issues for a relevant ticket: `gh issue list --search "<feature keywords>" --limit 10`
2. If a matching ticket is found, ask the user: "I found #XXXXX — is that the right ticket to link?" before proceeding
3. If no ticket is found, ask the user what ticket to link to
4. Only create an unlinked PR if the user explicitly confirms there is no matching ticket

**Examples:**
- ❌ BAD: Write PR description with no issue reference
- ❌ BAD: "As part of #36316" — does not close the ticket on merge
- ✅ GOOD: "Resolves #36316" — closes the ticket automatically when the PR merges
- ✅ GOOD: "I found #36316 'SOW: Fee Cap locking to Original Proposal Date' — is that the right ticket to link?" before proceeding
- ✅ GOOD: "I couldn't find a matching ticket — which issue should this PR link to?"

## Research Groundwork

**🚨 CRITICAL: ALWAYS research the codebase before writing any PR or issue description 🚨**

Before writing a single word of a PR or issue description:
- Search the codebase for the relevant code, service, model, or controller being referenced
- Read the actual implementation to understand what it does, what triggers it, and what conditions it checks
- Base the description entirely on what the code actually does — never on assumptions or what the user said it does
- If the user says "X triggers Y", verify that in the code before writing it down

This applies to:
- Bug reports (understand the current buggy behavior from the code)
- Feature PRs (understand what existing code you're building on)
- Any issue that references existing system behavior

**Example:**
- ❌ BAD: User says "the trigger is wrong" → write a ticket describing a wrong trigger without checking the code
- ✅ GOOD: User says "the trigger is wrong" → find the trigger in the codebase, read what it currently does, then write the ticket describing the actual current behavior vs. expected behavior

## Pre-Flight Checks

**CRITICAL: Check Current Branch First**
- ALWAYS run `git branch --show-current` before any PR operation
- The git status shown at conversation start is a snapshot and can be stale
- NEVER assume the branch based on conversation history

**Branch Creator Check**
- ALWAYS verify the branch creator before pushing or creating a PR
- Use `git log <parent-branch>..HEAD --reverse --format="%an <%ae>" | head -1` to find the first commit unique to this branch
- **NEVER** use `git log HEAD --reverse ...` — that walks back to the repo's initial commit and will return the wrong author
- Compare the result against `michael@scientist.com`; if they don't match, do NOT push

**Protected Branch Check**
- NEVER create PRs from protected branches: `main`, `staging`, or `production`
- If the current branch is a protected branch:
  - STOP immediately
  - Alert the user they are on a protected branch
  - DO NOT checkout to a new branch or take any action
  - Simply inform them that a PR should not be opened from this branch

## PR Creation Rules

**CRITICAL RULES:**
- **ALWAYS create PRs as drafts** using the `--draft` flag
- **NEVER** create ready-for-review PRs
- **NEVER** merge PRs
- **NEVER** approve PRs
- **NEVER** close PRs
- **NEVER** add comments to PRs (via `gh pr comment` or any other means)
- **NEVER** modify PRs that the user has not contributed code to
- Only create draft PRs and update metadata - nothing beyond that

**PR Title Prefix Rules:**
- **ALL PRs into `staging`** must have the title prefixed with "Staging: "
- **Example**: "Staging: Fix Select2 dropdown z-index in reassign approval modal"
- PRs into `main` do not need a prefix

**Editing Existing PRs:**
- If a PR needs changes (title, description, labels, etc.), use `gh pr edit` to update it
- Never close and recreate a PR - always edit the existing one
- You can edit: title (`--title`), body (`--body`), labels (`--add-label`, `--remove-label`), milestone (`--milestone`)

## PR Labeling Rules

**Area label rules:**
- **Backoffice pages only**: Add "Backoffice" label
- **Marketplace/Storefront pages only** (anything NOT in backoffice): Add "Storefront" label
- **Both backoffice AND storefront pages**: Add NEITHER label (no label implies universal change)

**CRITICAL: Storefront and Backoffice labels are mutually exclusive:**
- **NEVER** add both "Storefront" and "Backoffice" labels to the same PR
- A PR can affect one area (use that label), both areas (use no label), but never should have both labels
- If changes affect both backoffice and storefront, omit the area label entirely
- Having no area label indicates a universal change that affects multiple areas

**Bug fix PRs: use "Type: Fix", NOT "Bug":**
- When opening a PR that resolves a bug ticket, add the **"Type: Fix"** label
- **NEVER** add the "Bug" label to a PR — "Bug" is for issues/tickets only, not PRs

**Determine area by:**
- Controller namespace (e.g., `Backoffice::` = backoffice)
- Layout used (`backoffice_bs5_layout` = backoffice, `storefront_bs5_layout` = storefront)
- URL path (`backoffice.test` = backoffice, `az.test` = storefront)
- Route prefix (`/admin` on marketplace = storefront, `/backoffice` = backoffice)

**Examples:**
- PR modifies only `/app/views/backoffice/providers/` → Add "Backoffice" label
- PR modifies only `/app/views/admin/news_items/` → Add "Storefront" label
- PR modifies `/app/views/shared/_news_item_form.html.haml` used in both backoffice and admin → Add NO area label

## Gathering Context

**CRITICAL: Always compare against the parent branch, NOT main**
- Branches do not always originate from `main` - they may branch from other feature branches
- Use the parent branch that the current branch originated from for all comparisons
- Check CLAUDE.local.md "Branch Comparisons" rule for details

Before creating the PR, gather:
1. Current branch name: `git branch --show-current`
2. Determine the parent branch (the branch this originated from)
3. Git status: `git status`
4. Commits on branch: `git log <parent-branch>..HEAD --oneline`
5. Files changed: `git diff <parent-branch>...HEAD --stat`
6. Full diff: `git diff <parent-branch>...HEAD`
7. Read the controller(s) being modified to understand all actions

## Generating URLs for Test Instructions

**IMPORTANT**: Always derive URLs from the actual code changes, NOT from template PRs.

**Determining the Route:**
- Look at the controller path and module to determine the route
- Example: `app/controllers/admin/providers_controller.rb` under `Admin` module → `/admin/providers`

**Marketplace vs Backoffice:**
- **Backoffice pages**: Use `https://backoffice.test` as base URL
- **Marketplace pages**: Use `https://az.test` as base URL
- **Rule**: If it's NOT in the backoffice, it's on the marketplace

**Examples:**
- Marketplace admin: `https://az.test/admin/providers`
- Backoffice accounting: `https://backoffice.test/accounting/order_requests`

**Controller Layout Changes:**
- When a controller adds a layout change (e.g., `layout :backoffice_bs5_layout`, `layout :storefront_bs5_layout`), this affects ALL actions in that controller
- Even if only the index view was modified, you MUST include test instructions for ALL actions that exist in the controller (show, edit, new, etc.)
- Always read the controller to check which actions exist and include them ALL in test instructions

**Placeholder Syntax for Show/Edit Actions:**
- Use `#{}` syntax to indicate where users should insert their own local record information
- Examples: `#{order_request.id}`, `#{order_request.uuid}`, `#{provider.slug}`, `#{invoice.uuid}`
- Use the correct model name based on what you see in the controller/view code
- Use the correct field (id vs uuid) based on how the route is defined (check the view links or route parameters)

**UUIDs vs IDs vs Slugs:**
- Most URLs that specify `:id` parameters are actually using UUIDs, not the numeric `id` column
- **Provider routes use UUID, NOT slug** — use `provider.uuid`, not `provider.slug` when constructing provider URLs (e.g., `/providers/612f95b7-.../saved_line_item_rate_cards`)
- When in doubt, check the route definition or controller to see which is used

**Example URLs with Placeholders:**
- `https://backoffice.test/accounting/order_requests/#{order_request.id}`
- `https://backoffice.test/accounting/invoices/#{invoice.uuid}`
- `https://az.test/admin/providers/#{provider.slug}`

## Required PR Description Sections

**CRITICAL: ALL PRs must use this EXACT format:**

```markdown
**Description**
What does this pull request do and which tickets does it resolve?

**User Impact**
What changes for a user? Who are the users? (Researcher, Supplier, Scientist Admin, etc.)

**Instructions**
1. Add detailed steps to assist reviewers testing these changes.

[**Screenshots** section — include ONLY when there are view file changes; omit entirely otherwise]

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

**Section Guidelines:**

1. **Description**
   - Start with issue reference using "Resolves #XXXXX" — this auto-closes the ticket when the PR merges
   - Only use "As part of #XXXXX" if the user explicitly says the ticket should stay open after merge
   - Explain what the PR does
   - Include relevant technical details

2. **User Impact**
   - What bug is fixed or feature is added
   - Specify user types: Researcher, Supplier, Scientist Admin, etc.
   - Can state "No external impact" if it's internal-only or code cleanup

3. **Instructions**
   - **CRITICAL**: Only include test instructions for files that were changed from the parent branch
   - Do NOT include test instructions for functionality from the parent branch that will be tested when that branch merges
   - Compare against the parent branch (not always main) to determine what changed in THIS branch
   - Provide specific URLs with placeholders where needed (e.g., `#{record.id}`)
   - List numbered step-by-step testing instructions
   - Be detailed to assist reviewers
   - **For standard flows (request creation, proposal creation, PO creation)**: do NOT spell out those steps — reviewers know them. Write "On `https://az.test/`, create a request and land on the supplier selection page" and move on to the steps specific to the feature. Never specify which service type to select.
   - **For features that depend on specific data state**: think through what database state is required to actually exercise the behavior before writing the instructions. For example, if a feature locks a value at PO time, the test must set that value before the PO is created and change it after — otherwise the test doesn't demonstrate anything. Write the console setup steps explicitly
   - **Database setup steps must use Rails console syntax** — code blocks should be copy-pastable directly into `rails c`, never wrapped in `bundle exec rails runner`. Prefix with "Open Rails console (`rails c`) and run:". Example: `provider = Pg::Provider.first; puts provider.uuid` not `bundle exec rails runner "puts Provider.first.uuid"`
   - **NEVER reference external documents or files** in the Instructions section — always write the full steps inline. Reviewers cannot access local docs files.
   - **NEVER tell the reviewer to log in** — they have their own admin account and will log in if needed. Do specify which marketplace/org to use (e.g. "On `https://az.test/`...").
   - **NEVER use `michael@scientist.com` or any specific user email** in test instructions — the reviewer will use their own account.

4. **Screenshots**
   - **Check the diff first**: run `git diff <parent-branch>...HEAD --name-only` and look for view file changes (`app/views/`, `.html.haml`, `.html.erb`, `.jsx`, `.tsx`, etc.)
   - **No view file changes** → omit the Screenshots section entirely — do NOT include it with "N/A" or any placeholder
   - **Bug fixes and hotfixes with UI changes**: ALWAYS include a before/after table:
     ```markdown
     **Screenshots**

     <table>
     <tr>
     <th>Before (Bug)</th>
     <th>After (Fixed)</th>
     </tr>
     <tr>
     <td>

     </td>
     <td>

     </td>
     </tr>
     </table>
     ```
   - **All other PRs with UI changes** (new features, migrations, refactors): also include a before/after table:
     ```markdown
     **Screenshots**

     <table>
     <tr>
     <th>Before</th>
     <th>After</th>
     </tr>
     <tr>
     <td>

     </td>
     <td>

     </td>
     </tr>
     </table>
     ```
   - User will add screenshots by editing the PR description on GitHub
   - The blank lines inside `<td>` tags are where screenshots will be inserted

**Never include the dynamic content check instruction:**
- **DO NOT include**: "Remember to ensure that these changes do not break any scripts, configuration rules, or dynamic forms (see https://github.com/scientist-hq/rx/tree/main/docs/Checking-Dynamic-Content.md for instructions)."
- Omit this boilerplate from all PR descriptions

## Editing GitHub Issues and PRs

**🚨 CRITICAL: When editing issues or PRs, ALWAYS check for edits since your last interaction and NEVER remove screenshots 🚨**

- **ALWAYS** fetch the latest version of the issue/PR body immediately before editing it
- **NEVER** assume the content hasn't changed since you first read it
- **ALWAYS** preserve all screenshots and images — even if you're updating other parts of the content
- The user may have added screenshots between when you first read it and when you're editing it

**Workflow:**
1. Fetch the current version of the issue/PR body
2. Make your changes while preserving all existing screenshots and images
3. Double-check that all screenshot URLs are preserved in your edit

## PR Creation Commands

```bash
# Basic draft PR creation (ALWAYS use --draft)
gh pr create --draft --title "Title" --body "$(cat <<'EOF'
[PR body content here]
EOF
)" --base main

# Add labels and milestone
gh pr edit [PR_NUMBER] --add-label "Label1,Label2" --milestone "Milestone Name"

# Remove incorrect labels
gh pr edit [PR_NUMBER] --remove-label "LabelName"
```
