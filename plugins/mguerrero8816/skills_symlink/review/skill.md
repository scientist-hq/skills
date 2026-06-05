---
description: Reviews a pull request — multi-agent dispatch for your own PRs, streamlined checklist for teammates' PRs.
---

# Review Pull Request

**🚨 SUBAGENT GUARD: If you were launched via the Agent tool as a subagent, do NOT follow the multi-agent dispatch instructions below. Proceed directly to Step 1 and perform the review yourself. Dispatching further agents from a subagent causes infinite recursion. 🚨**

This command reviews pull requests. The type of review depends on whether the PR is yours or belongs to another team member.

## Multi-Agent Dispatch (Primary Agent Only)

When the primary agent (directly responding to the user) is asked to review a PR, invoke `Skill(subagent-bootstrap)` and `Skill(bash)` to load their contents, then dispatch 2 agents in parallel using the Agent tool:

1. **Security & data safety** — authorization gaps, XSS, SQL injection, IDOR, mass assignment, data integrity risks, sensitive data exposure
2. **General review** — holistic review of the PR: logic, correctness, edge cases, performance, N+1 queries, Rails conventions, test coverage, migration safety

Collect both results and present them to the user, grouped by agent, with a rolled-up summary table at the end sorted by severity.

Each agent prompt must include:
- The PR URL or number
- Its specific focus
- The instruction: "You are a subagent. Do not dispatch further agents — perform the review yourself."
- The full contents of the `subagent-bootstrap` skill at the top
- The full contents of the `bash` skill under a "## Bash Rules" section

## Step 1: Determine PR Ownership

**First, check who authored the PR:**

1. Use `gh pr view [PR_NUMBER]` to fetch PR details
2. Check the author field
3. Compare against the user's identity:
   - Email: `michael@scientist.com`
   - Names: `Michael`, `Mike`, `Michael Gorsuch`

## Step 2: Choose Review Type

### If the PR is the user's (authored by Michael/Mike):

**Review BOTH code implementation AND formatting:**

**A. Code Review (same as below)**
**B. Formatting Review:**
- Run `base-rules.md` to load all PR formatting rules
- Check that the PR follows all rules from `base-rules.md`:
  - Is it a draft PR?
  - Does it have the correct title format?
  - Does it have appropriate labels?
  - Does the description follow the required sections?
  - Are test instructions complete?
  - Are URLs using the correct base domain?
  - Is the screenshot table present?
- Provide feedback on any formatting issues or missing elements

### If the PR is NOT the user's (authored by someone else):

**Review ONLY the code implementation (skip formatting):**

1. **Fetch PR Details**
   ```bash
   gh pr view [PR_NUMBER]
   gh pr diff [PR_NUMBER]
   ```

2. **Review Code Changes**
   - **Logic & Correctness**: Does the code do what it claims to do?
   - **Bugs & Edge Cases**: Are there any obvious bugs or unhandled edge cases?
   - **Patterns & Conventions**: Does it follow RX codebase patterns?
   - **Security**: Any potential security vulnerabilities (XSS, SQL injection, etc.)?
   - **Performance**: Any N+1 queries or performance issues?
   - **Testing**: Are specs adequate? Are edge cases tested?
   - **Error Handling**: Are errors handled appropriately?

3. **Check RX-Specific Patterns**
   - Business logic in services, not models
   - View logic in presenters
   - Using Stimulus for JavaScript (not legacy patterns)
   - ActiveStorage for file uploads (not Paperclip)
   - Proper indexing on foreign keys
   - Money gem for currency handling
   - Following strong_migrations patterns

4. **Review Against CLAUDE.md Guidelines**
   - Does it follow the documented patterns in `/Users/mike/rx/CLAUDE.md`?
   - Does it use the correct gems and libraries?
   - Are new files in the right locations?

5. **Provide Constructive Feedback**
   - Point out specific issues with file paths and line numbers
   - Suggest improvements with code examples
   - Highlight potential bugs or edge cases
   - Recommend better patterns if applicable
   - Note any breaking changes or migration concerns

## Important Notes

