#!/usr/bin/env bash

set -eu

command_name="${1:-}"
if [ "$#" -gt 0 ]; then
  shift
fi
start_input="$*"

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
  tmux set-option -gq status-interval 2
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
task_label="$(tmux_get @tmux_timer_task_label)"

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
  if [ -z "$start_input" ]; then
    tmux display-message "timer: missing minutes"
    exit 1
  fi

  minutes_arg="${start_input%% *}"
  if [ "$minutes_arg" = "$start_input" ]; then
    task_label=""
  else
    task_label="${start_input#"$minutes_arg"}"
    while [ "${task_label# }" != "$task_label" ]; do
      task_label="${task_label# }"
    done
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
  tmux_set @tmux_timer_task_label "$task_label"
  activate_refresh
  play_sound start
  if [ -n "$task_label" ]; then
    tmux display-message "timer: started ${minutes_arg}m ${task_label}"
  else
    tmux display-message "timer: started ${minutes_arg}m"
  fi
}

stop_timer() {
  tmux_set @tmux_timer_running "0"
  tmux_set @tmux_timer_started_at "0"
  tmux_set @tmux_timer_accumulated_sec "0"
  tmux_set @tmux_timer_state "stopped"
  tmux_set @tmux_timer_task_label ""
  restore_refresh
  tmux display-message "timer: stopped"
}

set_theme() {
  case "$start_input" in
    spectrum|ocean|forest|mono|levander)
      tmux_set @tmux_timer_theme "$start_input"
      tmux display-message "timer: theme set to $start_input"
      ;;
    *)
      tmux display-message "timer: theme must be spectrum, ocean, forest, mono, or levander"
      exit 1
      ;;
  esac
}

case "$command_name" in
  start)
    start_new
    ;;
  stop)
    stop_timer
    ;;
  theme)
    set_theme
    ;;
  *)
    tmux display-message "timer: unknown command"
    exit 1
    ;;
esac
