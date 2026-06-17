# Workflow Preferences

## Test Documents

Save all manual test documents to `/Users/mike/test_docs/` — never inside the repo. This applies whenever creating a test doc or when the user mentions "test doc".

## Always Write or Check for Specs Before Making Code Changes

Before implementing any code change, check whether specs already exist for the affected code. If none exist, write one first and confirm it fails for the right reason before implementing.

This ensures specs actually validate the intended behavior and don't pass trivially.

When writing specs, load `skills/testing/spec/spec-rules.md` for writing conventions and the relevant test-data skill for record creation patterns (see `SKILL.md` Testing section).

## Verify Views in Browser Before Making Changes

Before editing any view template and after making changes, dispatch browser verification subagents rather than performing Playwright steps yourself.

**Workflow:**
1. Identify the URL for the view being changed (load `skills/rx-urls.md` if needed)
2. Dispatch a **before** subagent — include in its prompt:
   - Invoke the subagent-bootstrap skill first
   - The URL to check and what element/state to confirm
3. Wait for the before-state report
4. Make the code change
5. Dispatch an **after** subagent — include in its prompt:
   - Invoke the subagent-bootstrap skill first
   - The URL and what change to verify
   - "Reload the page before checking — never trust the current browser state"
