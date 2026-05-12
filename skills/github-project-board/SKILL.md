---
name: github-project-board
description: "Team gits GitHub ProjectV2 board: iteration schedules, pointing workflow, demo reminders."
---

# GitHub Project Board — Team Gits

Reference for the `scientist-hq` ProjectV2 board (#45, "team gits") — iteration structure, pointing workflow, and automation patterns.

## Board Structure

- **Board**: scientist-hq/projects/45
- **Iterations**: 14-day sprints, Saturday → Friday
- **Demo day**: Friday 9am PT (last day of iteration)
- **Slack channel**: C0A6SBPBYCD

## Iteration Schedule

- Iterations start on Saturday, end on Friday
- Duration is typically 14 days but varies (holidays cause 7, 12, or 21-day iterations)
- End date = `startDate + duration - 1`
- **Never hardcode 14 days** — always compute from `startDate + duration`

## Pointing Workflow

### Collecting Estimates

When pointing issues in a thread:
- Team members reply with their estimate (story points)
- **Auto-set rule**: When 2 team members agree on the same value, set the estimate immediately — no need to wait for further votes

### Setting Estimates

Use the `set-project-estimate.sh` script:

```bash
bash ~/.hermes/scripts/set-project-estimate.sh <repo> <issue_number> <estimate>
```

The script:
- Accepts `<repo>` as first arg (e.g. `rx`, `benchmate`, `benchmate_tools`)
- Self-sources `GITHUB_TOKEN` from `~/.env` if not already set
- No `op run` or manual export needed

## Querying Iteration Data

### GraphQL Query

```graphql
{
  organization(login: "scientist-hq") {
    projectV2(number: 45) {
      fields(first: 30) {
        nodes {
          ... on ProjectV2IterationField {
            id
            name
            configuration {
              iterations {
                id
                title
                startDate
                duration
              }
              completedIterations {
                id
                title
                startDate
                duration
              }
            }
          }
        }
      }
    }
  }
}
```

### Auth Pattern

```python
import os
token = None
env_path = os.path.expanduser('~/.env')
if os.path.exists(env_path):
    with open(env_path) as f:
        for line in f:
            if line.startswith('GITHUB_API_TOKEN='):
                token = line.strip().split('=', 1)[1]
                break
env = os.environ.copy()
env['GITHUB_TOKEN'] = token
```

### Key Facts

- Both active (`iterations`) and past (`completedIterations`) are returned
- Iteration titles can vary (e.g. "Iteration 60 (Maintenance)") — don't assume numeric-only
- Duplicate iteration titles exist (e.g. two "Iteration 74" with different dates) — match on `startDate`, not just title

## Automation Patterns

### Script + Cron Pattern

The recommended approach for board-driven automation:

1. **Python script** in `~/.hermes/scripts/` that:
   - Queries the ProjectV2 GraphQL API for iteration/field data
   - Evaluates whether today matches the trigger condition
   - Prints the message if yes, exits silently if no

2. **Cron job** runs the script on a regular schedule and delivers output to Slack

### Example: Demo Day Reminder

```bash
# Script fires every Thursday at 1pm, delivers to Slack channel
hermes cron create \
  --name demo-party-reminder \
  --schedule "0 13 * * 4" \
  --script demo-party-reminder.py \
  --deliver slack:C0A6SBPBYCD \
  --enabled-toolsets web
```

### Pairing: Reminder + Audit

Best practice — pair delivery crons with audit crons that catch schedule drift:

| Job | Schedule | Purpose | Deliver |
|-----|----------|---------|---------|
| demo reminder | Thu 1pm | Post reminder if demo is tomorrow | slack:CHANNEL |
| schedule audit | Mon 8am | Check for unusual durations or non-Friday endings | local |

## Pitfalls

1. **Iteration duration varies** — holidays cause non-standard durations. Always compute from `startDate + duration`.
2. **Demo ≠ last day** — demo is Friday (last day of iteration). Confirm with team if this ever shifts.
3. **GitHub token** — scripts use `gh` CLI which needs `GITHUB_TOKEN`. Source from `~/.env` as `GITHUB_API_TOKEN`.
4. **Cron schedule timezone** — cron schedules run in the system's local timezone (Pacific).
5. **Slack `@here`** — use `<!here>` in output text for Slack notifications.
