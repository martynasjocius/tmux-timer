# tmux-timer

A small visual timer plugin for tmux.

It adds a colored progress bar to the status line and lets you see and control the timer from any pane, window, or session.

Useful for Pomodoro sessions, focused coding blocks, or custom work/break routines.

## Features

- Visual 12-step progress bar
- `1` to `1440` minute timers
- Start and stop controls
- Soft sound on start and completion
- Uses `status-right`, so it can sit next to items like battery status

## Install

With TPM:

```tmux
set -g @plugin 'martynasjocius/tmux-timer'
run '~/.tmux/plugins/tpm/tpm'
```

Manual load:

```tmux
run-shell ~/.tmux/plugins/tmux-timer/tmux-timer.tmux
```

## Usage

- `prefix + T`, then `s` to start
- `prefix + T`, then `x` to stop

Start opens a prompt with the last used duration. The initial default is `25` minutes.

You can optionally add a task label after the duration:

- `2`
- `2 few words`

## Development

From the repo root:

```bash
./tmux-timer.tmux
```

---

Created by Martynas Jocius.
