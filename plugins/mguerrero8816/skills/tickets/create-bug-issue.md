---
name: create-bug-issue
description: Guidelines and exact structure for creating GitHub bug issues, including required sections (User Impact, Bug Description, Expected Behavior, Steps To Reproduce, Screenshots) and the --type Bug flag.
---

# Create Bug Issue

## Issue Structure

All bug issues MUST follow this exact structure with these section headers:

```markdown
## User Impact
[Brief description of how this bug affects users and what they experience]

## Bug Description
[Technical description of the bug - error messages, unexpected behavior, etc.]

## Expected Behavior
[Clear description of what should happen instead]

## Steps To Reproduce
1. [First step]
2. [Second step]
3. [Third step]
4. [Continue with numbered steps...]

## Screenshots

```

**IMPORTANT:** Always include the `## Screenshots` section header in every bug issue, even if there are no screenshots yet. The user will manually add screenshots after the issue is created. Leave this section empty when creating the issue.

## Section Guidelines

### User Impact
- Start with a user-facing description of the problem
- Focus on what the user experiences, not technical details
- Keep it concise (1-2 sentences)

### Bug Description
- Provide technical details about what's happening
- Include error messages if applicable
- Can reference code locations, but don't suggest fixes

### Expected Behavior
- Clearly state what should happen instead of the bug
- Focus on the desired outcome

### Steps To Reproduce
- Use numbered list format
- Be specific and detailed
- Include exact URLs, button clicks, or actions needed
- Make sure steps are reproducible by someone else

### Screenshots
- **ALWAYS include the `## Screenshots` section** in every bug issue
- Leave the section empty when creating the issue - the user will manually add screenshots afterward
- Screenshots are highly valuable for debugging and should be added by the user after issue creation

## Type

- **ALWAYS use `--type "Bug"`** when creating bug issues

## Important Notes

- **Do NOT suggest fixes or code changes** in the issue description
- Keep technical details in "Bug Description" section
- Keep user-facing details in "User Impact" section
- **ALWAYS include the `## Screenshots` section header** - leave it empty, the user will populate it manually after issue creation

## Creating the Issue

When creating a bug issue with `gh issue create`:
1. Use the structure above exactly
2. Include all section headers (User Impact, Bug Description, Expected Behavior, Steps To Reproduce, Screenshots)
3. Leave the Screenshots section empty
4. Use `--type "Bug"` flag (NOT `--label "Bug"`)

## Example Command

```bash
gh issue create --title "Brief description of the bug" --body "$(cat <<'EOF'
## User Impact
[User-facing description]

## Bug Description
[Technical details and error messages]

## Expected Behavior
[What should happen]

## Steps To Reproduce
1. [Step one]
2. [Step two]
3. [Continue...]

## Screenshots

EOF
)" --type "Bug"
```

## Example Issue

See issue #33967 for a properly formatted bug issue: https://github.com/scientist-hq/rx/issues/33967
