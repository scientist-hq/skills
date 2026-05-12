# W-04: Per-Batch Execution

For EACH batch, follow this sequence: changelog review → spec hardening → upgrade → verify → PR.

## Step 1: Changelog and Breaking Change Review

Read the CHANGELOG / release notes between your current version and the target version.

```bash
# Find current version
grep -E "^    gem_name " Gemfile.lock

# Find target version (from Dependabot alert or latest)
gem search gem_name --remote --versions | head -3
```

For each dependency in the batch:

1. **Read the CHANGELOG.** Check the gem's GitHub releases page or CHANGELOG.md.
2. **Identify breaking changes, deprecation removals, behavior changes.**
3. **Search codebase for affected APIs:**
   ```bash
   grep -r "DeprecatedMethod\|RemovedClass\|changed_behavior" app/ lib/ spec/
   ```
4. **Document findings** — these go in the PR description.

### What to Look For

- **Removed methods/classes** — will cause NoMethodError in production
- **Changed default behavior** — silent breakage, hardest to catch
- **New required configuration** — app won't boot without it
- **Dependency changes** — new deps added, old deps dropped (e.g., ViewComponent 4 drops `method_source`)
- **Minimum version requirements** — does the new version require a newer Ruby or Rails?

## Step 2: Audit and Expand Spec Coverage BEFORE Upgrading

This is the most important step. Specs written on the CURRENT version establish a behavioral baseline.

### Find existing specs

```bash
# Ruby — find specs that exercise the dependency
grep -r "PackageName\|related_method\|related_class" spec/ --include="*.rb" -l

# Check factory usage for the area
grep -r "factory\|FactoryBot" spec/ --include="*.rb" -l | head -10
```

### Identify coverage gaps

Ask: "If this dependency changed behavior silently, would our specs catch it?"

Common gaps:
- **Authentication flows** (for Devise upgrades) — test login, logout, password reset, token refresh
- **XML/HTML parsing** (for nokogiri/rexml) — test any code that parses external XML/HTML
- **Database operations** (for Rails upgrades) — test migrations, schema operations, complex queries
- **View rendering** (for ViewComponent) — test all components render without error

### Write baseline specs

```ruby
# Write specs that pass NOW and will catch regressions
RSpec.describe "Dependency Baseline" do
  it "parses XML correctly" do
    doc = Nokogiri::XML("<root><child>text</child></root>")
    expect(doc.at("child").text).to eq("text")
  end
end
```

These specs must PASS on the current version. If they don't, fix them before proceeding — you can't distinguish upgrade breakage from pre-existing failures.

## Step 3: Perform the Upgrade

### Branch

```bash
git checkout -b security/batch-N-description
```

**Monorepo worktree paths:** When the git root and the app root differ (e.g., `~/src/rx` is git root, `~/src/rx/rx/` is the Rails app), `git worktree add` creates a copy of the git root. So `git worktree add ../rx-batch5 origin/main -b branch` creates `~/src/rx-batch5/` where the Rails app is at `~/src/rx-batch5/rx/`. Run git ops from the worktree root, bundle ops from the app subdirectory.

### Update conservatively

```bash
# Ruby — ALWAYS use --conservative
bundle update gem1 gem2 --conservative

# npm
pnpm update package1 package2
```

### Verify only intended changes

```bash
git diff --stat
# Should show ONLY Gemfile.lock (and Gemfile if you edited it)
# If unrelated gems drifted, reset and try again
```

**Critical:** Without `--conservative`, Bundler may resolve other gems to newer versions. Example: `bundle update nokogiri` without `--conservative` can also upgrade Rails if the Gemfile constraint allows it. This is the #1 cause of mixed-concern PRs.

### If bundle update fails (Ruby version mismatch)

On machines where local Ruby doesn't match the project's requirement:

```bash
# Use mise to get the right Ruby
eval "$(mise env)"
bundle update gem1 --conservative
```

If even that fails (private gems pin Ruby version in gemspec):

**Why `BUNDLE_IGNORE_RUBY=1` won't help:** This env var only affects the `ruby` directive in the Gemfile. If a private gem (like `scientist_api_v2`) has `required_ruby_version = 3.3.8` in its gemspec, Bundler still rejects it. Additionally, the bootboot plugin ignores `BUNDLE_IGNORE_RUBY=1` entirely.

Fallback — manually edit Gemfile.lock:

1. Get exact dependency spec: `gem specification <gem> -v <target_version> --remote`
2. Manually edit Gemfile.lock — replace version and deps block with new
3. Note in PR body that lockfile was manually edited; CI validates with correct Ruby

This is safe for single-gem upgrades. For complex multi-gem changes, use Docker.

### Dual-lockfile repos (bootboot)

If the repo uses bootboot (rx does), update BOTH lockfiles:

```bash
bundle update gem1 gem2 --conservative
DEPENDENCIES_NEXT=1 bundle update gem1 gem2 --conservative
```

Verify both appear in `git diff --stat`. See references/bootboot.md for details.

## Step 4: Verify

```bash
# Full test suite
bundle exec rspec

# JS tests if npm packages changed
yarn test

# Brakeman (will catch obsolete ignore entries)
bundle exec brakeman --ensure-no-obsolete-ignore-entries

# Linters
bundle exec rubocop
```

If brakeman fails on obsolete ignore entries, see workflows/W-05-ci-fix-patterns.md.

## Step 5: Create PR

### Branch naming convention

`security/batch-N-description` (e.g., `security/batch-2-nokogiri-rexml`)

### PR body should include

- Which Dependabot alert numbers this resolves
- Changelog summary for each upgraded dependency
- Breaking changes identified and how they were addressed
- New specs added (if any)
- Verification results

### Linked issues

Both rx and benchmate enforce linked issues on PRs. Options:
1. Create a GitHub issue for the batch (preferred for manual upgrade PRs)
2. Exempt security branches from the check (already done for `dependabot/` branches)

For manual `security/*` branches, create an issue:

```bash
ISSUE_URL=$(gh issue create --repo ORG/REPO \
  --title "Security: Batch N - description" \
  --body "Resolves Dependabot alerts: #X, #Y, #Z" \
  --label security)
echo "Resolves $ISSUE_URL" >> /tmp/pr_body.md
gh pr create --repo ORG/REPO \
  --title "security: batch N description" \
  --body-file /tmp/pr_body.md
```
