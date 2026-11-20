#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "$0")/../.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
cp -a "$repo_dir/dotfiles/quickshell/notchD" "$test_dir/app"
cp "$repo_dir/tests/tray-calendar/shell.qml" "$test_dir/shell.qml"
export NOTCHD_TRAY_TEST_DIR="$test_dir" NOTCHD_TRAY_TEST_REPO="$repo_dir"
export NOTCHD_TEST_PYTHON="${PYTHON:-python3}"
"$NOTCHD_TEST_PYTHON" -c 'import dbus_next'
cat > "$test_dir/dbus.conf" <<'CONFIG'
<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN" "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig><type>session</type><listen>unix:tmpdir=/tmp</listen><auth>EXTERNAL</auth><policy context="default"><allow send_destination="*"/><allow eavesdrop="true"/><allow own="*"/><allow user="*"/></policy></busconfig>
CONFIG
dbus-run-session --config-file="$test_dir/dbus.conf" -- bash -c '
set -euo pipefail
"$NOTCHD_TEST_PYTHON" "$NOTCHD_TRAY_TEST_REPO/tests/tray-calendar/notifier.py" "$NOTCHD_TRAY_TEST_DIR/actions.jsonl" > "$NOTCHD_TRAY_TEST_DIR/notifier.log" 2>&1 &
notifier_pid=$!
trap "kill $notifier_pid 2>/dev/null || true" EXIT
QT_QPA_PLATFORM=offscreen timeout 12 quickshell -p "$NOTCHD_TRAY_TEST_DIR/shell.qml" > "$NOTCHD_TRAY_TEST_DIR/shell.log" 2>&1
cat "$NOTCHD_TRAY_TEST_DIR/shell.log" "$NOTCHD_TRAY_TEST_DIR/notifier.log"
rg -q TRAY_CALENDAR_PASSED "$NOTCHD_TRAY_TEST_DIR/shell.log"
! rg "ReferenceError:|TypeError:|Binding loop detected" "$NOTCHD_TRAY_TEST_DIR/shell.log"
"$NOTCHD_TEST_PYTHON" -c '\''import json,os,pathlib; events=[json.loads(x) for x in (pathlib.Path(os.environ["NOTCHD_TRAY_TEST_DIR"])/"actions.jsonl").read_text().splitlines()]; assert ["activate"] in events and ["secondary"] in events and ["scroll",120,"vertical"] in events and ["menu",1,"clicked"] in events,events; print("TRAY_ACTIONS_PASSED")'\''
'