**Always review code implementation:**
- Review the actual code changes for ALL PRs (yours and others)
- Check for bugs, edge cases, performance issues, security concerns
- Verify adherence to RX patterns and conventions

**Only review formatting for your own PRs:**
- For PRs authored by Michael/Mike, also check PR formatting
- For other people's PRs, skip formatting review entirely
- Other developers may have different formatting preferences

**Be thorough but constructive:**
- Provide specific file paths and line numbers
- Explain WHY something is an issue, not just that it is
- Suggest alternatives when pointing out problems
- Acknowledge good patterns when you see them

**Before flagging a missing registry entry, verify the live UI's data source:**
- Constants like `DIRECTIVE_NAMES` may only drive legacy forms — the BS5 UI may use a different data source (e.g. `available_type_options`)
- Before flagging a missing entry in any registry or constant, trace the actual controller action and view that serves the live page
- Do not flag a gap in a registry if the live UI doesn't read from that registry

**Don't flag pre-existing intentional patterns as bugs:**
- If a pattern has a comment explaining it (e.g. `# Allow use of any of the PO methods`) or is clearly established across the codebase, it is not a bug introduced by the PR — skip it
- Only flag things that the PR itself introduced or changed

**A DB query in an AJAX endpoint is not an N+1:**
- Each AJAX request is a fresh controller action — there is no "outer loop" to escape
- Replacing a targeted query with `pluck` + in-memory `include?` saves nothing; both hit the DB once per request
- Only flag N+1s where a query fires inside a loop within a single request

**A constant's home is valid if its namespace communicates meaning:**
- A CSS/icon constant on a model is not automatically wrong — if every call site references it as `ModelName::CONSTANT` and that name describes what it represents, the namespace is doing useful work
- Only flag constant placement if the location is genuinely confusing or causes a coupling problem

**Never flag potential Rubocop violations:**
- Do NOT note style issues, spacing, naming, or any other concern that Rubocop would catch
- Rubocop runs automatically when the PR is opened and will surface those issues itself
- Only flag things Rubocop cannot catch: logic bugs, design concerns, missing error handling, performance issues, security vulnerabilities, test coverage gaps

## Examples

### Reviewing your own PR:
```
Reviewing PR #12345 by Michael...

**Code Review:**

✅ Overall implementation looks solid!

**Potential N+1 Query (app/controllers/backoffice/providers_controller.rb:45)**
```ruby
@providers.each do |provider|
  provider.certifications.count  # N+1 query
end
```
Suggestion: Add `.includes(:certifications)` to the initial query on line 42.

**Edge Case (app/services/provider_updater.rb:78)**
Should handle the case where `provider.legacy_id` is nil for newly created providers.

---

**Formatting Review:**

1. ✅ Created as draft - good!
2. ❌ Missing "Backoffice" label - should be added since changes are in backoffice/
3. ❌ User Impact section is too brief - should specify which user types are affected
4. ✅ Screenshot table is present
5. ❌ Test instructions use placeholder syntax but should reference actual records per CLAUDE.local.md

Suggested fixes:
- Add "Backoffice" label
- Expand User Impact to specify "Scientist Admins managing providers"
- Update test instructions to use actual provider UUIDs
```

### Reviewing someone else's PR:
```
Reviewing PR #12346 by Jane...

**Code Review:**

Overall approach looks good, but found a few concerns:

**Potential N+1 Query (app/controllers/backoffice/providers_controller.rb:45)**
```ruby
@providers.each do |provider|
  provider.certifications.count  # N+1 query
end
```
Suggestion: Add `.includes(:certifications)` to the initial query on line 42.

**Missing Edge Case Handling (app/services/provider_updater.rb:78)**
The service doesn't handle the case where `provider.legacy_id` is nil. This could cause issues for newly created providers.

**Security Concern (app/views/backoffice/providers/show.html.haml:23)**
Using `html_safe` on user-generated content without sanitization. This could lead to XSS.

**Good Pattern (app/builders/provider_form_builder.rb)**
Nice use of a builder for form construction - follows RX conventions well!

**Testing Gap**
The spec at `spec/services/provider_updater_spec.rb` doesn't test the failure path when provider.save fails.
```
