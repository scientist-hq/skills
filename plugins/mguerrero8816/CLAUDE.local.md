# Personal Claude Instructions for Mike

This file contains personal preferences and instructions for working with this codebase.

## Clarifying Scope Before Fixing Multi-Part Queries

**🚨 CRITICAL: When a fix is described informally and the target code has multiple components, state your interpretation of exactly what changes before writing any code or specs 🚨**

Queries often have multiple distinct parts — a subquery that feeds records in, a filter that scopes the results, a JOIN that links tables, etc. A vague description like "also search for X" or "there's a hole here" could apply to any of them.

Before touching anything:
1. Identify the components of the query
2. State which one you believe needs changing: "So the fix is on the `organization_id` filter side, not the `provider_ids` subquery side — right?"
3. Wait for confirmation before writing code or specs

**Why:** In a session working on `quote_group_org_providers`, this went wrong twice in a row. The fix was only to the `organization_id` filter, but two incorrect interpretations (widening the subquery, then creating impossible test data) were fully implemented and reverted before the correct one landed.

## Explaining Chains of Causation

**🚨 CRITICAL: When explaining a chain of causation, ALWAYS include the file and line number for every step 🚨**

This applies to:
- Exception propagation (where does an error bubble up through?)
- Service call flows (what calls what?)
- Callback chains
- Any explanation of how one thing leads to another

The person asking doesn't know exactly what's going on — that's why they're asking. Always give them the full picture with file paths and line numbers so they can navigate directly to each step.

## Output Formatting

**🚨 CRITICAL: NEVER prefix code, commands, or any output with the ⏺ bullet character 🚨**

### Tables Too Wide for the Terminal

Print tables normally with full content. If the user indicates the table isn't rendering correctly (e.g. looks like a list, asks why it's not showing as a table, asks you to reprint it), that means the rows are too wide for their terminal — abbreviate file paths to just the filename and shorten cell content until it fits.

- **NEVER** use `⏺` or any similar Unicode bullet/dot as a prefix before code snippets, commands, or inline text
- Code and commands should appear without any decorative prefix characters

## Current Branch — Always Verify Live

**🚨 CRITICAL: NEVER assume the current branch from the git status snapshot at conversation start 🚨**

The git status shown at the start of a conversation is a snapshot taken before the session began and can be stale. Always run `git branch --show-current` to verify the actual current branch before making any branch-based assumptions or decisions.

- **NEVER** say "you're on branch X" based on the conversation-start snapshot alone
- **ALWAYS** run `git branch --show-current` to confirm

## Write Specs Before Making Code Changes

When a task requires a spec, write it first and confirm it fails for the right reason before making the implementation change. This ensures the spec actually validates the intended behavior and doesn't pass trivially.

## "Fix This" Means the Database

**🚨 CRITICAL: When the user asks to "fix" an error or page issue, assume the fix is in the database — NOT the code 🚨**

- **DEFAULT**: Investigate and repair data (missing records, nil associations, bad state, etc.)
- **EXCEPTION**: If the current conversation has been actively working on a related feature or code change, then a code fix may be appropriate
- **NEVER** edit code in response to "fix this" unless we are mid-feature and the fix is clearly code-related
- When in doubt, check the database first and explain what data was wrong


## Sending Commands via tmux

**🚨 CRITICAL: ALWAYS send a separate Enter after typing into a tmux pane — NEVER rely on `Enter` in the same `send-keys` call 🚨**

- **NEVER** do: `tmux send-keys -t 0:0 "some text" Enter` and expect it to submit
- **ALWAYS** follow up with a second call: `tmux send-keys -t 0:0 "" Enter`
- This applies to all Claude Code TUI sessions running in tmux

**Correct pattern:**
```
tmux send-keys -t 0:0 "your message here" Enter
tmux send-keys -t 0:0 "" Enter
```

## Bash Command Style

**🚨 CRITICAL RULE: ALWAYS chain bash commands with `&&` or `;` — NEVER use newlines inside a single Bash tool call 🚨**

