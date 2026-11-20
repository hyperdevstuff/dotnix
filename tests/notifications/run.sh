#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "$0")/../.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
cp -a "$repo_dir/dotfiles/quickshell/notchD" "$test_dir/notchD"
sed 's|../../dotfiles/quickshell/notchD/services|services|' "$repo_dir/tests/notifications/shell.qml" > "$test_dir/notchD/test-store.qml"
cat > "$test_dir/dbus.conf" <<'CONFIG'
<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN" "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig><type>session</type><listen>unix:tmpdir=/tmp</listen><auth>EXTERNAL</auth><policy context="default"><allow send_destination="*"/><allow eavesdrop="true"/><allow own="*"/><allow user="*"/></policy></busconfig>
CONFIG
output=$(dbus-run-session --config-file="$test_dir/dbus.conf" -- env QT_QPA_PLATFORM=offscreen timeout 10 quickshell -p "$test_dir/notchD/test-store.qml" 2>&1)
printf '%s\n' "$output"
[[ "$output" == *NOTIFICATION_TESTS_PASSED* ]]
