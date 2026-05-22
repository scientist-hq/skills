---
description: Audit and wipe Claude Code auto-memory directories — migrate anything useful to the skills plugin, then delete the rest.
---

## Cleanup Workflow

### 1. Find all memory directories

```bash
find /Users/mike/.claude/projects -name "MEMORY.md" | sort
```

### 2. For each MEMORY.md, evaluate each entry

| Entry type | Action |
|------------|--------|
| Already covered in a skill or rule | Drop — it's redundant |
| Useful URL pattern or project context | Add to `skills/rx-urls.md` or the relevant skill |
| Code style rule | Add to the correct T2/T3 rule file |
| Stale dead code tracking or one-off notes | Drop |
| Pointer to a skill that already exists | Drop |

When in doubt, check whether the content is already captured in `~/skills/plugins/mguerrero8816/` before migrating.

### 3. Wipe each MEMORY.md

After migrating anything worth keeping, delete the file:

```bash
rm /Users/mike/.claude/projects/<project>/memory/MEMORY.md
```

Or wipe all at once:

```bash
find /Users/mike/.claude/projects -name "MEMORY.md" -delete
```

### 4. Confirm

```bash
find /Users/mike/.claude/projects -name "MEMORY.md"
```

Should return nothing.
