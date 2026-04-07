#!/usr/bin/env bash

set -eu

tmux_get() {
  tmux show-option -gqv "$1"
}

state="$(tmux_get @tmux_timer_state)"
running="$(tmux_get @tmux_timer_running)"
duration_min="$(tmux_get @tmux_timer_duration_min)"
started_at="$(tmux_get @tmux_timer_started_at)"
accumulated_sec="$(tmux_get @tmux_timer_accumulated_sec)"

case "$state" in
  '')
    exit 0
    ;;
esac

case "$duration_min" in
  ''|*[!0-9]*)
    exit 0
    ;;
esac

case "$started_at" in
  ''|*[!0-9]*)
    started_at=0
    ;;
esac

case "$accumulated_sec" in
  ''|*[!0-9]*)
    accumulated_sec=0
    ;;
esac

duration_sec=$((duration_min * 60))
elapsed_sec="$accumulated_sec"

if [ "$state" = "stopped" ]; then
  elapsed_sec=0
fi

if [ "$running" = "1" ] && [ "$started_at" -gt 0 ]; then
  now_epoch="$(date +%s)"
  if [ "$now_epoch" -gt "$started_at" ]; then
    elapsed_sec=$((elapsed_sec + now_epoch - started_at))
  fi
fi

if [ "$elapsed_sec" -ge "$duration_sec" ]; then
  elapsed_sec="$duration_sec"
  if [ "$running" = "1" ]; then
    tmux set-option -gq @tmux_timer_running "0"
    tmux set-option -gq @tmux_timer_started_at "0"
    tmux set-option -gq @tmux_timer_accumulated_sec "$duration_sec"
    tmux set-option -gq @tmux_timer_state "done"
  fi
fi

remaining_sec=$((duration_sec - elapsed_sec))
filled_slots=$((elapsed_sec * 10 / duration_sec))

if [ "$filled_slots" -gt 10 ]; then
  filled_slots=10
fi

if [ "$remaining_sec" -le 0 ]; then
  remaining_min=0
else
  remaining_min=$(((remaining_sec + 59) / 60))
fi

if [ "$state" = "stopped" ]; then
  remaining_min=0
fi

palette="39 45 51 50 49 48 179 215 214 208"
set -- $palette
active_clock_color='colour39'

case "$state" in
  stopped)
    printf '#[fg=colour255,bg=default]◷ '
    label_color='colour250'
    ;;
  running)
    printf '#[fg=%s,bg=default]◷ ' "$active_clock_color"
    label_color='colour255'
    ;;
  paused)
    printf '#[fg=%s,bg=default]◴ ' "$active_clock_color"
    label_color='colour255'
    ;;
  done)
    printf '#[fg=%s,bg=default]◹ ' "$active_clock_color"
    label_color='colour255'
    ;;
esac

slot=1
for color in "$@"; do
  if [ "$slot" -le "$filled_slots" ]; then
    printf '#[fg=colour%s]▰' "$color"
  else
    printf '#[fg=colour238]▱'
  fi
  slot=$((slot + 1))
done
printf '#[fg=%s] %sm #[default]' "$label_color" "$remaining_min"
