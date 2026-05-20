# Personal Claude Instructions for Mike

This file contains personal preferences and instructions for working with this codebase.

## Where to Put Rules

**🚨 CRITICAL: When adding new rules derived from reviewing a process, put them in the most appropriate file — not CLAUDE.local.md by default 🚨**

- **Spec writing rules** → `.claude/commands/spec-rules.md`
- **PR rules** → `.claude/commands/pr-rules.md`
- **Personal workflow preferences** → `CLAUDE.local.md`
- **Narrow/derived rules** (apply only in a specific context, not broadly) → create a new focused rules file in `.claude/commands/` (e.g. `fee-cap-rules.md`, `billing-rules.md`) and load it with a slash command
- Only add to `CLAUDE.local.md` if there is no more specific home for the rule
- Derived rules from process reviews generally do NOT apply broadly — default to a new focused file over adding to an existing broad one
- **NEVER edit `CLAUDE.md`** — it is a shared file checked into the repo and owned by the team

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

## Banned Slash Commands

**🚨 CRITICAL: NEVER use any of the following slash commands 🚨**

- **NEVER** invoke `/architect`, `/bug`, `/bump`, `/commit`, `/explain`, `/explore`, `/implement`, `/infra`, `/learn`, `/post-review`, `/pr`, `/qa`, `/recap`, `/review`, or `/test`
- These commands exist in `.claude/commands/` but must not be used under any circumstances
- This applies even if the task seems like a perfect match for one of these commands

## Memory

**🚨 CRITICAL: NEVER save memories 🚨**

- **NEVER** use the memory system to save notes, feedback, or context
- Use `CLAUDE.local.md` or `CLAUDE.md` for persistent instructions instead
- If the user asks you to remember something, add it to `CLAUDE.local.md`

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


## Generating URLs

**🚨 CRITICAL: When asked for a URL, ALWAYS provide a live, working URL with actual database records 🚨**

**This is an absolute rule with NO exceptions:**
- **NEVER** provide placeholder URLs like `/providers/#{provider.uuid}/...`
- **NEVER** provide instructions on how to generate URLs
- **ALWAYS** search the database for actual records and construct complete, working URLs
- Use `bundle exec rails runner` to query the database for real UUIDs, IDs, or other identifiers
- Return the full URL that can be immediately copied and pasted into a browser

**URL Format Rules:**
- ❌ INCORRECT: `https://storefront.test/` is NOT a valid storefront URL
- ✅ CORRECT: `https://{subdomain}.test/` (e.g., `https://az.test/`)
- Storefront URLs use organization subdomains, not a generic "storefront" subdomain
- ✅ CORRECT: `https://backoffice.test/` for backoffice URLs

**Examples:**
- ❌ BAD: "Visit `/providers/#{provider.uuid}/proposal_templates`"
- ❌ BAD: "Visit `https://storefront.test/delayed_user_reports`"
- ✅ GOOD: "Visit `https://backoffice.test/providers/e0b473d2-23af-46b6-9b0d-de5de272afbd/proposal_templates`"
- ✅ GOOD: "Visit `https://az.test/delayed_user_reports`"

**Storefront vs Backoffice URL Routing:**
- `/quote_groups/` — **storefront** — use `https://{subdomain}.test/quote_groups/...`
- `/providers/` — **backoffice** — use `https://backoffice.test/providers/...`
- When in doubt, check whether the controller lives under `app/controllers/backoffice/` (backoffice) or not (storefront)
- To get the subdomain, query `record.organization.subdomain` and use `https://{subdomain}.test/...`

**When the user says "give me a url" or similar:**
1. Query the database for actual records
2. Determine if the page is storefront or backoffice (see routing rules above)
3. Construct the complete URL with real data
4. Use the correct domain pattern (subdomain.test for storefront, backoffice.test for backoffice)
5. Provide the URL ready to use

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

## Migrations — Timestamp Must Be Real

**🚨 CRITICAL: ALWAYS use the actual current UTC time as the migration timestamp — NEVER use a placeholder 🚨**

