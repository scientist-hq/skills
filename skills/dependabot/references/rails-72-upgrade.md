# Rails 7.1 → 7.2 Upgrade CI Fixes

Common failures and fixes specific to the Rails 7.1→7.2 minor version jump.

## 1. Brakeman Obsolete Ignore Entries

`config/brakeman.ignore` will have a stale EOLRails warning for Rails 7.1.3. After upgrading to 7.2, brakeman no longer fires this warning, so `--ensure-no-obsolete-ignore-entries` rejects it.

**Find it:**
```bash
grep -n "EOLRails\|Unmaintained Dependency" config/brakeman.ignore
```

**Fix:** Remove the entire JSON object for that fingerprint from the `ignored_warnings` array.

**Note:** The fingerprint (`d84924377155b41e...`) is version-specific. Search by `EOLRails` or `Unmaintained Dependency` instead of hardcoding the hash.

## 2. database_cleaner-active_record < 2.2

Version 2.1.0 calls `connection.schema_migration` which was removed in Rails 7.2.

**Fix:**
```ruby
# Gemfile
gem "database_cleaner-active_record", ">= 2.2"
```

```bash
bundle update database_cleaner-active_record --conservative
```

Bumps 2.1.0 → 2.2.2+ which uses the correct API.

## 3. Bundle Update Drift

`bundle update` without `--conservative` will pull in the Rails 7.2 upgrade transitively if the Gemfile constraint allows it (e.g., `gem "rails", "~> 7.2"`). This is how a "nokogiri only" PR accidentally becomes a "nokogiri + Rails" PR.

**Prevention:** Always `bundle update <gems> --conservative` and verify with `git diff Gemfile.lock`.

## 4. General Pattern: Adapter-Dependent Gems

Rails minor versions change internal AR adapter APIs. Gems that call `connection.*` internals break. After upgrading, run the full test suite and grep errors for:

```
undefined method.*for.*Adapter
```

**Common offenders:** database_cleaner-active_record, scenic, strong_migrations, apartment, acts_as_tenant.
