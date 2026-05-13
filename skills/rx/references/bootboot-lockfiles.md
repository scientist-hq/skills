# Bootboot Dual-Lockfile Setup

## Overview

RX uses the [bootboot](https://github.com/Shopify/bootboot) gem plugin for managing dependency upgrades. It maintains two lockfiles:

- `rx/Gemfile.lock` — primary (what CI and production use)
- `rx/Gemfile_next.lock` — "next" environment for testing upgrades

## How It Works

The `Gemfile` has a conditional block (currently commented out):

```ruby
plugin 'bootboot', '~> 0.2.2'

# uncomment when bootboot is needed for upgrading gems again
# if ENV['DEPENDENCIES_NEXT'] && !ENV['DEPENDENCIES_NEXT'].empty?
#   # next-version gems go here
# else
#   # current gems go here
# end
```

When active, running `DEPENDENCIES_NEXT=1 bundle install` updates `Gemfile_next.lock` separately.

## When to Sync

When **no dual-boot upgrade is in progress** (the conditional block is commented out), both lockfiles should be identical. They can drift when security patches or regular `bundle update` only updates `Gemfile.lock`.

### Sync procedure

```bash
cp rx/Gemfile.lock rx/Gemfile_next.lock
```

That's it. Verify with `diff rx/Gemfile.lock rx/Gemfile_next.lock` (exit 0 = identical).

### Branch/PR conventions

- Branch: `chore/sync-gemfile-next-lock`
- Commit: `chore: sync Gemfile_next.lock with Gemfile.lock`
- Risk: extremely low — aligns next-lockfile with what's already deployed

## When NOT to Sync

If the bootboot conditional block is **uncommented** and actively diverging gems, do NOT blindly copy. The two files are intentionally different during an upgrade campaign.
