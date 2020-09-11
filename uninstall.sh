#!/usr/bin/env bash
set -eux

if [ -e /usr/local/bin/thingshub ]; then
	rm -f /usr/local/bin/thingshub
fi

if [ -e "$HOME/Library/LaunchAgents/com.dzombak.thingshubd.plist" ]; then
	launchctl unload -w "$HOME/Library/LaunchAgents/com.dzombak.thingshubd.plist"
	rm -f "$HOME/Library/LaunchAgents/com.dzombak.thingshubd.plist"
fi

if [ -e /usr/local/opt/thingshubd ]; then
	rm -rf /usr/local/opt/thingshubd
fi
