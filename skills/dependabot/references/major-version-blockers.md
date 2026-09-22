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
| Devise 4→5 (rx) | `devise-token_authenticatable` v1.1.0 (last release: 2019, no Devise 5 support) | **RESOLVED (May 2026)** — inlined via branch `remove-devise-token-authenticatable`. Constraint was `>= 4.0.0, < 5.0.0`. Also present: `devise-security` (0.18.0) which only requires `>= 4.3.0` (not blocking). |
| Devise 4→5 (benchmate) | None — clean upgrade | PR #1008 |

## Inline Playbook (for unmaintained companion gems)

When the blocking gem is small, unmaintained, and the functionality is well-understood, inlining is preferred over forking. Proven pattern (used for `devise-token_authenticatable` → rx, May 2026):

### Investigation checklist

1. **Map the gem's surface area** — fetch source from GitHub API:
   ```bash
   gh api repos/OWNER/GEM/contents/lib --jq '.[].path'
   # Recursively fetch key files via base64 decode
   ```
2. **Find all references in the codebase:**
   ```bash
   grep -rn "gem_module_name\|GemClassName" app/ config/ spec/ --include="*.rb"
   ```
3. **Identify what's actually used** vs what the gem provides. Most gems provide 10 features; you use 2-3. Only inline what's used.
4. **Check existing test coverage** — search spec/ for any exercise of the gem's behavior.

### Two-phase execution (critical: spec BEFORE change)

**Phase 1 — Harden specs on CURRENT code:**
- Write request specs for the full auth/integration flow
- Write model specs for any callbacks or class methods the gem provides
- Run specs and confirm green BEFORE any code changes
- Commit: "Add comprehensive [feature] specs before gem removal"

**Phase 2 — Inline and remove:**
- Create concern(s) or initializer(s) with the inlined logic
- Update models to use concerns instead of gem modules
- Remove gem from Gemfile, run `bundle install` (+ bootboot if applicable)
- Remove any gem-specific initializer config blocks
- Run Phase 1 specs — must still pass
- Commit: "Remove [gem] and inline [feature] logic"

### Delegation to Claude Code

This is an ideal task for Claude Code print mode (single focused PR, clear boundaries):
```bash
cat /tmp/plan.md | claude --dangerously-skip-permissions -p \
  'Implement this plan in two phases...' \
  --allowedTools 'Read,Edit,Write,Bash' \
  --max-turns 60 --model sonnet --output-format json
```

Key points:
- Write a detailed plan file with the exact files, columns, and behavior to inline
- Include the gem's source code analysis in the plan (saves Claude turns on discovery)
- Use `--max-turns 60` — Phase 1 specs + Phase 2 implementation + running specs burns ~40-50 turns
- Use a git worktree so the developer's working copy is undisturbed
- Set git-mob for whoever requested the work before spawning Claude Code

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