**This is an absolute rule with NO exceptions:**
- **NEVER** use fake timestamps like `20260513000001` or any midnight/round-number timestamp
- **ALWAYS** run `date -u +%Y%m%d%H%M%S` first and use that value as the filename prefix
- Placeholder timestamps risk colliding with a teammate's migration and breaking the migration order

**Correct workflow:**
1. Run `date -u +%Y%m%d%H%M%S` to get the current UTC timestamp
2. Use that exact value as the migration filename prefix
3. Example: `20260513160855_create_preferred_quote_group_providers.rb`

## Migrations — Cleaning Up `schema.rb` After Running Migrations

**The dev database is shared and may contain migrations from unmerged branches being reviewed locally. Running `db:migrate` will apply those too, adding unrelated tables and columns to `schema.rb`.**

When `schema.rb` has unrelated changes after running a migration:
- **DO NOT** re-run `db:migrate` on a reset schema — it will just re-apply everything again
- **ALWAYS** clean `schema.rb` manually: compare against `main`, identify exactly what your migration adds (new table, new indexes, new FK entries, version bump), and revert everything else
- Use `git diff main -- db/schema.rb` (working tree) to see the full picture, not `git diff main...HEAD` (which compares commits)

## Migrations — `t.references` on Legacy Serial Tables

**Do NOT use `t.references` when creating foreign keys pointing at legacy `id: :serial` (integer) tables**

Modern Rails defaults both `create_table` PKs and `t.references` columns to `bigint`. Legacy tables in this codebase (e.g. `providers`, `quote_groups`) were created with `id: :serial` — a 4-byte `integer`. PostgreSQL requires the FK column type to match the referenced PK type exactly, so a `bigint` FK against an `integer` PK will fail with a type mismatch error.

- **ALWAYS** use `t.integer :xxx_id, null: false` for FK columns on legacy serial tables
- Check `db/schema.rb` for `id: :serial` to confirm a table is legacy before deciding

## Database Operations and Search Indexing

**🚨 CRITICAL RULE: NEVER use database operations that bypass ActiveRecord callbacks and skip reindexing 🚨**

**This is an absolute rule with NO exceptions:**
- **NEVER** use `update_all`, `delete_all`, `insert_all`, or other bulk SQL operations on models that use Searchkick
- These methods bypass ActiveRecord callbacks, which means Elasticsearch indexes won't be updated
- The database and search index will become out of sync, causing incorrect search results
- **ALWAYS** use individual record operations (`update`, `save`, `destroy`, etc.) or manually reindex after bulk operations

**Problematic methods to AVOID:**
- `Model.update_all(...)` - bypasses callbacks, no reindex
- `Model.delete_all` - bypasses callbacks, no reindex
- `Model.insert_all(...)` - bypasses callbacks, no reindex
- Direct SQL via `ActiveRecord::Base.connection.execute(...)`

**Safe alternatives:**
- ✅ GOOD: `records.each { |r| r.update!(field: value) }` - triggers callbacks and reindexing
- ✅ GOOD: `record.update!(field: value)` - triggers callbacks and reindexing
- ✅ GOOD: `record.destroy` - triggers callbacks and reindexing
- ✅ ACCEPTABLE: `Model.update_all(...) followed by Model.reindex` - but prefer individual updates

**When you MUST use bulk operations:**
1. Use the bulk operation
2. Immediately reindex the model: `Model.reindex`
3. Verify the search index is updated

**Examples:**
- ❌ BAD: `Pg::Certification.where(name: 'Test').update_all(region: 'au')`
- ✅ GOOD: `Pg::Certification.where(name: 'Test').each { |c| c.update!(region: 'au') }`
- ✅ ACCEPTABLE: `Pg::Certification.where(name: 'Test').update_all(region: 'au'); Pg::Certification.reindex`

**Why this matters:**
- Searchkick (Elasticsearch) relies on ActiveRecord callbacks to stay in sync
- Bulk operations skip callbacks for performance, but break search functionality
- Users see incorrect/incomplete search results when indexes are out of sync
- Individual operations are slower but guarantee consistency

## Insert-or-Skip with Composite Unique Indexes

**🚨 CRITICAL: Use `Model.insert` with `unique_by` for atomic "create if not exists" operations — NEVER `find_or_create_by!` or bare `upsert` 🚨**

