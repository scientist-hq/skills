---
description: How to write new skills and rules for this plugin — when to use each, where to put them, and how to structure them.
---

## Skills vs Rules

**Write a skill** when the guidance is task-specific — it only applies when Claude is doing a particular kind of work. Skills are loaded on-demand via the routing table.

**Write a rule** when the guidance applies unconditionally — it should always be in effect regardless of task. Rules load automatically at session start.

---

## Writing a Skill

### File Location

Place skills in `~/skills/plugins/mguerrero8816/skills/` under the most relevant category folder. If no folder fits, create one or place it at the top level.

```
skills/
├── pull-requests/    # PR creation and interaction
├── debugging/        # Debugging and investigation
├── testing/          # Specs, test data, QA
├── integrations/     # External service workflows
├── design/           # Feature design and screenshots
├── playwright/       # Browser automation
└── code-quality/     # Gem bumps, fee cap, etc.
```

### File Structure

```markdown
---
description: One sentence — what this skill covers and when to load it.
---

## Section Title

Content here.
```

- **No `name:` field** — skills are loaded via routing table, not auto-discovered
- **No opening phrase** after the first heading — the `description:` already says what the file is
- Use `##` sections for scannable content

### Updating the Routing Table

Every new skill needs a row in `~/skills/plugins/mguerrero8816/SKILL.md`.

- Add it to the most relevant section, or create a new section if none fits
- The **When** column should be specific enough to trigger on the right task without false positives

```markdown
## My Category

| When | File |
|------|------|
| Doing X or working on Y | `skills/my-skill.md` |
```

### Category-Specific Authoring Guides

| Skill type | Guide |
|------------|-------|
| Playwright / browser automation | `skills/playwright/authoring.md` |

---

## Writing a Rule

### Choosing the Right Tier

| Tier | Use when... |
|------|-------------|
| T2 Standards | Team-enforced or lint-enforced. Violating it would break CI, cause data loss, or be rejected in review. |
| T3 Preferences | Personal code style. Applies to Mike's code but yields to T2. Formatting choices, naming preferences, workflow habits. |
| T4 Defaults | Soft Claude behavior defaults — output formatting, tool-use patterns. Yields to everything above. |

**T1 is reserved** — do not add new T1 rules without careful consideration.

**T2 vs T3:** if a linter or the team would catch and reject the violation, it's T2. If it's a personal preference that wouldn't fail a review, it's T3.

### File Location

```
rules/
├── t2-standards/     # Always-on enforced standards
├── t3-preferences/   # Personal style preferences
└── t4-defaults/      # Soft Claude behavior defaults
```

**Add to an existing file** if the rule fits a file that already covers that topic (e.g. a new RuboCop rule goes in `t2-standards/rubocop.md`).

**Create a new file** if the topic is distinct. Use a short, lowercase, hyphenated filename.

### File Structure

Rule files use plain markdown — no frontmatter. Start with an `#` H1 title, then `##` sections.

```markdown
# Topic Name

## Rule Name

Explanation with examples.

- ❌ BAD: ...
- ✅ GOOD: ...
```

Rules do **not** need a routing table entry — they are loaded automatically every session.
