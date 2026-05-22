---
description: Step-by-step process for safely bumping gem versions in a bootboot dual-lock-file Rails project, including breaking change checks and PR test instructions.
---

## Bumping a Gem Version

### Step 1: Direct or Transitive?

Check if the gem is listed directly in `rx/Gemfile`:

```bash
grep "<gem_name>" rx/Gemfile
```

- **Transitive** (not in Gemfile): skip to Step 2 — no Gemfile edit needed
- **Direct** (in Gemfile): update the version constraint in `rx/Gemfile` first

### Step 2: Update the Lock Files

This project uses [bootboot](https://github.com/Shopify/bootboot) for dual-boot, so there are two lock files to keep in sync.

```bash
cd rx && bundle update <gem_name>
DEPENDENCIES_NEXT=1 bundle update <gem_name>
```

Note: `bundle update <gem_name>` alone may not touch `Gemfile_next.lock` — always run the `DEPENDENCIES_NEXT=1` variant explicitly to ensure both files are updated.

### Step 3: Verify Both Lock Files Changed

```bash
git diff --stat
```

You should see both `rx/Gemfile.lock` and `rx/Gemfile_next.lock` updated. If `Gemfile_next.lock` didn't change, run `DEPENDENCIES_NEXT=1 bundle update <gem_name>` explicitly.

### Step 4: Identify All Affected Gems

Check the full diff to see if any other gems moved alongside the target:

```bash
git diff --stat
git diff rx/Gemfile.lock
```

Any gem that changed version — not just the target — must go through Steps 5 and 6 individually. This happens when the target gem widens its own version constraints, allowing bundler to pull in newer transitive deps (e.g., bumping `addressable` 2.8.7 → 2.9.0 also pulled `public_suffix` 6.0.2 → 7.0.5 because `addressable` widened its constraint from `< 7.0` to `< 8.0`).

### Step 5: Check for Breaking Changes

For **each affected gem**, fetch the changelog from its GitHub releases page and look for anything between the old and new version tagged as **breaking**, **removed**, or **migration required**.

### Step 6: Check App Usage

For **each affected gem**, search the codebase for direct usage:

```bash
grep -r "GemModule::" rx/app --include="*.rb" -l
grep -r "require.*gem_name" rx/app --include="*.rb" -l
```

For each file found, check which specific methods/classes are called and cross-reference against any breaking changes found in Step 5.

### Step 7: Safety Verdict

For each affected gem:

- No breaking changes + app doesn't use affected APIs + CI passes → **safe to merge**
- Breaking changes that affect app usage → **code changes needed before merging**

### Step 8: Write PR Test Instructions

PR instructions must have reviewers actually load the app and exercise the code paths that use the affected gems — not just "run bundle install and check CI."

Use the app usage found in Step 6 to determine what to test. For each gem:

- If the gem handles **auth/passwords** (e.g., `bcrypt`, `devise`): have the reviewer sign up and log in
- If the gem handles **URLs/URIs** (e.g., `addressable`, `public_suffix`): have the reviewer visit pages that generate or parse URLs (punchout flows, PDF generation, link validation)
- If the gem is used **implicitly by Rails** (e.g., `rack`, `nokogiri`): have the reviewer load a few representative pages and confirm no errors
- If the gem has **no direct app usage** and is purely infrastructure: CI passing is sufficient, but still say so explicitly

**Good example** (bcrypt, [#31967](https://github.com/scientist-hq/rx/pull/31967)):
> 1. Make sure you are logged out
> 2. Go to `https://az.test/signup`, fill out the fields, and click "Sign Up"
> 3. Open Rails console and run `Pg::User.last.confirm`
> 4. Go to `https://az.test/login` and log in with the credentials from step 2
> 5. Confirm you can successfully log in

**Avoid** instructions like:
> 1. Run `bundle install`
> 2. Confirm CI passes

That tells reviewers nothing about whether the app actually works.
