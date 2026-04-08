#!/usr/bin/env bash

set -eu

tmux_get() {
  tmux show-option -gqv "$1"
}

resolve_theme() {
  case "$1" in
    ''|spectrum)
      printf '%s\n' \
        "93 99 39 45 51 50 49 48 179 215 214 208|colour222|colour141|colour244|gradient"
      ;;
    ocean)
      printf '%s\n' \
        "33 33 33 33 33 33 33 33 33 33 33 33|colour39|colour45|colour244|solid"
      ;;
    forest)
      printf '%s\n' \
        "34 34 34 34 34 34 34 34 34 34 34 34|colour130|colour22|colour244|solid"
      ;;
    mono)
      printf '%s\n' \
        "250 250 250 250 250 250 250 250 250 250 250 250|colour250|colour255|colour244|solid"
      ;;
    levander)
      printf '%s\n' \
        "120 120 120 120 120 120 120 120 120 120 120 120|colour183|colour120|colour244|solid"
      ;;
    *)
      resolve_theme "spectrum"
      ;;
  esac
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

escape_status_text() {
  printf '%s' "$1" | sed 's/#/##/g'
}

state="$(tmux_get @tmux_timer_state)"
running="$(tmux_get @tmux_timer_running)"
duration_min="$(tmux_get @tmux_timer_duration_min)"
started_at="$(tmux_get @tmux_timer_started_at)"
accumulated_sec="$(tmux_get @tmux_timer_accumulated_sec)"
task_label="$(tmux_get @tmux_timer_task_label)"
theme_name="$(tmux_get @tmux_timer_theme)"

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

theme_config="$(resolve_theme "$theme_name")"
IFS='|' read -r palette_colors main_color active_color inactive_color theme_mode <<EOF
$theme_config
EOF

case "$state" in
  stopped)
    label_color="$inactive_color"
    elapsed_label_color="$inactive_color"
    ;;
  running)
    if [ "$theme_mode" = "gradient" ]; then
      label_color="$main_color"
      elapsed_label_color="$active_color"
    else
      label_color="$main_color"
      elapsed_label_color="$active_color"
    fi
    ;;
  paused)
    if [ "$theme_mode" = "gradient" ]; then
      label_color="$main_color"
      elapsed_label_color='colour255'
    else
      label_color="$main_color"
      elapsed_label_color="$active_color"
    fi
    ;;
  done)
    label_color="$inactive_color"
    elapsed_label_color="$inactive_color"
    ;;
esac

icon_color="$elapsed_label_color"
escaped_task_label="$(escape_status_text "$task_label")"

if [ "$state" = "running" ]; then
  if [ "$theme_mode" = "gradient" ]; then
    icon_color="$active_color"
  else
    icon_color="$elapsed_label_color"
  fi
fi

printf '#[fg=%s]#[default]' "$icon_color"
if [ -n "$escaped_task_label" ]; then
  printf '  #[fg=%s]%s#[default]' "$label_color" "$escaped_task_label"
  printf ' #[fg=%s]%sm#[default] ' "$elapsed_label_color" "$elapsed_min"
else
  printf '  #[fg=%s]%sm#[default] ' "$elapsed_label_color" "$elapsed_min"
fi
slot=1
for color in $palette_colors; do
  if [ "$slot" -le "$filled_slots" ]; then
    if [ "$theme_mode" = "gradient" ]; then
      printf '#[fg=colour%s]▮' "$color"
    else
      printf '#[fg=%s]▮' "$active_color"
    fi
  else
    printf '#[fg=%s]▯' "$label_color"
  fi
  slot=$((slot + 1))
done
printf '#[fg=%s] %sm #[default]' "$label_color" "$duration_min"
