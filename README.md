# tmux-timer

Visual tmux timer with a 10-step progress bar in `status-right`.

Current control flow:

- `prefix + T`, then `s` to start a new timer
- `prefix + T`, then `p` to pause or resume
- `prefix + T`, then `x` to stop and show `0m`
- `prefix + T`, then `r` to reset to the configured duration

Development load:

```tmux
run-shell ~/.tmux/plugins/tmux-timer/tmux-timer.tmux
```

TPM install:

```tmux
set -g @plugin 'martynasjocius/tmux-timer'
run '~/.tmux/plugins/tpm/tpm'
```

Repo-local development load:

```bash
cd tmux-timer
./tmux-timer.tmux
```

Notes:

- Start prompt accepts `1` to `1440` minutes
- Timer is prepended to `status-right`, so it appears left of the battery segment
- State is stored in tmux global user options prefixed with `@tmux_timer_`
