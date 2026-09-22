# Sentry ↔ GitHub Issue Linking API

## Discovery (2025-05-12, updated 2026-05-12)

The Sentry API for linking external issues is **not publicly documented** (as of Feb 2025, per getsentry/sentry#85565). These notes are from empirical testing.

**Important:** The canonical write endpoints use `/api/0/groups/{id}/` not `/api/0/issues/{id}/`. Both may resolve for reads, but use `groups` for mutations.

## Endpoints

### List integrations available for an issue
```
GET /api/0/issues/{issue_id}/integrations/
```
Returns array of integrations with their `externalIssues` currently linked.

### Get GitHub integration info for the org (find integration_id)
```
GET /api/0/organizations/{org_slug}/integrations/?provider_key=github
```
Returns array of GitHub integrations. Use `.[0].id` as the `integration_id` for link/create calls.

### List external issues (flat)
```
GET /api/0/issues/{issue_id}/external-issues/
```
Returns flat array of external issue objects. May return empty even when links exist (use the integrations endpoint above instead for reliable data).

### Link existing GitHub issue
```
PUT /api/0/groups/{issue_id}/integrations/{integration_id}/?action=link
Content-Type: application/json

{
  "repo": "org/repo-name",
  "externalIssue": "12345",
  "title": "Issue title text",
  "description": ""
}
```
- **Method**: PUT (not POST — POST creates a new issue)
- All four fields required even though title/description seem redundant for linking
- `repo` must be full `org/repo-name` string
- Returns 201 with `{id, key, url, integrationId, displayName}`

### Create new GitHub issue (linked to Sentry)
```
POST /api/0/groups/{issue_id}/integrations/{integration_id}/
Content-Type: application/json

{
  "repo": "org/repo-name",
  "title": "New issue title",
  "description": "Body markdown text"
}
```
- **Method**: POST (not PUT — PUT is for linking existing issues)
- **Endpoint uses `groups` not `issues`** in the path — both resolve but `groups` is canonical for write operations
- Only three fields needed: `repo`, `title`, `description`
- `repo` must be the full `org/repo-name` string (not numeric ID, not Sentry's internal repo ID)
- Returns 200 with `{id, key, url, integrationId, displayName}` where `key` = `org/repo#number`
- The created GitHub issue is automatically linked in Sentry's sidebar

#### What does NOT work for create:
- PUT method → returns `"Action is required and should be either link or create"`
- Nesting payload under `"externalIssue": {...}` → returns `"Issue ID is required"`
- Using numeric Sentry repo ID for `repo` field → returns `"Repository is required"`
- Adding `?action=create` query param has no effect (POST implies create)

#### Verified example (2026-05-12):
```bash
curl -s -X POST -H "Authorization: Bearer $SENTRY_TOKEN" \
  -H "Content-Type: application/json" \
  "https://sentry.io/api/0/groups/7027765575/integrations/126670/" \
  -d '{"repo": "scientist-hq/rx", "title": "Bug: ...", "description": "..."}'
# → {"id": 4346298, "key": "scientist-hq/rx#36663", "url": "https://github.com/scientist-hq/rx/issues/36663", ...}
```

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
