# Major Version Upgrade Blockers

## Companion Gem Version Ceilings

The most common blocker for major version upgrades is a companion gem with a hard upper bound:

```ruby
# In companion's .gemspec:
spec.add_dependency "devise", ">= 4.0.0", "< 5.0.0"  # BLOCKER
```

### Detection

```bash
# Just try the upgrade — the resolver error names the blocker
bundle update devise 2>&1 | head -20

# Or check dependencies manually
gem specification devise-token_authenticatable --remote | grep -A5 dependencies
```

### Resolution Options (preference order)

1. **Check for newer version** of the companion on RubyGems
2. **Fork and relax** — if the companion's code doesn't use deprecated APIs:
   - Fork to org (e.g., `scientist-hq/devise-token_authenticatable`)
   - Relax gemspec: `">= 4.0.0", "< 6.0.0"`
   - Point Gemfile at fork: `gem 'devise-token_authenticatable', git: 'https://github.com/org/fork'`
3. **Inline the functionality** — if companion is small/unmaintained
4. **Replace** — find an actively-maintained alternative

### Known Blockers (scientist-hq)

| Target Upgrade | Blocking Gem | Status |
|---------------|-------------|--------|
| Devise 4→5 (rx) | `devise-token_authenticatable` v1.1.0 (last release: 2019) | Issue #36618 — needs fork or inline |
| Devise 4→5 (benchmate) | None — clean upgrade | PR #1008 |

## Rails Minor Version Jumps

Rails minor versions (7.1→7.2) behave like semi-major upgrades:
- Deprecation warnings from N-1 become errors in N
- Default configs change
- Framework defaults file gets generated

**Check deprecation warnings on current version first:**
```bash
grep -r "DEPRECATION" log/test.log | sort -u | head -20
```

## ViewComponent 3→4

See references/viewcomponent-4.md for full breaking changes. Quick risk assessment:

```bash
find app/components -name "*.rb" | wc -l                    # count components
grep -r "renders_one\|renders_many" app/components/          # slot usage
grep -r "use_helper\b" app/components/                       # deprecated helpers
find . -path "*component_preview*" -o -path "*previews*"     # preview usage
```

No previews + no deprecated helpers + basic slots = low-risk even across major.