This rule applies to **call sites** — the code that creates records. It does NOT apply to model-level `validates :uniqueness`, which is standard Rails convention and correct to have alongside a DB unique index.

- `find_or_create_by!` is non-atomic — two concurrent calls can both pass the find check, then one raises `ActiveRecord::RecordNotUnique` on create
- `upsert` without `unique_by` targets the primary key, not composite unique indexes — conflicts on composite indexes still raise
- **ALWAYS** use `Model.insert(attrs, unique_by: %i[col1 col2])` for composite unique indexes — generates `ON CONFLICT (col1, col2) DO NOTHING`
- `validates :uniqueness` on the model is fine and expected — it provides friendly error messages; the DB constraint enforces atomicity

**Examples:**
- ❌ BAD: `PreferredQuoteGroupProvider.find_or_create_by!(quote_group: qg, provider: p)` — non-atomic, raises on race
- ❌ BAD: `PreferredQuoteGroupProvider.upsert({ quote_group_id: qg.id, provider_id: p.id })` — targets PK, not composite index
- ✅ GOOD: `PreferredQuoteGroupProvider.insert({ quote_group_id: qg.id, provider_id: p.id }, unique_by: %i[quote_group_id provider_id])`
- ✅ GOOD: `validates :provider_id, uniqueness: { scope: :quote_group_id }` — standard model validation, not a concern

## Creating Test Users

**🚨 CRITICAL RULE: When creating test users, ALWAYS use the password !Testing1234 🚨**

**This is an absolute rule with NO exceptions:**
- **ALWAYS** set user passwords to `!Testing1234`
- This password meets all security requirements:
  - 12 characters or longer
  - Contains uppercase letters
  - Contains lowercase letters
  - Contains digits
  - Contains special characters
- Using a consistent password makes testing easier for the user

**Examples:**
```ruby
user = Pg::User.create!(
  email: 'test@example.com',
  password: '!Testing1234',
  password_confirmation: '!Testing1234',
  # ... other attributes
)
```


## Test Documents

**Test docs are stored at `/Users/mike/test_docs/`. When creating manual test documents or the user mentions "test doc", always save to that directory — NEVER inside the repo.**

## Playwright Screenshots

**🚨 CRITICAL: ALWAYS save Playwright screenshots to `/Users/mike/playwright_screenshots/` — NEVER save them inside the repo 🚨**

This applies to any screenshot taken via `browser_take_screenshot` or any other Playwright screenshot tool.

## Background Jobs

### Queue Assignment
- **Do NOT add `queue_as` to new jobs** — the majority of jobs in the codebase omit it and rely on the default queue
- Only specify a queue if there is a specific, known reason (e.g. high memory jobs like data imports use `:high_memory`)
- Do not flag missing `queue_as` as an issue during code reviews

## JavaScript Code Standards

### ESLint Strict Equality Rule
- **ALWAYS use strict equality**: Use `===` and `!==` instead of `==` and `!=` in JavaScript code
- **NEVER use loose equality**: The `==` operator will fail eslint checks with the `eqeqeq` rule
- **Check existing code patterns**: If copying code from existing files, update `==` to `===` even if the source uses loose equality

### ESLint No-New Rule
- **🚨 CRITICAL: NEVER use `new` constructors for side effects without assigning to a variable**
- **ALWAYS assign constructor results to a variable**, even if you don't use the variable afterward
- The `no-new` ESLint rule will fail if constructors are called without assignment

**Examples:**
- ❌ BAD: `new bootstrap.Dropdown(element, options);`
- ✅ GOOD: `const dropdown = new bootstrap.Dropdown(element, options);`
- ❌ BAD: `new Modal(config);`
- ✅ GOOD: `const modal = new Modal(config);`

**When suggesting or writing JavaScript code:**
- Any use of `new` MUST be assigned to a `const` or `let` variable
- This applies to Bootstrap components, custom classes, or any constructor
- Even if the variable isn't used later, it must be assigned

## ActiveStorage

### No Silent File Replacement
- **NEVER purge and replace an attached file unless the user explicitly asks for replacement behaviour**
- If a file is already attached when an attach is attempted, log an error and skip — do not silently overwrite
- Guard against double-attachment at the earliest possible point (e.g. top of the method that orchestrates the operation)

