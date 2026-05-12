# Bootboot: Dual-Lockfile Upgrades (rx)

## What is bootboot?

[Shopify/bootboot](https://github.com/Shopify/bootboot) is a Bundler plugin that maintains two lockfiles simultaneously. This allows dual-building release images during larger infrastructure upgrades (e.g., testing a new Ruby or Rails version in parallel with the current one).

In rx:
- `Gemfile.lock` — the primary lockfile (current production)
- `Gemfile_next.lock` — the "next" lockfile (upcoming/parallel version)

## Why this matters for Dependabot remediation

Every gem upgrade on rx must update BOTH lockfiles. If you only update `Gemfile.lock`, CI may pass locally but the "next" build will have stale/vulnerable dependencies.

## How to update both lockfiles

### Standard upgrade (both lockfiles)

```bash
cd rx/  # the Rails app directory within the monorepo

# Update the primary lockfile
bundle update gem_name --conservative

# Update the next lockfile
DEPENDENCIES_NEXT=1 bundle update gem_name --conservative
```

### Verify both changed

```bash
git diff --stat
# Should show:
#   rx/Gemfile.lock      | N +++---
#   rx/Gemfile_next.lock | N +++---
```

### If the Gemfile has conditional deps for next

The rx Gemfile has a block gated on `DEPENDENCIES_NEXT`:

```ruby
if ENV.fetch('DEPENDENCIES_NEXT', nil) && !ENV['DEPENDENCIES_NEXT'].empty? && Plugin.installed?('bootboot')
  # Gems that differ between current and next go here
end
```

If a gem is ONLY in this block, you only need `DEPENDENCIES_NEXT=1 bundle update`. If it's in the main Gemfile (most cases), update both.

## Common patterns

### Gem exists at same version in both lockfiles

Most security patches fall here — same gem, same target version in both:

```bash
bundle update nokogiri --conservative
DEPENDENCIES_NEXT=1 bundle update nokogiri --conservative
```

### Gem version differs between lockfiles

If `Gemfile_next.lock` has a different base version (e.g., testing Rails 8.1 in next while main is on 8.0), the patch targets may differ. Check both:

```bash
grep "^    gem_name " Gemfile.lock
grep "^    gem_name " Gemfile_next.lock
```

### When bundle update fails on the next lockfile

If `DEPENDENCIES_NEXT=1 bundle update` fails due to version conflicts, it usually means the `next` configuration has different constraints. Read the resolver error and handle it separately from the main lockfile.

## Commit hygiene

Include both lockfile changes in the same commit. Don't split them — they represent the same logical upgrade.

```bash
git add Gemfile.lock Gemfile_next.lock
git commit -m "Bump gem_name X.Y.Z → X.Y.W (both lockfiles)"
```

## Pitfalls

- **Forgetting `Gemfile_next.lock`** is the #1 mistake. CI may not catch it immediately if the "next" build is only run on certain branches or schedules.
- **`DEPENDENCIES_NEXT=1` must be non-empty.** The Gemfile checks `!ENV['DEPENDENCIES_NEXT'].empty?`, so `DEPENDENCIES_NEXT=""` won't work.
- **bootboot must be installed as a plugin.** The Gemfile guards on `Plugin.installed?('bootboot')`. If you're in a fresh checkout, run `bundle plugin install bootboot` first (or just `bundle install` which should handle it).
- **Manual lockfile edits need both files.** If you're editing `Gemfile.lock` manually (e.g., Ruby version mismatch), you must make the equivalent edit in `Gemfile_next.lock` too.
