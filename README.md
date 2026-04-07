# Visual Tmux Timer

A simple visual timer for tmux.

It adds a colored progress bar to the status line and makes it easy to start, pause, stop, and reset a timer.

## Features

- Visual 12-step progress bar
- `1` to `1440` minute timers
- Start, pause, stop, and reset controls
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
- `prefix + T`, then `p` to pause or resume
- `prefix + T`, then `x` to stop
- `prefix + T`, then `r` to reset

Start opens a prompt with a default of `25` minutes.

## Development

From the project directory:

```bash
./tmux-timer.tmux
```

---

Created by Martynas Jocius.
