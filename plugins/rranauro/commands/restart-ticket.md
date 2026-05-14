# Restart Work on a Ticket

This command picks up where you left off on an in-progress GitHub issue by assessing current state and identifying remaining work.

**Usage:** `/rranauro:restart-ticket <github_issue_url>`

## Step 1: Read the Ticket

Use the GitHub MCP tools or `gh` CLI to read the full issue from the provided URL. Extract:
- Issue number
- Title
- Full description (body)
- Labels
- Any linked issues or PRs
- Comments (look for updated requirements or decisions made in discussion)

## Step 2: Assess Current State

### Check the Branch

```bash
git branch --list "*<issue_number>*"
git log main..<branch> --oneline
git diff main...<branch> --stat
```

- Find the branch associated with this issue number
- If not already on it, switch to it
- Review the commit history since branching from main

### Check for an Existing Plan

Look for a plan file at `plans/<issue_number>-*.md`. If found, read it to understand the original approach and steps.

### Review What's Changed

- Read the diff against main to understand what has been implemented so far
- Check for any failing tests: `bundle exec rspec` on changed spec files
- Look at `git status` for any uncommitted work in progress

## Step 3: Present a Status Report

Present a clear summary to the user with these sections:

```markdown
## Ticket: #<issue_number> - <title>

### What the Ticket Asks For
[Brief summary of the requirements from the issue]

### What's Been Done
- [List of completed work based on commits and code changes]
- [Reference specific commits or files]

### What Remains
1. [ ] [Remaining task]
2. [ ] [Remaining task]
3. [ ] ...

### Current Issues
- [Any failing tests, lint errors, or problems spotted in the code]
- [Any conflicts with main that need resolving]

### Recommendation
[Suggest the next concrete step to take]
```

## Step 4: Update the Plan

If a plan file exists, update the checkboxes to reflect completed steps. If no plan file exists, create one following the same format as `/rranauro:start-ticket`.

**Wait for the user to confirm the assessment and agree on next steps before beginning any implementation work.**

## Important Notes

- **Do NOT start coding** until the user confirms the assessment and next steps
- **Check for main branch drift** - note if main has moved significantly since the branch was created
- **Read any PR** that may already be open for this branch
- **Search the codebase** for any TODO comments referencing the issue number
- **Keep focus tight** - only assess what's relevant to the ticket, don't expand scope
