# Workflow Preferences

## Test Documents

Save all manual test documents to `/Users/mike/test_docs/` — never inside the repo. This applies whenever creating a test doc or when the user mentions "test doc".

## Always Write or Check for Specs Before Making Code Changes

Before implementing any code change, check whether specs already exist for the affected code. If none exist, write one first and confirm it fails for the right reason before implementing.

This ensures specs actually validate the intended behavior and don't pass trivially.

When writing specs, load `skills/testing/spec/spec-rules.md` for writing conventions and the relevant test-data skill for record creation patterns (see `SKILL.md` Testing section).

## Verify Views in Browser Before Making Changes

Before editing any view template, provide the URL and confirm the current rendered state in the browser first. This catches wrong branches, missing test data, feature flags, and cached states before wasting an edit.

**Workflow:**
1. Identify the URL for the view being changed (load `skills/rx-urls.md` if needed)
2. Open the page using the appropriate Playwright skill (see `skills/playwright/qa-rules.md`)
3. Confirm the relevant UI element is visible and note its current state
4. Make the code change
5. Reload and verify the change took effect
