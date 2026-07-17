---
description: Universal RSpec rules for this codebase covering let! vs let, change matchers, minimum required fields, running specs, controller spec patterns, and stubbing collaborators.
---

# RSpec Spec Writing Rules

## Record Creation

**ALWAYS use `let!` instead of `let` for database records**
- `let` is lazy — it only creates the record when first referenced, which can cause ordering issues and forces `.reload` calls to get fresh data
- `let!` is eager — the record exists in the DB before the example runs, so in-memory objects stay in sync with the database
- Only use `let` for non-persisted objects (plain Ruby objects, doubles, mocks) where eager evaluation would be wasteful or cause side effects

**Examples:**
- ❌ BAD: `let(:provider) { Pg::Provider.create!(...) }`
- ✅ GOOD: `let!(:provider) { Pg::Provider.create!(...) }`
- ✅ OK: `let(:service) { MyService.new(provider) }` — not a DB record, lazy is fine

## Asserting Changes

**ALWAYS use `expect { }.to change(...)` when testing that something changes**
- Do not check the value before and after separately with `eq`
- Do not check only the after-state with `eq` when the point of the test is that something changed
- `change` captures before/after in one expression, makes intent clear, and catches cases where the initial state was already the expected value

**Forms:**
- `change(object, :method)` — checks a method on an object
- `change { expression }` — checks an arbitrary block
- Chain `.from(x).to(y)` when the specific before/after values matter
- Chain `.by(n)` for numeric changes
- Chain `.from(x)` or `.to(y)` alone when only one side needs to be pinned

**Examples:**
- ❌ BAD: `subject; expect(record.status).to eq('approved')`
- ❌ BAD: `before = record.status; subject; expect(record.status).not_to eq(before)`
- ✅ GOOD: `expect { subject }.to change(record, :status).from('pending').to('approved')`
- ✅ GOOD: `expect { subject }.to change { Record.count }.by(1)`
- ✅ GOOD: `expect { subject }.not_to change(record, :status)`

## Parenthesizing `change { }` Blocks

**ALWAYS parenthesize `change { }` when used with `.not_to` or `.and`**

Without parentheses, Ruby's parser may associate the block with the outer method (`.not_to` or `.and`) instead of `change`, causing a RuboCop error: _"Parenthesize the param `change { ... }` to make sure that the block will be associated with the `change` method call."_

**Examples:**
- ❌ BAD: `expect { subject }.not_to change { record.reload.status }`
- ✅ GOOD: `expect { subject }.not_to(change { record.reload.status })`
- ❌ BAD: `.and change { record.reload.count }.by(1)`
- ✅ GOOD: `.and(change { record.reload.count }.by(1))`

This applies to the block form `change { }` only — `change(object, :method)` does not need parenthesizing.

## Record Creation — Minimum Required Fields

**Only include fields that are actually required — do not copy over-specified examples from other specs**
- Before writing record creation, check the model's validations for the minimum required fields
- Existing specs may themselves be over-specified; don't treat them as a template for what's needed
- **NEVER use FactoryBot** — always hand-roll records with only the minimum required fields
- For canonical creation patterns, consult the test-data files before checking model validations or other specs:
  - `Pg::Organization` → `skills/testing/spec/test-data-organization.md`
  - `Pg::User` → `skills/testing/spec/test-data-user.md`
  - `Pg::Ware`, `Pg::Provider`, `Pg::QuoteGroup`, `Pg::QuotedWare` → `skills/testing/spec/test-data-request.md`
  - `Pg::Proposal` (SOW / Amendment) → `skills/testing/spec/test-data-proposal.md`
  - CPO / PPO → `skills/testing/spec/test-data-purchase-order.md`

## Running Specs

**Only run the specific files you changed — never pass a whole directory**
- Running a directory pulls in unrelated specs and wastes time
- After making changes, run only the files that were added or modified

**Examples:**
- ❌ BAD: `bundle exec rspec spec/actions/proposals/`
- ✅ GOOD: `bundle exec rspec spec/actions/proposals/adjust_fee_cap_spec.rb spec/models/pg/proposal/manual_fee_cap_amount_spec.rb`

