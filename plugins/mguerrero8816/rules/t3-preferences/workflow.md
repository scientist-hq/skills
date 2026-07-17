# Workflow Preferences

## Test Documents

Save all manual test documents to `/Users/mike/test_docs/` — never inside the repo. This applies whenever creating a test doc or when the user mentions "test doc".

## Always Write or Check for Specs Before Making Code Changes

Before implementing any code change, check whether specs already exist for the affected code. If none exist, write one first and confirm it fails for the right reason before implementing.

This ensures specs actually validate the intended behavior and don't pass trivially.

When writing specs, load `skills/testing/spec/spec-rules.md` for writing conventions and the relevant test-data skill for record creation patterns (see `SKILL.md` Testing section).

**Exception — small changes:** Skip the spec-first step for small, low-risk edits (label/wording changes, markup tweaks, dropdown option lists, copy, and similar) that don't add real logic or behavior. Use judgment; when in doubt or when the change introduces a new code path, still spec it first. Mike can always ask for specs on a small change.

## Verify Views in Browser Before Making Changes

Before editing any view template and after making changes, dispatch browser verification subagents rather than performing Playwright steps yourself.

**Exception — small changes:** Skip browser verification (both before and after) for small, low-risk view edits (label/wording, markup tweaks, option lists, copy, and similar). Use judgment; verify in-browser when the change affects layout, interactive behavior, or anything visually non-obvious. Mike can always ask for browser verification on a small change.

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

### Batch the after-verification for multi-change requests

When a single request from Mike involves multiple view changes, make **all** the changes first, then dispatch **one** after-verification run covering everything — do not verify after each individual edit.

Browser verification is slow (each Playwright step is a round-trip); running it per-edit wastes minutes on a request that only needs one final pass.

- ❌ BAD: edit header → verify → move form to modal → verify → rename button → verify
- ✅ GOOD: edit header + move form to modal + rename button, then one verification run covering all three

Still run non-browser checks (rspec, rubocop) as you go — the batching applies only to the browser verification subagent. And still do a **before** run first if the starting state needs confirming.