**Examples:**
- ❌ BAD:
  ```ruby
  @document.file.purge if @document.file.attached?
  @document.file.attach(...)
  ```
- ✅ GOOD:
  ```ruby
  if @document.file.attached?
    Rails.logger.error("[MyClass] file already attached for document=#{@document.uuid} — skipping")
  else
    @document.file.attach(...)
  end
  ```

## Namespacing — Never Add New Models to `app/models/pg/`

**🚨 CRITICAL RULE: NEVER create new model files under `app/models/pg/` 🚨**

**This is an absolute rule with NO exceptions:**
- `app/models/pg/` is a legacy directory — new models go top-level or in a purpose-specific subdirectory
- **NEVER** place a new model file under `app/models/pg/`
- Referencing existing `Pg::` classes is fine — the ban is on creating new ones in that directory

**Exception — configuration rule directives:**
- Directives live in `app/models/configuration/pg/` and **all** use the `Pg::` namespace — follow that convention for new directives
- ✅ GOOD: `class Pg::PreferredProviderDirective < Pg::Directive` in `app/models/configuration/pg/preferred_provider_directive.rb`

## Rails Model Standards

### `belongs_to` — Always Check `belongs_to_required_by_default`

This app sets `config.active_record.belongs_to_required_by_default = false` in `config/application.rb`. This means `belongs_to` associations do **not** validate presence by default.

- **ALWAYS add `optional: false`** to `belongs_to` associations where nil should never be allowed
- Without it, a record with a nil FK will pass model validation and only fail at the DB constraint level (worse error messages, harder to debug)

**Examples:**
- ❌ BAD: `belongs_to :quote_group, class_name: 'Pg::QuoteGroup'`
- ✅ GOOD: `belongs_to :quote_group, class_name: 'Pg::QuoteGroup', optional: false`

### `has_many` in Namespaced Models — Always Specify `class_name` for Top-Level Models

When adding `has_many` inside a namespaced model (e.g. `Pg::QuoteGroup`, `Pg::Provider`), Rails resolves the association class by prepending the current namespace first. A `has_many :preferred_quote_group_providers` inside `Pg::QuoteGroup` will try `Pg::PreferredQuoteGroupProvider` before falling back to `PreferredQuoteGroupProvider`.

- **ALWAYS add `class_name:`** when the associated model lives in a different namespace than the declaring model
- This applies in both directions: `belongs_to` pointing *into* a namespace, and `has_many` pointing *out* to a top-level model

**Examples:**
- ❌ BAD: `has_many :preferred_quote_group_providers, dependent: :destroy` (inside `Pg::QuoteGroup`)
- ✅ GOOD: `has_many :preferred_quote_group_providers, class_name: 'PreferredQuoteGroupProvider', dependent: :destroy`

## Ruby Code Standards

### Symbol Arrays — Always Use `%i[]`

- **ALWAYS use `%i[]`** for arrays of symbols — never `[:foo, :bar]`
- This applies everywhere: migrations, model code, specs, anywhere a symbol array appears
- Rubocop enforces this with `Style/SymbolArray`

**Examples:**
- ❌ BAD: `add_index :table, [:quote_group_id, :provider_id]`
- ✅ GOOD: `add_index :table, %i[quote_group_id provider_id]`

### Method Naming — Keep It Short
- **ALWAYS choose the shortest name that clearly conveys intent**
- Avoid restating the subject, type, or surrounding context in the name — the class and location already provide that
- If a name is longer than ~4 words, look for a shorter equivalent before committing to it

**Examples:**
- ❌ BAD: `manual_fee_cap_amount_not_below_historical_cap`
- ✅ GOOD: `validate_fee_cap_floor`
- ❌ BAD: `check_if_commission_fee_cap_exceeds_historical_value`
- ✅ GOOD: `commission_over_cap?`

### Model Method Ordering
- **ALWAYS follow this order in Rails models:**
  1. `include` / `extend`
  2. `attr_reader` / `attr_writer` / `attr_accessor`
  3. Associations (`belongs_to`, `has_many`, etc.)
  4. Validations
  5. Scopes
  6. Instance methods (including `to_param`)
