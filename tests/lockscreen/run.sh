#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "$0")/../.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
cp -a "$repo_dir/dotfiles/quickshell/notchD" "$test_dir/app"
cp "$repo_dir/tests/lockscreen/shell.qml" "$repo_dir/tests/lockscreen/FixtureController.qml" "$test_dir/"
output=$(env -u NIRI_SOCKET DBUS_SESSION_BUS_ADDRESS="unix:path=$test_dir/no-bus" QT_QPA_PLATFORM=offscreen timeout 12 quickshell -p "$test_dir/shell.qml" 2>&1) || { printf '%s\n' "$output"; exit 1; }
printf '%s\n' "$output"
[[ "$output" == *LOCKSCREEN_VISUAL_TESTS_PASSED* ]]
if [[ "$output" == *'FAIL '* || "$output" == *'ReferenceError:'* || "$output" == *'TypeError:'* || "$output" == *'Binding loop detected'* ]]; then exit 1; fi