**Always run specs after writing or editing them — never assume they're correct**
- After adding or modifying any spec, run it immediately with `bundle exec rspec <path>` from `rx/`
- A spec that has never been run is unverified — execution confirms the test logic is sound
- Report the result before moving on


## Controller Specs — Asserting State Changes

**Exception to the general "Asserting Changes" rule above: in controller specs, NEVER use `expect { }.to change { }` — use explicit before/after checks instead.**

RuboCop does not allow `change { }` blocks in controller specs:

```ruby
# ❌ BAD
it 'marks the invoice as paid' do
  expect {
    post :update_statuses, params: { ... }
  }.to change { invoice.reload.status }.to('paid')
end

# ✅ GOOD
it 'marks the invoice as paid' do
  expect(invoice.status).to eq('in_review')
  post :update_statuses, params: { ... }
  expect(invoice.reload.status).to eq('paid')
end
```

Applies to: any controller spec testing a status/attribute change, both "it changes" and "it does not change" cases, single and multi-record assertions.

## Require Convention

**Always match the `require` used by sibling specs in the same directory — do not assume `rails_helper`.**

- Some directories (e.g. `spec/services/saved_line_items/`) consistently use `spec_helper`; new specs in those directories should follow suit
- Only use `rails_helper` in directories where siblings already use it

## Stubbing Collaborator Services

**When a spec depends on a collaborator service, check whether that collaborator has its own specs:**
- **Has its own specs** → stub it with `allow(ServiceClass).to receive(:method).and_return(value)` and test only the behavior of the thing being specced — do not re-test the collaborator's logic
- **Has no specs** → ask whether to create specs for it first (the answer is generally yes); once those exist, stub it as above

**Examples:**
- ❌ BAD: Setting up PaperTrail, time-travel, POs, and org hierarchies in a model validation spec when the historical cap lookup already has its own spec file
- ✅ GOOD: `allow(Proposals::HistoricalFeeCap).to receive(:for).with(proposal).and_return(1000)` — stub the covered collaborator, test only the validation boundary

## Test Through the Real Persistence Path — No Spec-Only Saves

**When the behavior under test creates or mutates records through a service or controller action, drive the spec through that real path. Never stand in a spec-only `save` / `save(validate: false)` / `persist!` helper to force the records into existence.**

A fake save masks *where* persistence actually happens and lets a spec pass against code wired to the wrong layer — the classic trap is a builder/prefill service that returns an **unsaved** object (e.g. `Proposals::Build`, which only pre-fills a form). That is NOT the creation point; find the service that actually persists (e.g. `Proposals::Create#run`'s `save!`) and exercise it.

- **Scaffolding the behavior depends on** (parent records) may be created directly — that's setup.
- **The record under test** must be created by the real service/controller, so the spec exercises the actual integration (validations, params, callbacks).
- If wiring the real path is painful (heavy params, many validations), that pain is signal — it's the integration you'd otherwise ship untested. Assemble the valid params up front (read a sibling spec that drives the same service) rather than discovering requirements one rescued validation at a time.

**Examples:**
- ❌ BAD: `co = Proposals::Build.run(...); co.save(validate: false)` then asserting on `co` — `Build` never persists in production; this tests nothing real.
- ✅ GOOD: `Proposals::Create.new(proposal: nil, params: {...}).run` (exactly as the controller invokes it), then assert on the returned persisted record.

## No View Specs

**Do not write view specs (`type: :view`, files under `spec/views/`).** We do not test views in isolation.

- When a change lives in a view/partial, put the logic somewhere testable and spec that instead:
  - Extract the non-trivial logic (partitioning, totals, label resolution, conditionals) into a **helper or presenter** and unit-test the method.
  - Or cover the rendered behavior through a **request/system spec** that exercises the real page, if end-to-end coverage is warranted.
- Pure markup/layout with no logic needs no spec — rely on browser verification.

**Example:**
- ❌ BAD: `spec/views/shared/_accounting_milestones.html.haml_spec.rb` rendering the partial with `render partial:` and asserting on `rendered`
- ✅ GOOD: extract the milestone grouping/subtotal logic into a presenter method and spec that method directly

