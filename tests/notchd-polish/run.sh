#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "$0")/../.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
cp -a "$repo_dir/dotfiles/quickshell/notchD" "$test_dir/app"
cp "$repo_dir/tests/notchd-polish/shell.qml" "$test_dir/shell.qml"
cp -a "$repo_dir/tests/notchd-polish/mocks" "$test_dir/app/services/mocks"
sed -i 's/import Quickshell.Services.Mpris/import "mocks"/' "$test_dir/app/services/Media.qml"
output=$(env PATH="$repo_dir/dotfiles/bin:$PATH" DBUS_SESSION_BUS_ADDRESS=unix:path="$test_dir/no-bus" QT_QPA_PLATFORM=offscreen timeout 10 quickshell -p "$test_dir/shell.qml" 2>&1)
printf '%s\n' "$output"
[[ "$output" == *POLISH_TESTS_PASSED* ]]
if [[ "$output" == *'ReferenceError:'* || "$output" == *'TypeError:'* || "$output" == *'Binding loop detected'* ]]; then exit 1; fi
