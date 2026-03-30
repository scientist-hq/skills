# Agentic Workflow Guide

How to use the agent commands and skills system for RX development.

## Skills System

Structured knowledge lives in `.claude/skills/`. Before implementing any feature, load `.claude/skills/SKILL.md` for the navigation index, then load specific rules and patterns as needed.

- **Sacred Rules** (MUST follow): `.claude/skills/sacred-rules/SR-*.md` — violations block merge
- **Sacred Taste** (SHOULD follow): `.claude/skills/sacred-taste/ST-*.md` — improve quality
- **Patterns** (Reference): `.claude/skills/patterns/PT-*.md` — real codebase templates

## Agent Commands

Use these slash commands for specialized workflows:

| Command | Agent | What It Does |
|---------|-------|-------------|
| `/architect <feature>` | Senior Architect | Researches codebase, produces implementation plan in `plans/` |
| `/bug <#issue or description>` | Senior Debugger | Investigates root cause, reproduces with failing test, applies minimal fix |
| `/implement <plan>` | Senior Engineer | Implements an approved plan using Red-Green-Refactor |
| `/review [target]` | Code Reviewer | Reviews changes against Sacred Rules, produces structured report |
| `/test <code>` | Test Engineer | Writes/improves RSpec tests, analyzes coverage gaps |
| `/infra <task>` | Infra Architect | Researches cross-repo, produces infrastructure plan (read-only) |
| `/qa [context]` | QA Engineer | Sets up local env, creates manual test plan, helps verify |
| `/commit` | Commit Organizer | Groups changes into logical bite-sized commits |
| `/pr [#issue]` | PR Creator | Safety checks, creates draft PR with correct labels and format |
| `/explain [target]` | Codebase Mentor | Explains code, history, architecture, and how changes fit in |

## Recommended Feature Development Flow

```
1. /architect <feature>     → Plan in plans/<feature>.md
   (Review and approve plan)

2. /test <planned-code>     → Failing specs that define behavior
   (Review test coverage)

3. /implement <plan-file>   → Step-by-step implementation
   (Review after each step, commit when satisfied)

4. /review                  → Structured review with MUST-FIX and SUGGESTIONS
   (Decide which suggestions to address)

5. /commit                  → Groups changes into logical commits
   (Review proposed breakdown, confirm)

6. /pr #<issue>             → Draft PR with labels, linked issue, QA instructions

7. Debrief: "Was there anything surprising?"
```

### Bug Fix Flow

```
1. /bug #<issue>            → Diagnoses root cause, presents findings
   (Review diagnosis, confirm approach)

2. Agent writes failing reproduction test, applies minimal fix

3. /qa                      → Set up local env, test data, manual test plan
   (Run through the test plan locally)

4. /review                  → Check the fix against Sacred Rules

5. /commit                  → Group changes (test + fix)

6. /pr #<issue>             → Draft PR with Type: Fix label
```

### Infrastructure Flow

```
1. /infra <task>            → Researches across repos, produces plan in plans/
   (Review plan — which repos, what changes, deploy order, risks)

2. Implement manually or hand off to /implement for RX-only changes

3. /qa                      → Verify locally if needed

4. /commit → /pr            → For each repo that needs a PR
```

### Learning Flow (use anytime)

```
/explain                    → Explains current branch changes in context
/explain <file or feature>  → Deep dive into any part of the system
```

## Post-Feature Learning

After completing a feature, update skills if needed:
- Sacred Rule violated during implementation? → Add or clarify rule in `.claude/skills/sacred-rules/`
- New pattern emerged? → Add `PT-XX` pattern file in `.claude/skills/patterns/`
- Reviewer caught something the engineer should have known? → Promote to Sacred Rule