- **NEVER place `to_param` or other instance methods before scopes**

### attr_reader/attr_writer/attr_accessor Placement
- **ALWAYS place `attr_reader`, `attr_writer`, and `attr_accessor` at the top of the class**, alongside other class-level declarations like `include`, `extend`, and `delegate`
- **NEVER place them at the bottom of the file or after method definitions**

### No Combined Assignment and Control Flow
- **NEVER combine a variable assignment with a control flow keyword (`break`, `return`, `next`) on the same line**
- Always assign the variable on its own line first, then call the control flow keyword on the next line

**Examples:**
- ❌ BAD: `break current_value = nil`
- ❌ BAD: `return result = some_method`
- ✅ GOOD:
  ```ruby
  current_value = nil
  break
  ```

### No Ternary Operators
- **NEVER use ternary operators (`condition ? a : b`)** — always use `if/else` instead
- This applies to Ruby and JavaScript/CoffeeScript
- **Exception**: Ternaries are acceptable inside scope lambdas/blocks where the `if/else` alternative would require significantly more lines and hurt readability due to placement context

**Examples:**
- ❌ BAD: `obj.is_a?(Hash) ? obj[segment] : obj.public_send(segment)`
- ✅ GOOD:
  ```ruby
  if obj.is_a?(Hash)
    obj[segment]
  else
    obj.public_send(segment)
  end
  ```
- ✅ ACCEPTABLE (scope lambda): `scope :for_trigger, ->(source, action) { active.where(organization: source.respond_to?(:organization) ? source.organization : nil) }`

### No Guard Clauses with `return unless` / `return if`
- **NEVER use `return unless` or `return if` as guard clauses** — always use an `if` block instead
- This applies to Ruby only

**Examples:**
- ❌ BAD: `return unless @document.source.respond_to?(:quote_group)`
- ❌ BAD: `return if record.nil?`
- ✅ GOOD:
  ```ruby
  if @document.source.respond_to?(:quote_group)
    # ...
  end
  ```
- ✅ GOOD:
  ```ruby
  if record.present?
    # ...
  end
  ```

### Hash Alignment (Layout/HashAlignment)
- **NEVER use extra padding spaces to align hash values** — this violates rubocop's `Layout/HashAlignment` rule
- Each key-value pair should use a single space after the colon, with no additional padding to align values across keys

**Examples:**
- ❌ BAD:
  ```ruby
  {
    name:         'foo',
    long_key:     'bar',
    another_key:  'baz'
  }
  ```
- ✅ GOOD:
  ```ruby
  {
    name: 'foo',
    long_key: 'bar',
    another_key: 'baz'
  }
  ```

