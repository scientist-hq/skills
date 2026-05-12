# Sentry ↔ GitHub Issue Linking API

## Discovery (2025-05-12)

The Sentry API for linking external issues is **not publicly documented** (as of Feb 2025, per getsentry/sentry#85565). These notes are from empirical testing.

## Endpoints

### List integrations available for an issue
```
GET /api/0/issues/{issue_id}/integrations/
```
Returns array of integrations with their `externalIssues` currently linked.

### List external issues (flat)
```
GET /api/0/issues/{issue_id}/external-issues/
```
Returns flat array of external issue objects. May return empty even when links exist (use the integrations endpoint above instead for reliable data).

### Link existing GitHub issue (USE THIS ONE)
```
PUT /api/0/issues/{issue_id}/integrations/{integration_id}/?action=link
Content-Type: application/json

{
  "repo": "org/repo-name",
  "externalIssue": "12345",
  "title": "Issue title text",
  "description": ""
}
```
- **Method**: PUT (not POST!)
- All four fields required even though title/description seem redundant for linking
- Returns 201 with `{id, key, url, integrationId, displayName}`

### Create new GitHub issue (AVOID)
```
POST /api/0/issues/{issue_id}/integrations/{integration_id}/
Content-Type: application/json

{
  "repo": "org/repo-name",
  "title": "New issue title",
  "description": "Body text",
  "comment": ""
}
```
- Creates a brand new issue on GitHub
- Even with `?action=link` query param, POST + title + description = create

### Delete external issue link (requires elevated scope)
```
DELETE /api/0/issues/{issue_id}/external-issues/{external_issue_id}/
```
- Requires a token with `org:integrations` scope
- Must be done through Sentry UI or elevated token

## Integration Details (scientist-inc)

| Field | Value |
|-------|-------|
| Integration ID | `126670` |
| Name | `assaydepot` |
| Provider | `github` |
| Domain | `github.com/assaydepot` |
| Status | `active` |
| Features | codeowners, commits, issue-basic, issue-sync, stacktrace-link |

## Available Repos (subset)

Key repos registered in Sentry (provider: `integrations:github`):
- `scientist-hq/rx` (id: 138120)
- `scientist-hq/benchmate` (id: 899890)
- `scientist-hq/dracula` (id: 269551)
- `scientist-hq/trialinsights` (id: 259356)
- `scientist-hq/k3-applications` (id: 277294)
- `scientist-hq/skills` (id: 3052320)

Legacy repos also exist under `assaydepot/*` namespace.

## Error Recovery

If you accidentally link the wrong GitHub issue:
1. You may not be able to delete the link via API (403 without elevated scope)
2. Options:
   a. Ask someone with Sentry UI access to remove it (X button in sidebar)
   b. Make the accidentally-linked issue canonical: copy the body from the intended issue, reopen it, close the other one as duplicate
   c. Both links can coexist — the correct one will be there alongside the wrong one
