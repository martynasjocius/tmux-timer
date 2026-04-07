#!/usr/bin/env bash

set -eu

command_name="${1:-}"
minutes_arg="${2:-}"

tmux_get() {
  tmux show-option -gqv "$1"
}

tmux_set() {
  tmux set-option -gq "$1" "$2"
}

play_sound() {
  sound_name="$1"
  timer_dir="$(tmux_get @tmux_timer_dir)"
  if [ -n "$timer_dir" ]; then
    "$timer_dir/scripts/play-sound.sh" "$sound_name" >/dev/null 2>&1 &
  fi
}

activate_refresh() {
  saved_interval="$(tmux_get @tmux_timer_status_interval_saved)"
  if [ -z "$saved_interval" ]; then
    tmux_set @tmux_timer_status_interval_saved "$(tmux_get status-interval)"
  fi
  tmux set-option -gq status-interval 5
}

restore_refresh() {
  saved_interval="$(tmux_get @tmux_timer_status_interval_saved)"
  if [ -n "$saved_interval" ]; then
    tmux set-option -gq status-interval "$saved_interval"
    tmux_set @tmux_timer_status_interval_saved ""
  fi
}

now_epoch() {
  date +%s
}

duration_min="$(tmux_get @tmux_timer_duration_min)"
state="$(tmux_get @tmux_timer_state)"
running="$(tmux_get @tmux_timer_running)"
started_at="$(tmux_get @tmux_timer_started_at)"
accumulated_sec="$(tmux_get @tmux_timer_accumulated_sec)"

case "$duration_min" in
  ''|*[!0-9]*)
    duration_min=25
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

start_new() {
  if [ -z "$minutes_arg" ]; then
    tmux display-message "timer: missing minutes"
    exit 1
  fi

  case "$minutes_arg" in
    ''|*[!0-9]*)
      tmux display-message "timer: minutes must be 1-1440"
      exit 1
      ;;
  esac

  if [ "$minutes_arg" -lt 1 ] || [ "$minutes_arg" -gt 1440 ]; then
    tmux display-message "timer: minutes must be 1-1440"
    exit 1
  fi

  current_now="$(now_epoch)"
  tmux_set @tmux_timer_duration_min "$minutes_arg"
  tmux_set @tmux_timer_accumulated_sec "0"
  tmux_set @tmux_timer_started_at "$current_now"
  tmux_set @tmux_timer_running "1"
  tmux_set @tmux_timer_state "running"
  activate_refresh
  play_sound start
  tmux display-message "timer: started ${minutes_arg}m"
}

stop_timer() {
  tmux_set @tmux_timer_running "0"
  tmux_set @tmux_timer_started_at "0"
  tmux_set @tmux_timer_accumulated_sec "0"
  tmux_set @tmux_timer_state "stopped"
  restore_refresh
  tmux display-message "timer: stopped"
}

case "$command_name" in
  start)
    start_new
    ;;
  stop)
    stop_timer
    ;;
  *)
    tmux display-message "timer: unknown command"
    exit 1
    ;;
esac
