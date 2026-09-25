# Workflow Preferences

## Test Documents

Save all manual test documents to `/Users/mike/test_docs/`, never inside the repo.

## Check for Specs Before a Code Change

Before you change code, look for specs that cover it. If there are none, write one and confirm that it fails for the right reason. Then implement. Before you write a spec, load `skills/testing/spec/spec-rules.md` and the relevant test-data skill.

- **Small changes:** skip this for copy, labels, markup tweaks, option lists, and similar edits with no new logic. If the change adds a code path, write the spec.
- **Views:** a view change never gets an RSpec spec. See the next rule.

## Never Write an RSpec Spec for a View

Do not add an RSpec example that asserts on rendered markup or copy. This holds even for a new conditional in a view.

- NEVER create a file under `spec/views/`.
- NEVER assert on markup or copy from a request spec or a controller spec.
- A form field's `name` and `value` are a server contract. A spec can read them from the body and assert the parsed payload.
- This rule does not apply to Jest tests under `app/javascript/**/__tests__/`.

- ❌ BAD: `expect(response.body).to include('Additional Items')`
- ❌ BAD: `expect(Nokogiri::HTML(response.body).css('.card-body .card').size).to eq(2)`
- ✅ GOOD: `expect(rendered_item_group_ids(response.body)).to include(group.id)`
- ✅ GOOD: `expect(response).to have_http_status(:success)`

## Verify Views in the Browser Before and After a Change

Use subagents for browser verification. Do not do the Playwright steps yourself.

1. Find the URL for the view. Load `skills/rx-urls.md` if necessary.
2. Dispatch a **before** subagent. Tell it to invoke the `subagent-bootstrap` skill first. Give it the URL and the state to confirm.
3. Wait for its report, then make the change.
4. Dispatch an **after** subagent with the same bootstrap instruction, the URL, and the change to verify. Tell it: "Reload the page before checking — never trust the current browser state."

- **Small changes:** skip both runs for copy, labels, markup tweaks, and similar edits. Verify when the change affects layout, interaction, or something that is not visually obvious.
- **Several changes in one request:** make all the changes, then dispatch one after-run for all of them. Still run rspec and rubocop as you go.

## Run Only the Specs for What Changed

Run the spec files that cover the code you touched, by path. Never run a directory tree, and never reproduce CI locally. CI runs the full suite on each push. To learn whether CI passes, run `gh pr checks <number> --repo scientist-hq/rx`.

- Run rubocop only on the changed files, with `--force-exclusion`.
- Before you start rspec, check for a run in progress: `ps -o pid=,command= -A | grep "bin/rspec"`. All local runs share one test database, so a second run causes false failures in the first. If a run already covers your file, wait for it.

- ❌ BAD: `bundle exec rspec spec/models spec/actions spec/requests`
- ❌ BAD: `bundle exec rubocop` with no paths
- ✅ GOOD: `bundle exec rspec spec/models/pg/quote_group_spec.rb spec/actions/proposals/build_spec.rb`
- ✅ GOOD: `bundle exec rubocop --force-exclusion --format simple app/models/pg/quote_group.rb`

## Design Files Stay Local

A design file is any mockup, wireframe, comparison, or written design proposal for Mike. Write it as a plain `.html` or `.md` file in `/Users/mike/test_docs/`, unless Mike names a different location. Give him the path.

- NEVER publish one with the Artifact tool, a document connector, a gist, or any other remote host, unless Mike asks and names the place.
- A feature design document under `design_docs/` is a repo file. See the `design-design-doc` skill. It must not be published either.

- ✅ GOOD: write `/Users/mike/test_docs/39229-modal-layout.html`, then give `file:///Users/mike/test_docs/39229-modal-layout.html`
