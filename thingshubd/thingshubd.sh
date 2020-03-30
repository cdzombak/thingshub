#!/usr/bin/env bash
THINGSHUBD_CONFIG=${THINGSHUBD_CONFIG:-$HOME/.local/thingshubd.list}
THINGSHUBD_DEBUG=${THINGSHUBD_DEBUG:-false}
THINGSHUBD_SHOW_NOTIFICATIONS=${THINGSHUBD_SHOW_NOTIFICATIONS:-true}
PATH="/usr/local/bin:$PATH"
set -eu

use_terminal_notifier=true
command -v terminal-notifier >/dev/null 2>&1 || use_terminal_notifier=false
if [ "$THINGSHUBD_DEBUG" = true ]; then
  if [ "$use_terminal_notifier" = true ]; then
    >&2 echo "[debug] found terminal-notifier at $(command -v terminal-notifier)"
  else
    >&2 echo "[debug] terminal-notifier not found"
  fi
fi

if [ "$THINGSHUBD_SHOW_NOTIFICATIONS" = false ]; then
  if [ "$THINGSHUBD_DEBUG" = true ]; then
    >&2 echo "[debug] notifications will be hidden due to THINGSHUBD_SHOW_NOTIFICATIONS"
  fi
  use_terminal_notifier=false
fi

show_msg() {
  >&2 echo "$1"
  if [ "$use_terminal_notifier" = true ]; then
    escaped_msg=$(echo "$1" | sed -e '/^\[/ s/^\[/\\\[/')
    terminal-notifier -message "$escaped_msg" -title "ThingsHub Sync" -subtitle "$(date +"%A %T")" -sender com.culturedcode.ThingsMac -activate com.culturedcode.ThingsMac
  fi
}

if [ ! -f "$THINGSHUBD_CONFIG" ]; then
  show_msg "Sync Failed: Config file not found at $THINGSHUBD_CONFIG"
  exit 2
fi

verbose_flag=""

if [ "$THINGSHUBD_DEBUG" = true ]; then
  verbose_flag="-verbose"
  show_msg "Sync is running."
fi

while read -r dir; do
  dir="${dir//\$HOME/$HOME}"
  if [ ! -d "$dir" ]; then
    show_msg "Failed to sync $(basename "$dir"): not found"
    continue
  fi
  pushd "$dir" >/dev/null
  >&2 echo "Syncing '$dir' ..."
  thingshub $verbose_flag
  popd >/dev/null
  show_msg "Sync complete for $(basename "$dir")"
done <"$THINGSHUBD_CONFIG"

osascript -e "tell application \"Things3\" to show list \"Today\""
