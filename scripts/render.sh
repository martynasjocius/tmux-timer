#!/usr/bin/env bash

set -eu

tmux_get() {
  tmux show-option -gqv "$1"
}

play_sound() {
  sound_name="$1"
  timer_dir="$(tmux_get @tmux_timer_dir)"
  if [ -n "$timer_dir" ]; then
    "$timer_dir/scripts/play-sound.sh" "$sound_name" >/dev/null 2>&1 &
  fi
}

tmux_restore_refresh() {
  saved_interval="$(tmux_get @tmux_timer_status_interval_saved)"
  if [ -n "$saved_interval" ]; then
    tmux set-option -gq status-interval "$saved_interval"
    tmux set-option -gq @tmux_timer_status_interval_saved ""
  fi
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
segment_count=12

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
    tmux_restore_refresh
    play_sound end
    running="0"
    state="done"
  fi
fi

remaining_sec=$((duration_sec - elapsed_sec))
filled_slots=$((elapsed_sec * segment_count / duration_sec))

if [ "$filled_slots" -gt "$segment_count" ]; then
  filled_slots="$segment_count"
fi

if [ "$remaining_sec" -le 0 ]; then
  remaining_min=0
else
  remaining_min=$(((remaining_sec + 59) / 60))
fi

elapsed_min=$((elapsed_sec / 60))

if [ "$state" = "stopped" ]; then
  remaining_min=0
  elapsed_min=0
fi

palette="93 99 39 45 51 50 49 48 179 215 214 208"
set -- $palette
palette_colors="$*"
case "$state" in
  stopped)
    label_color='colour244'
    elapsed_label_color='colour244'
    ;;
  running)
    label_color='colour215'
    elapsed_label_color='colour141'
    ;;
  paused)
    label_color='colour215'
    elapsed_label_color='colour255'
    ;;
  done)
    label_color='colour244'
    elapsed_label_color='colour244'
    ;;
esac

icon_color="$elapsed_label_color"

if [ "$state" = "running" ]; then
  set -- $palette_colors
  active_slot="$filled_slots"
  if [ "$active_slot" -lt 1 ]; then
    active_slot=1
  fi
  index=1
  for color in "$@"; do
    if [ "$index" -eq "$active_slot" ]; then
      icon_color="colour${color}"
      break
    fi
    index=$((index + 1))
  done
fi

printf '#[fg=%s]  #[fg=%s]%sm #[default]' "$icon_color" "$elapsed_label_color" "$elapsed_min"
slot=1
for color in $palette_colors; do
  if [ "$slot" -le "$filled_slots" ]; then
    printf '#[fg=colour%s]▮' "$color"
  else
    printf '#[fg=colour%s]▯' "$color"
  fi
  slot=$((slot + 1))
done
printf '#[fg=%s] %sm #[default]' "$label_color" "$duration_min"