- **NEVER** write multi-line scripts in a single Bash tool call (newlines trigger permission prompts)
- **ALWAYS** chain sequential commands with `&&` (stop on failure) or `;` (continue regardless)
- If commands are independent, make multiple parallel Bash tool calls instead
- Examples:
  - ❌ BAD: `cd rx\nbundle exec rspec spec/foo_spec.rb`
  - ✅ GOOD: `cd rx && bundle exec rspec spec/foo_spec.rb`


## Default User Context

**🚨 CRITICAL RULE: The user is logged in as michael@scientist.com unless otherwise specified 🚨**

**This is an absolute rule with NO exceptions:**
- When creating test data, action items, invitations, or any user-specific records, use `michael@scientist.com` as the default email
- When querying for "the current user" or "my user", use `michael@scientist.com`
- Only use a different email if the user explicitly specifies otherwise
- This applies to:
  - Creating UserActionItem records
  - Creating Pg::Invitation records
  - Creating test users or data for demonstration
  - Any database queries that need a user context

**Examples:**
- ✅ GOOD: `UserActionItem.create(email: 'michael@scientist.com', ...)`
- ❌ BAD: `UserActionItem.create(email: 'michael+user@scientist.com', ...)` (unless explicitly requested)
- ✅ GOOD: `user = Pg::User.find_by(email: 'michael@scientist.com')`

## Repository Notes

- Repository was renamed from `assaydepot/rx` to `scientist-hq/rx`
- Git remote should point to `git@github.com:scientist-hq/rx.git`

## Project Structure

**🚨 CRITICAL RULE: Bundle commands MUST be run from the rx subfolder 🚨**

**This is an absolute rule with NO exceptions:**
- The Rails application lives in `/Users/mike/rx/rx/` (note the nested `rx` directory)
- **ALWAYS** `cd` into the `rx` subfolder before running any `bundle` commands
- This applies to:
  - `bundle exec rails`
  - `bundle exec rspec`
  - `bundle exec rubocop`
  - `bundle exec rails runner`
  - Any other `bundle exec` command

**Examples:**
- ❌ BAD: `bundle exec rails runner "..."` (from `/Users/mike/rx`)
- ✅ GOOD: `cd rx && bundle exec rails runner "..."` (from `/Users/mike/rx`)
- ✅ GOOD: Just run `bundle exec rails runner "..."` if already in `/Users/mike/rx/rx`


## Verify Views in Browser Before Making Changes

**🚨 CRITICAL: When asked to change something in a view, ALWAYS provide the URL and verify the current state in the browser before making any edits 🚨**

**This is an absolute rule with NO exceptions:**
- **ALWAYS** provide a working URL to the relevant page first
- **ALWAYS** open the page in the browser and confirm what is currently visible
- **NEVER** make view edits based solely on reading the template — verify the live rendered output first
- This catches wrong branches, missing test data, feature flags, and cached states before you waste an edit

**Workflow:**
1. Identify the URL for the view being changed
2. Navigate to it in the browser
3. Confirm the relevant UI element is visible and note its current state
4. Then make the code change
5. Reload and verify the change took effect

## Making Conditions True or False

**🚨 CRITICAL: When asked to make a line/condition true or false, ALWAYS manipulate database data, NEVER edit code 🚨**

**This is an absolute rule with NO exceptions:**
- **NEVER** edit view files, controller logic, or conditional statements
- **ALWAYS** update database records to make conditions evaluate as requested
- Read the conditional logic to understand what data is needed
- Use `bundle exec rails runner` to create, update, or delete database records

**Examples:**
- User: "make line 26 true" → Read line 26, understand the condition, then create/update database records so the condition evaluates to true
- User: "make this condition false" → Update database to make the condition evaluate to false
- User: "can you add data so this shows up" → Create the necessary database records

**Workflow:**
1. Read the code to understand the condition
2. Identify what database state is required
3. Update the database accordingly
4. Verify the condition now evaluates as expected





## Test Documents

**Test docs are stored at `/Users/mike/test_docs/`. When creating manual test documents or the user mentions "test doc", always save to that directory — NEVER inside the repo.**






## Ruby Code Standards


















