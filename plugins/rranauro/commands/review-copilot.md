Review and address GitHub Copilot's PR review comments one by one.

**Step 1 — Find the PR:**
- Run `gh pr view --json number,url,title` to get the current branch's PR.
- If no PR exists, tell the user and stop.

**Step 2 — Fetch Copilot's review comments:**
- Run `gh api repos/{owner}/{repo}/pulls/{number}/comments --jq '.[] | select(.user.login | test("copilot|github-actions")) | {id, path, line, body, diff_hunk}'` to get Copilot's inline comments.
- Also check `gh api repos/{owner}/{repo}/pulls/{number}/reviews --jq '.[] | select(.user.login | test("copilot|github-actions")) | {id, state, body}'` for top-level review comments.
- If no comments found, tell the user "No Copilot review comments found" and stop.

**Step 3 — Process each comment:**
For each comment, in order:

1. **Show the comment** — display the file path, line number, and Copilot's feedback.
2. **Read the relevant code** — read the file around the mentioned lines to understand context.
3. **Assess the comment** — categorize it:
   - 🔴 **Must fix** — security issue, bug, or correctness problem
   - 🟡 **Should fix** — code quality, maintainability, or clarity improvement
   - 🟢 **Optional** — style preference, nitpick, or suggestion that doesn't improve the code meaningfully
   - ⚪ **Ignore** — false positive, already handled, or not applicable to our codebase
4. **Explain your reasoning** — briefly describe the problem and why you categorized it that way.
5. **Propose action** — either:
   - Fix it: describe what you'll change and make the edit
   - Ignore it: explain why it's safe to skip

**Step 4 — Ask the user before fixing:**
- Present your assessment for the current comment.
- Ask: "Fix this, skip it, or discuss?"
- Only make changes when the user confirms.

**Step 5 — After all comments are addressed:**
- Summarize for the user: how many fixed, how many skipped, and why.
- If any fixes were made, the commit message must capture the per-comment evaluation so it's durable in git history (not just the conversation). Format:

  ```
  Address Copilot review feedback

  - <path>:<line> [Must fix] <one-line reasoning> — <action taken>
  - <path>:<line> [Should fix] <one-line reasoning> — <action taken>
  - <path>:<line> [Ignore] <one-line reasoning> — false positive, no change
  - <path>:<line> [Optional] <one-line reasoning> — skipped (nitpick)
  ```

  Use the same four categories from Step 3.3. **Include skipped comments too** — the durable record of "we considered this and decided not to act" is the point. If Step 6 delegates to `/rx:commit`, pass this body as the intended message rather than letting `/rx:commit` draft its own.
- If no fixes were made (all comments skipped/ignored), do NOT create a commit. The evaluation summary lives only in the conversation; there is nothing to push.

**Step 6 — Quality gates (if any fixes were made):**
- Run the /rx:commit skill

**Step 7 — Push:**
- Push the branch to origin.

**Arguments:** $ARGUMENTS
If the user passes a PR number (e.g., `/rranauro:review-copilot 228`), use that instead of the current branch's PR.
