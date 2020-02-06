#!/usr/bin/env bash
set -eux

mkdir -p /usr/local/opt/thingshubd/bin
cp -f ./thingshubd.sh /usr/local/opt/thingshubd/bin/thingshubd
chmod +x /usr/local/opt/thingshubd/bin/thingshubd

mkdir -p "$HOME/Library/LaunchAgents/"
if launchctl list | grep -c com.dzombak.thingshubd >/dev/null; then
  launchctl unload "$HOME/Library/LaunchAgents/com.dzombak.thingshubd.plist"
  rm -f "$HOME/Library/LaunchAgents/com.dzombak.thingshubd.plist"
fi
cp -f ./com.dzombak.thingshubd.plist "$HOME/Library/LaunchAgents/"
launchctl load "$HOME/Library/LaunchAgents/com.dzombak.thingshubd.plist"

if [ ! -f "$HOME/.local/thingshubd.list" ]; then
  mkdir -p "$HOME/.local"
  cp ./thingshubd.list.example "$HOME/.local/thingshubd.list"
fi