### No Backslash String Line Continuation
- **NEVER split strings across lines using `\` (backslash continuation)** — just write the full string on one line
- This applies to log messages, error strings, and any other string literals
- Long lines are acceptable — do not break strings to fit within a line length limit

**Examples:**
- ❌ BAD:
  ```ruby
  Rails.logger.error(
    "[MyClass] something went wrong for " \
    "id=#{record.id} status=#{record.status}"
  )
  ```
- ✅ GOOD:
  ```ruby
  Rails.logger.error(
    "[MyClass] something went wrong for id=#{record.id} status=#{record.status}"
  )
  ```

### Variable Assignment Alignment
- **NEVER add extra padding spaces to align variable assignment values** — this violates rubocop's `Layout/ExtraSpacing` rule
- Each assignment should use a single space around `=`, with no additional padding to align values across multiple assignments

**Examples:**
- ❌ BAD:
  ```ruby
  proposal    = @document.source
  quoted_ware = proposal.quoted_ware
  quote_group = quoted_ware.quote_group
  ```
- ✅ GOOD:
  ```ruby
  proposal = @document.source
  quoted_ware = proposal.quoted_ware
  quote_group = quoted_ware.quote_group
  ```
- ❌ BAD:
  ```ruby
  NAVY     = '1f356f'
  CYAN     = '6fceb9'
  LABEL_BG = 'eff3f5'
  ```
- ✅ GOOD:
  ```ruby
  NAVY = '1f356f'
  CYAN = '6fceb9'
  LABEL_BG = 'eff3f5'
  ```

### No Assigning the Result of a Conditional Block to a Variable
- **NEVER write `variable = if condition ... end`** — assign inside each branch instead
- This applies to `if/else`, `case/when`, and any other conditional block

**Examples:**
- ❌ BAD:
  ```ruby
  dv = if has_history
    current_dv.paper_trail.version_at(timestamp) || current_dv
  else
    current_dv
  end
  ```
- ✅ GOOD:
  ```ruby
  if has_history
    dv = current_dv.paper_trail.version_at(timestamp) || current_dv
  else
    dv = current_dv
  end
  ```

### Single-Line Conditionals (Style/IfUnlessModifier)
- **ALWAYS use modifier form** when a conditional has only one line in its body — rubocop enforces this with `Style/IfUnlessModifier`
- Write `expression if condition` or `expression unless condition` instead of a multi-line `if/end` block

**Examples:**
- ❌ BAD:
  ```ruby
  if record.present?
    do_something
  end
  ```
- ✅ GOOD:
  ```ruby
  do_something if record.present?
  ```
- ❌ BAD:
  ```ruby
  unless user.admin?
    redirect_to root_path
  end
  ```
- ✅ GOOD:
  ```ruby
  redirect_to root_path unless user.admin?
  ```

### Parallel Array Building — Prefer Explicit Init + Shovel Over `each_with_object`

When building two parallel arrays from a single collection in one pass, declare the arrays first and shovel into them — do not use `each_with_object` with destructured accumulators.

**Examples:**
- ❌ BAD (too compact, hard to read):
  ```ruby
  names, ids = items.each_with_object([[], []]) do |item, (n, i)|
    n << item.name
    i << item.id
  end
  ```
- ✅ GOOD:
  ```ruby
  names = []
  ids = []
  items.each do |item|
    names << item.name
    ids << item.id
  end
  ```

### Local Variables That Shadow Method Names — Prefix With Context

When a local variable name would shadow a same-class method name, prefix the local variable to make the distinction clear.

**Examples:**
- ❌ BAD: `provider_names = []` inside a method that also defines `def provider_names`
- ✅ GOOD: `note_provider_names = []` — the prefix makes it clear this is a local, not the method

### Nil/Empty Array Checks — Use `present?` in Views, Not `presence` in Models

When a view needs to distinguish between a populated array and an empty one, check `collection.present?` in the view — do not call `.presence` on the array in the model to coerce `[]` to `nil`.

**Examples:**
- ❌ BAD: `providers: provider_names.presence` in a model method, then `- if file[:providers]` in a view
- ✅ GOOD: `providers: provider_names` in the model, then `- if file[:providers].present?` in the view

## Browser Automation Skills

Personal skills for automating browser tasks in the local dev environment. These live in `~/.claude/skills/` and are not in the repo.

**`/playwright-qa`** — base Playwright skill (`~/.claude/skills/playwright-qa/SKILL.md`)
- Knows all dev credentials, org subdomains, and login flows
- Use for general multi-step browser automation
- Other browser skills build on this one

**`/storefront-index`** — open the storefront index (`~/.claude/skills/storefront-index/SKILL.md`)
- Use when the user says "open the storefront", "go to az.test", "open the [org] storefront", etc.
- Defaults to `az` if no org is specified
- ALWAYS use this skill instead of `playwright-qa` when the task is just opening the storefront index

**`/storefront-create-request`** — create a new request from the storefront (`~/.claude/skills/storefront-create-request/SKILL.md`)
- Use when the user wants to create a request or search for a service on the storefront
- Opens the storefront index first, then searches "hbs" and selects Human Biological Samples
- Builds on storefront-index

**`/open-proposal-form`** — open the new proposal form (`~/.claude/skills/open-proposal-form/SKILL.md`)
- Use when the user wants to open a proposal form, inspect it, or get to the proposal creation page
- Starts from the storefront request page: sends to suppliers → opens backoffice → selects a quoted ware → clicks Start Proposal
- Stops at the open blank form and reports the URL — does NOT fill or submit

**`/create-proposal`** — fill and submit a proposal (`~/.claude/skills/create-proposal/SKILL.md`)
- Use when the user wants to create and submit a full proposal (SOW, fees, line items)
- Builds on open-proposal-form to get to the form, then fills and submits it

**`/create-purchase-order`** — create a purchase order from a proposal (`~/.claude/skills/create-purchase-order/SKILL.md`)
- Use when the user wants to create a purchase order or complete the PO workflow
- Builds on create-proposal, then returns to the storefront request page to initiate the PO

**`/create-change-order`** — create a change order against an existing PO (`~/.claude/skills/create-change-order/SKILL.md`)
- Use when the user wants to create a change order or modify scope on an in-progress request
- Builds on send-po-to-netsuite; action is in the backoffice quoted ware sidebar, not the storefront

**`/send-po-to-netsuite`** — send a PO to NetSuite (`~/.claude/skills/send-po-to-netsuite/SKILL.md`)
- Use when the user wants to send a PO to NetSuite or sync a purchase order
- Goes to `backoffice/accounting/purchase_orders`, finds the PO, opens Actions → Send → Send Purchase Order & Sales Order to Netsuite
- Note: AZ org will fail with `customerLegalEntity` error in dev — use an org with NetSuite configured (e.g. BMS) for a full end-to-end test

**🚨 CRITICAL: ALWAYS run `/storefront-index` when the user wants to open or navigate to a storefront — do NOT use playwright-qa directly for this task 🚨**

**🚨 CRITICAL: ALWAYS run `/storefront-create-request` when the user wants to create a request from the storefront 🚨**

**🚨 CRITICAL: ALWAYS run `/open-proposal-form` when the user wants to open or inspect the proposal form — do NOT use create-proposal if the user only wants to open the form 🚨**

**🚨 CRITICAL: ALWAYS run `/create-proposal` when the user wants to create and submit a complete proposal 🚨**

**🚨 CRITICAL: ALWAYS run `/create-purchase-order` when the user wants to create a purchase order 🚨**

## CSS `text-decoration` on Child Inline Elements

When you need to hide the underline on a specific child inline element inside an `<a>` tag, `text-decoration: none` on the child does **not** work — the underline is drawn by the parent's box and passes through all children regardless.

The correct approach:
1. Set `text-decoration: underline` on the child (so it owns its own underline segment)
2. Set `text-decoration-color: <background-hex>` to make that segment invisible

**Examples:**
- ❌ BAD: `style: "text-decoration: none;"` on a child `<i>` inside an `<a>` — has no effect
- ✅ GOOD: `style: "text-decoration: underline; text-decoration-color: #f2f2f2;"` — child owns its segment and colors it to match the background

Look up the exact background color hex before hardcoding it (e.g. `neutral-95` = `#f2f2f2`).

