# W-05: CI Fix Patterns

Common CI failures on security upgrade PRs and how to fix them.

## 1. Brakeman: Obsolete Ignore Entries

**Symptom:** CI fails with:
```
Obsolete ignore entries found.
```

**Cause:** `config/brakeman.ignore` contains suppressed warnings that no longer fire after the upgrade. Brakeman runs with `--ensure-no-obsolete-ignore-entries` which rejects stale entries.

**Example:** After upgrading Rails 7.1→7.2, the EOLRails warning for 7.1.3 no longer fires:
```json
{
  "warning_type": "Unmaintained Dependency",
  "check_name": "EOLRails",
  "message": "Support for Rails 7.1.3 ended on 2025-10-01",
  "fingerprint": "d84924377155b41e..."
}
```

**Fix:** Remove the entire JSON object from the `ignored_warnings` array in `config/brakeman.ignore`.

**How to find the right entry:** Search for the warning type rather than a specific fingerprint — fingerprints vary by version string:
```bash
grep -n "EOLRails\|Unmaintained Dependency" config/brakeman.ignore
```

Then remove the enclosing `{ ... }` block from the JSON array. Be careful with trailing commas — the JSON must remain valid.

**Gotcha:** Multiple obsolete entries may exist. Run brakeman locally to see the full list:
```bash
bundle exec brakeman --ensure-no-obsolete-ignore-entries 2>&1
```

## 2. database_cleaner-active_record: undefined method 'schema_migration'

**Symptom:**
```
NoMethodError: undefined method 'schema_migration' for an instance of
ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
```

**Cause:** `database_cleaner-active_record` 2.1.0 calls `connection.schema_migration` which was removed in Rails 7.2.

**Fix:**
```ruby
# Gemfile — add explicit constraint
gem "database_cleaner-active_record", ">= 2.2"
```

```bash
bundle update database_cleaner-active_record --conservative
```

This bumps 2.1.0 → 2.2.2+ which uses the correct Rails 7.2 API.

**Why it's not obvious:** The parent gem `database_cleaner` uses `"~> 2.0"` which happily resolves to 2.1.0. You need the explicit sub-gem constraint to force the compatible version.

## 3. Linked-Issue Check Failure

**Symptom:** "Ensure Pull Request has a linked issue" check fails.

**Cause:** Dependabot PRs don't auto-create GitHub Issues. The security advisory IS the issue.

**Fix:** See references/linked-issue-exemption.md for full details. Short version:

```yaml
# .github/workflows/pr_verify_linked_issue.yml
jobs:
  verify_linked_issue:
    if: ${{ !startsWith(github.head_ref, 'dependabot/') }}
```

## 4. Bundle Update Pulling in Unintended Upgrades

**Symptom:** A "bump nokogiri" PR also shows Rails version changes in the diff.

**Cause:** `bundle update nokogiri` without `--conservative` re-resolves shared dependencies. If Gemfile says `gem "rails", "~> 7.2"` but lockfile has 7.1.x, Rails gets upgraded too.

**Fix:** Always use `--conservative`:
```bash
bundle update nokogiri rexml --conservative
```

**Verify:** `git diff --stat` should show ONLY Gemfile.lock changing, and `git diff Gemfile.lock` should show only the targeted gems.

**If you've already pushed a mixed PR:** Reset the branch to main and redo:
```bash
git reset --hard origin/main
bundle update <only-the-intended-gems> --conservative
git add Gemfile.lock
git commit -m "Bump only-the-intended-gems"
git push --force-with-lease
```

## 5. Companion Gem Version Ceiling

**Symptom:** `bundle update` fails with a resolver error like:
```
Could not find compatible versions
  devise-token_authenticatable requires devise < 5.0.0
```

**Cause:** A companion gem has a hard upper bound on the dependency you're upgrading.

**Fix options (in preference order):**
1. Check for newer version of the companion on RubyGems
2. Fork and relax the constraint
3. Inline the functionality if the companion is small/unmaintained
4. Replace the companion with an actively-maintained alternative

See references/major-version-blockers.md for details.

## 6. General Pattern: Adapter-Dependent Gems

Rails minor versions frequently change internal ActiveRecord adapter APIs. Gems that call `connection.*` internals break silently.

**Common offenders:**
- `database_cleaner-active_record` (schema_migration, table deletion)
- `scenic` (raw SQL generation)
- `strong_migrations` (migration hooks)
- `apartment` / `acts_as_tenant` (schema switching)

**Detection:** Run the full test suite and grep for:
```
undefined method.*for.*Adapter
```
