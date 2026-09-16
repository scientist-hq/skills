---
description: How to slice a finished branch into reviewable commits — code and specs in separate slices, how to stage a partial file without `add -p`, and how to keep each slice honest. Load when Mike asks to slice, split, or break up a branch's changes into commits.
---

## The Two Rules

**Code and its specs are separate slices.** One commit for the behaviour, one for the tests that cover it. A reviewer reading the code commit sees only the change; reading the spec commit sees only what it is meant to guarantee. A mixed commit hides both in a diff where the spec lines outnumber the code three to one.

**Never run `git commit` or `git push`.** Stage the slice, print the exact command with a suggested message, and let Mike commit. Staging (`git add`, `git apply --cached`) and unstaging (`git restore --staged`) are fine.

## Ordering

**Specs first, code second — and the spec slice is expected to fail.** That is the point of the order: a red spec commit followed by a green code commit proves in the history that the code was necessary and that the spec actually exercises it. A spec written after the fact proves neither.

So each pair is:

1. the new examples, plus any existing assertion the new behaviour contradicts
2. the behaviour that turns them green

**An assertion flip belongs in the spec slice.** When the new behaviour makes an old assertion wrong — an inverted boolean, a changed constant, a value that used to be copied — flip it with the new examples. It fails alongside them and goes green with them.

State the expectation rather than hiding it: name which slice is red, and which one turns it green. The pull request is the green unit, not the individual commit, so per-commit CI and `git bisect` will show the spec commits failing. That is intended.

**Confirm the spec slice fails for the right reason before staging it.** Run it. A spec that passes before the code lands is not testing the change, and a spec that fails on a typo or a missing factory is not either. The failure message is the evidence — read it.

## Finding the Boundaries

Slice by the question a reviewer would ask, not by file. Three of five steps landing in one file is fine; one step spread over four files is also fine.

Check the hunk boundaries before promising a split:

```
git diff <path> | grep -n "^@@"
```

If a file's concerns land in separate hunks, it can be split. If one hunk mixes two concerns, either merge those slices or accept editing a hunk by hand — and prefer merging.

**Some things do not come apart.** A prop threaded through three components is one commit; any two of the three is a broken build. New props with no consumer, and a consumer with no props, are each half an interface. When a split would produce a commit that cannot be tested or cannot compile, say so rather than forcing it.

## Staging Part of a File

Never use `git add -p` — it is interactive and unavailable here. Build a patch with the hunks you want and apply it to the index:

```python
python3 - <<'PY'
import subprocess, pathlib
path = "app/models/thing.rb"
keep = [1, 3]                     # 1-indexed hunk numbers
d = subprocess.run(["git","diff","--",path],capture_output=True,text=True,check=True).stdout
lines = d.split("\n")
starts = [i for i,l in enumerate(lines) if l.startswith("@@")]
body = []
for k in keep:
    end = starts[k] if k < len(starts) else len(lines)
    body += lines[starts[k-1]:end]
pathlib.Path("/tmp/slice.patch").write_text("\n".join(lines[:starts[0]] + body) + "\n")
PY
```

Then, from `rx/rx`, apply it at the repo root so the `a/rx/...` paths resolve:

```
git -C /Users/mike/rx apply --cached /tmp/slice.patch
```

Verify the split landed where you meant:

```
git diff --cached --stat      # what is in this slice
git diff --stat               # what is waiting for later ones
```

**Once the earlier commit lands, the leftovers usually stage whole.** Re-check before building another patch — partial staging is often needed only for the first slice of a file.

## Per Slice

1. Stage it.
2. Show `git diff --cached --stat`, and the diff itself for anything non-obvious.
3. Say in two or three sentences what it does and what it does not do yet.
4. Print the commit command with a message: imperative subject, a body explaining why, `Refs #<issue>`, and the `Co-Authored-By` line.
5. Wait. Do not stage the next slice until the previous one is in — check `git log --oneline -2` rather than assuming.

## Before Slicing At All

Run the affected suites once on the whole branch, with every change in the working tree. Slicing is a presentation step; it is not the place to discover a real failure. If Mike changes the scope mid-slice, re-run what the revert touched before staging again.

Knowing the whole branch is green is also what lets you say, honestly, that a red spec slice is red only because its code has not landed yet.