## View Loop Membership Checks — Use Controller-Level `pluck`

When a view needs to check whether each row in a loop belongs to a set (e.g. "is this provider preferred?"), default to loading the full set once in the controller via `pluck` into an instance variable, then check membership in the view.

- ❌ BAD: Model methods that query per row (N+1), or methods that take two IDs when one object already implies the other
- ✅ GOOD: `@preferred_provider_ids = PreferredQuoteGroupProvider.where(quote_group: @quote_group).pluck(:provider_id)` in the controller, then `@preferred_provider_ids&.include?(quoted_ware.provider_id)` in the view

Only reach for a model method if the membership logic is complex enough to warrant encapsulation.

## Backoffice URL for a Request (Quoted Ware)

**🚨 CRITICAL RULE: When asked for the backoffice page for a request, use `/quoted_wares/:uuid/edit` 🚨**

- The backoffice page for a request (quoted ware) is at `https://backoffice.test/quoted_wares/:uuid/edit`
- Use the quoted ware's **UUID**, not its numeric `id`
- This is the edit page — it shows invoices, credits, and other request details side by side
- ❌ BAD: `https://backoffice.test/quoted_wares/10` (numeric id, show action)
- ✅ GOOD: `https://backoffice.test/quoted_wares/589762de-6915-48e8-a6a4-c1d3ca244d9c/edit` (UUID, edit action)
