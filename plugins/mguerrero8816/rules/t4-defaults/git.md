# Git Defaults

## Never Prepend cd to Git Commands

`git` operates on the current working tree — prepending `cd /some/path &&` is never needed and triggers a permission prompt for the compound command.

- ❌ `cd /Users/mike/rx && git diff main...HEAD`
- ✅ `git diff main...HEAD`

## Always Verify Current Branch Live

Never assume the current branch from the git status snapshot at conversation start — it is taken before the session begins and can be stale. Always run `git branch --show-current` to confirm before making any branch-based assumptions or decisions.

## Never Assert Commit or Working-Tree State Without Checking

**Never tell Mike whether something is committed, uncommitted, staged, stashed, or pushed without running `git status` / `git log` in that same turn.**

Mike commits and pushes on his own throughout a session, and those actions are invisible here. State inferred from what happened earlier in the conversation — "I made the edits, so they must be uncommitted" — is a guess, and it is usually wrong by the time it's said. The conversation-start git status snapshot is equally stale.

This applies to every phrasing of the claim, including ones that sound like context rather than an assertion: "nothing is committed", "this is all working-tree", "your changes are still local", "you'll need to commit this", "the tree is clean". Each one is a factual claim about the repo right now.

- Check before asserting, in the same turn — not from an earlier check in the conversation.
- Repeating the claim later in the turn does not reuse the earlier check. Re-run it or drop the claim.
- If the state doesn't matter to the answer, leave it out entirely rather than guessing.
- When suggesting a commit/stash/branch-move workflow, run `git status --short` first — the suggested commands depend on what is actually pending.

**Examples:**
- ❌ BAD: "Nothing is committed, so the first decision is where this lands." (no check run)
- ❌ BAD: "The fix is sitting on `p3`, uncommitted." (inferred from having made the edit)
- ✅ GOOD: run `git status --short; git log --oneline -1`, then "`7c241b9e15 preventing early db writes` is committed and the tree is clean."
- ✅ GOOD: "Here's how I'd move it to `p2`" — with no claim about whether it's committed, when that wasn't checked.
