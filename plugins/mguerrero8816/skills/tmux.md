---
description: Rules for sending commands to tmux panes, including Claude Code TUI sessions.
---

## Always Send a Separate Enter

Never rely on `Enter` in the same `send-keys` call — always follow up with a second call.

- ❌ BAD: `tmux send-keys -t 0:0 "some text" Enter`
- ✅ GOOD:
  ```
  tmux send-keys -t 0:0 "your message here" Enter
  tmux send-keys -t 0:0 "" Enter
  ```

This applies to all tmux panes, including Claude Code TUI sessions.
