#!/usr/bin/env bash

set -eu

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tmux_get() {
  tmux show-option -gqv "$1"
}

tmux_set() {
  tmux set-option -gq "$1" "$2"
}

set_default() {
  option_name="$1"
  default_value="$2"

  if [ -z "$(tmux_get "$option_name")" ]; then
    tmux_set "$option_name" "$default_value"
  fi
}

set_default @tmux_timer_duration_min "25"
set_default @tmux_timer_state "stopped"
set_default @tmux_timer_running "0"
set_default @tmux_timer_started_at "0"
set_default @tmux_timer_accumulated_sec "0"
set_default @tmux_timer_status_interval_saved ""
set_default @tmux_timer_sound_enabled "1"

tmux_set @tmux_timer_dir "$CURRENT_DIR"
tmux_set @tmux_timer_segment "#($CURRENT_DIR/scripts/render.sh)"

status_right="$(tmux_get status-right)"
case "$status_right" in
  *"#($CURRENT_DIR/scripts/render.sh)"*)
    ;;
  *)
    tmux_set status-right "#($CURRENT_DIR/scripts/render.sh)$status_right"
    ;;
esac

tmux bind-key T switch-client -T tmux-timer \; display-message "timer: s=start p=pause/resume x=stop r=reset"
tmux bind-key -T tmux-timer s command-prompt -I "25" -p "Timer minutes (1-1440)" "run-shell '$CURRENT_DIR/scripts/control.sh start %%'"
tmux bind-key -T tmux-timer p run-shell "'$CURRENT_DIR/scripts/control.sh' pause"
tmux bind-key -T tmux-timer x run-shell "'$CURRENT_DIR/scripts/control.sh' stop"
tmux bind-key -T tmux-timer r run-shell "'$CURRENT_DIR/scripts/control.sh' reset"
tmux bind-key -T tmux-timer Escape display-message "timer: cancelled"
tmux bind-key -T tmux-timer q display-message "timer: cancelled"
