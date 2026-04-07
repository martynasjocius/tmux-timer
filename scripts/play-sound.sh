#!/usr/bin/env bash

set -eu

sound_name="${1:-}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
timer_dir="$(cd "$script_dir/.." && pwd)"

if [ "$(tmux show-option -gqv @tmux_timer_sound_enabled)" != "1" ]; then
  exit 0
fi

case "$sound_name" in
  start)
    sound_file="$timer_dir/assets/sounds/timer-start.wav"
    ;;
  end)
    sound_file="$timer_dir/assets/sounds/timer-end.wav"
    ;;
  *)
    exit 1
    ;;
esac

[ -f "$sound_file" ] || exit 0

if command -v paplay >/dev/null 2>&1; then
  exec paplay "$sound_file"
fi

exit 0
