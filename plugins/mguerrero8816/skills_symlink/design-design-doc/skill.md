---
description: Command for creating and maintaining a living feature design document in /Users/mike/design_docs/ throughout a design conversation.
---

# Design Doc

## Behaviour

When this command is invoked:
1. Ask the user for the feature name if not already provided
2. Create a new markdown file at `/tmp/design_docs/{feature_name}.md` using a slugified version of the feature name
3. Write the current state of the design to that file
4. As the design evolves during the conversation, update the file to reflect the latest decisions

## Updating the Doc

Throughout the design conversation, whenever a significant decision is made or the design changes, update the file immediately — do not wait for the user to ask. This includes:
- Schema changes (new tables, renamed columns, dropped columns)
- Naming decisions
- Architectural decisions (e.g. sync vs async, callback vs notifications)
- Additions or removals from Future Considerations
- Any other meaningful change to the design

The file should always reflect the current agreed-upon design, not a history of decisions. It is a living document, not a changelog.

## File Location

Always write to `/Users/mike/design_docs/`. Create the directory if it does not exist.

File naming: lowercase, words separated by underscores, `.md` extension.
- e.g. "Quote Group Auto Document" → `/tmp/design_docs/quote_group_auto_document.md`
- e.g. "Billing PO Legal Entity" → `/tmp/design_docs/billing_po_legal_entity.md`

## Document Structure

The design doc should follow this structure:

```markdown
# {Feature Name} — Design Proposal

## Overview
[Brief description of what the feature does and why it exists]

## Goals
[Bulleted list of goals]

## Database Design
[Tables, columns, and relationships. Use markdown tables for columns.]

## [Additional sections as relevant]
[e.g. Generation Flow, Triggering, Versioning, etc.]

## Future Considerations
[Bulleted list of things intentionally deferred]
```

## Important Notes

- The doc should always be in a state that could be handed to another developer or shared for approval
- Keep it concise and factual — avoid conversational tone
- Do not include a history of rejected approaches — only the current agreed design
- Future Considerations should capture deferred decisions, not rejected ones
