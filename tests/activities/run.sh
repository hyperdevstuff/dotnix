#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "$0")/../.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
mkdir -p "$test_dir/services" "$test_dir/runtime"
chmod 700 "$test_dir/runtime"
cp "$repo_dir/dotfiles/quickshell/notchD/services/Privacy.qml" "$repo_dir/dotfiles/quickshell/notchD/services/KeepAwake.qml" "$test_dir/services/"
sed 's|../../dotfiles/quickshell/notchD/services|services|' "$repo_dir/tests/activities/shell.qml" > "$test_dir/shell.qml"
output=$(env -u NIRI_SOCKET -u WAYLAND_DISPLAY -u PIPEWIRE_REMOTE -u PIPEWIRE_RUNTIME_DIR QT_QPA_PLATFORM=offscreen XDG_RUNTIME_DIR="$test_dir/runtime" timeout 10 quickshell -p "$test_dir/shell.qml" --no-color 2>&1) || { printf '%s\n' "$output"; exit 1; }
printf '%s\n' "$output"
[[ "$output" == *ACTIVITY_TESTS_PASSED* ]]
