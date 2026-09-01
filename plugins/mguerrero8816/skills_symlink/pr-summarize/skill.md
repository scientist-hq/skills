---
description: Explain a PR's code changes in reasonable parts, ordered top-to-bottom to match GitHub's Files-changed tab so Mike can scroll and read along. Load when asked to summarize, walk through, or explain the changes in a PR.
---

## Purpose

Produce a walkthrough of a PR's diff that Mike can read while scrolling straight down the GitHub **Files changed** page — no hopping up and down. This is a *reading companion for the diff*, not a code review (for review use `review`).

## Step 1 — Fetch the diff from the REAL PR head, never the local tree

**This is the rule that matters most. The local working tree can be several commits behind the PR head.** A `git diff` against a local branch silently produced a wrong summary once — a whole extracted file was missing, and later commits (fee-first UX, a data-loss fix, a concern extraction) were absent. Always pull the diff from GitHub.

1. Confirm the head: `gh pr view <PR> --json headRefOid,author,title -q '.headRefOid'`
2. Get the real diff to a scratchpad file: `gh pr diff <PR> --patch > <scratchpad>/pr<PR>.diff`
   - `--patch` gives per-commit patches with commit messages — the messages are gold for explaining *why* a change exists and for spotting a change that was later reverted (added then removed = net zero; don't describe it as present).
3. Get the authoritative file list (GitHub order): `gh pr view <PR> --json files -q '.files[].path' | sort`
4. If a local branch is checked out, sanity-check it against the head and **state the divergence to Mike** if they differ:
   `git rev-parse HEAD` vs the `headRefOid` above. If behind, tell Mike the GitHub diff is authoritative and local files won't match.

Never `cd`; run `gh`/`git` from the repo. Read the saved `.diff` with the Read tool (grep `^Subject:` / `^diff --git` to map commit and file boundaries).

## Step 2 — Order the walkthrough to match GitHub

GitHub's Files-changed tab is sorted **alphabetically by full path** (case-insensitive; `_` sorts before letters, so `__tests__/` lands before sibling files). `... | sort` reproduces this order. Emit your file sections in exactly that order so Mike scrolls once, top to bottom.

## Step 3 — Structure each summary

- **Lead with a one-paragraph mental model** of the feature before the file list — the single invariant or data flow that makes the individual diffs make sense (e.g. "a grouped milestone needs two FKs on one row, set at create time before the proposal has an id"). Without it the parts read as disconnected.
- **One `###` heading per file, in GitHub order.** Use the repo-relative path as the heading (or a readable short form for long JS paths).
- **Right-size each file:** expand the substantive ones (new behavior, tricky logic); collapse mechanical/repeated ones to a single line ("mechanical `railsName` → `useRowName()` migration"). Group identical trivial changes.
- **Mark new files** (🆕) and, on a re-summary, mark anything you're correcting (⚠️).
- **Cite `path:line` only against the real head** — line numbers from a stale tree will be wrong.
- **Put tests last** as a short cluster unless a test encodes something the production code doesn't show.
- End with a one-line note if the local tree is stale (head SHA vs local).

## What to skip

- Don't restate the PR description back verbatim — read the actual code and explain what it does.
- Don't review (no verdicts, no findings) unless Mike asks — that's `review`.
- Don't touch code, git state, or the PR. This is read-only.
