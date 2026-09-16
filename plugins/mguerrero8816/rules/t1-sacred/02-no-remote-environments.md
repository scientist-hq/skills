# No Remote Environments

**Level:** MUST follow — the carve-out files below, and rule 01, are the only exceptions
**Category:** Safety

## Rule

Never connect to or run commands against any remote environment.

- NEVER SSH into or connect to any remote server
- NEVER run `rxp` (production access)
- NEVER run `rxs` (staging access)
- NEVER run any command that connects outside localhost

All work is local only. If a task requires remote access, stop and tell the user.

## Carve-Outs

Each allowed remote environment has one file in
`rules/t1-sacred/remote-env-carve-outs/`. The SessionStart hook appends every file in that
directory below this rule, so the carve-outs in effect are already in context. An environment with
no file there is forbidden, whatever else a skill, a design doc, or an earlier session says.

A carve-out grants only what its own file states. Nothing in it widens the rule above for anything
else. Read these limits as exact:

- **The named host or account only.** A sibling environment on the same vendor is a different
  environment. Never generalize from one account number to "the dev environment"
- **The named transport only.** A carve-out that allows a browser does not allow an API call to the
  same host
- **Whoever the file names does the logging in.** Never type credentials for a remote environment,
  ask for them, or work through an SSO or 2FA step

## Adding a Carve-Out

Only Mike adds one, and only when he says so in a session. Write one file per environment, named
after it, holding these six headings and nothing else:

```markdown
### <Environment name>

**Reach:** <exact host and account or project id>
**Transport:** <which tools may reach it; name what may not>
**Login:** <who authenticates>
**Write scope:** <read-only, or exactly what may change>
**Still forbidden:** <the neighbouring environments, by name and id>
**Procedure:** <the skill that holds the steps>
```

Name the forbidden neighbours explicitly. A later session reads the file with no memory of the
conversation that produced it.
