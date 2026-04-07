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

pause_or_resume() {
  current_now="$(now_epoch)"

  if [ "$running" = "1" ]; then
    elapsed="$accumulated_sec"
    if [ "$started_at" -gt 0 ] && [ "$current_now" -gt "$started_at" ]; then
      elapsed=$((elapsed + current_now - started_at))
    fi
    tmux_set @tmux_timer_accumulated_sec "$elapsed"
    tmux_set @tmux_timer_running "0"
    tmux_set @tmux_timer_started_at "0"
    tmux_set @tmux_timer_state "paused"
    tmux display-message "timer: paused"
    exit 0
  fi

  if [ "$state" = "paused" ] || [ "$state" = "done" ]; then
    tmux_set @tmux_timer_running "1"
    tmux_set @tmux_timer_started_at "$current_now"
    tmux_set @tmux_timer_state "running"
    tmux display-message "timer: resumed"
    exit 0
  fi

  tmux display-message "timer: nothing to resume"
}

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
  tmux display-message "timer: started ${minutes_arg}m"
}

stop_timer() {
  tmux_set @tmux_timer_running "0"
  tmux_set @tmux_timer_started_at "0"
  tmux_set @tmux_timer_accumulated_sec "0"
  tmux_set @tmux_timer_state "stopped"
  tmux display-message "timer: stopped"
}

reset_timer() {
  tmux_set @tmux_timer_running "0"
  tmux_set @tmux_timer_started_at "0"
  tmux_set @tmux_timer_accumulated_sec "0"
  tmux_set @tmux_timer_state "paused"
  tmux display-message "timer: reset to ${duration_min}m"
}

case "$command_name" in
  start)
    start_new
    ;;
  pause)
    pause_or_resume
    ;;
  stop)
    stop_timer
    ;;
  reset)
    reset_timer
    ;;
  *)
    tmux display-message "timer: unknown command"
    exit 1
    ;;
esac
