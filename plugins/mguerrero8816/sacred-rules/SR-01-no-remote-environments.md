# SR-01: No Remote Environments

**Level:** MUST follow — no exceptions, no overrides
**Category:** Safety

## Rule

Never connect to or run commands against any remote environment.

- NEVER SSH into or connect to any remote server
- NEVER run `rxp` (production access)
- NEVER run `rxs` (staging access)
- NEVER run any command that connects outside localhost

All work is local only. If a task requires remote access, stop and tell the user.
