---
description: Universal rules for all GitHub ticket and issue interactions, covering Claude attribution placement, no point-of-contact policy, using --type instead of --label, and preserving screenshots on edits.
---

# General Ticket / Issue Rules

## Attribution

**ALWAYS place the Claude attribution as the first line** of any issue body or comment written for GitHub:

```
🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

- **NEVER** place attribution at the bottom
- This applies to: issue bodies, issue comments, any text written to GitHub on behalf of the user

## No Point of Contact

**NEVER include a point of contact in any ticket or issue.**

- **NEVER** add a "Point of Contact", "Contact", "Owner", or similar field/section
- Omit any such section entirely — do not include it even if a template suggests it

## Type Instead of Label

**NEVER add a label — ALWAYS set a type instead.**

- **NEVER** use `--label` when creating issues
- **ALWAYS** use `--type` with one of:
  - `Bug` — bug reports and error fixes
  - `Feature` — new features or enhancements
  - `Task` — anything else (chores, refactors, investigations, etc.)

## Editing Existing Issues

**ALWAYS fetch the latest version of an issue immediately before editing it — NEVER remove screenshots.**

- **ALWAYS** fetch the current issue body right before making edits, even if you read it earlier in the conversation
- **NEVER** assume the content hasn't changed since you first read it
- **ALWAYS** preserve all screenshots and images when updating any part of the content
- The user may have added screenshots between when you first read it and when you're editing it

**Workflow:**
1. Fetch the current issue body
2. Make your changes while preserving all existing screenshots and images
3. Double-check that all screenshot URLs are preserved in your edit
