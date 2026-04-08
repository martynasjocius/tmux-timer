# tmux-timer

A keyboard-first timer for tmux that lives in your status line.

Start a focused work session, keep the countdown visible in every pane, attach a short task label, and switch themes without leaving tmux.

## Why Use It

- Keeps a live timer in the status line instead of a separate window or app
- Works well for Pomodoro sessions, deep work blocks, and ad hoc countdowns
- Controlled entirely from tmux key bindings
- Supports task labels and preset themes
- Plays a soft sound when a timer starts or finishes

## Features

- Status-line timer with elapsed time, total time, and visual progress
- Start, stop, and theme switching from tmux commands
- Optional inline task label
- Preset themes: `levander`, `spectrum`, `ocean`, `forest`, `mono`
- Remembers the last used duration
- Supports timers from `1` to `1440` minutes

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

Default key bindings:

- `prefix + T`, then `s` to start a timer
- `prefix + T`, then `x` to stop the current timer
- `prefix + T`, then `t` to switch theme

Starting a timer opens a prompt prefilled with the last used duration.

Examples:

- `25`
- `25 write docs`
- `90 deep work`

Task labels are displayed inline in the status line and truncated automatically when needed.

## Configuration

Default theme:

```tmux
set -g @tmux_timer_theme 'levander'
```

Available themes:

- `levander`
- `spectrum`
- `ocean`
- `forest`
- `mono`

Sound alerts:

```tmux
set -g @tmux_timer_sound_enabled '1'
```

Disable sounds:

```tmux
set -g @tmux_timer_sound_enabled '0'
```

## Notes

- The plugin adds its segment to `status-right`
- The clock icon uses a Nerd Font glyph, so a Nerd Font-enabled terminal is recommended
- Theme changes can be made either in tmux config or from the `prefix + T`, then `t` prompt

## Development

From the repo root:

```bash
./tmux-timer.tmux
```

## Author

Created by Martynas Jocius.

## License

[MIT](./LICENSE)
