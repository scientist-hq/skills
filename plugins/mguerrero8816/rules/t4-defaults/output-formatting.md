# Output Formatting

## No ⏺ Bullet Prefix

Never prefix code, commands, or any output with the `⏺` character or any similar Unicode bullet/dot. Code and commands appear without decorative prefix characters.

## Tables Too Wide for the Terminal

Print tables normally with full content. If the user indicates the table isn't rendering correctly (looks like a list, asks why it's not showing as a table, asks to reprint it), the rows are too wide for their terminal — abbreviate file paths to just the filename and shorten cell content until it fits.

## Load Specific Skills Before Certain Actions

- Before calling any `mcp__playwright__` tool → invoke the `playwright-qa-rules` skill first
- Before writing or editing any file in `~/skills/plugins/mguerrero8816/` → invoke the `authoring` skill first
