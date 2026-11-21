#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "$0")/../.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
cp -a "$repo_dir/dotfiles/quickshell/notchD" "$test_dir/app"
cp "$repo_dir/tests/clipboard/shell.qml" "$test_dir/shell.qml"
mkdir "$test_dir/bin"
cp "$repo_dir/tests/clipboard/backend.py" "$test_dir/bin/notchd-clipboard"
chmod +x "$test_dir/bin/notchd-clipboard"
export NOTCHD_CLIPBOARD_TEST_DIR="$test_dir"
output=$(env PATH="$test_dir/bin:$PATH" DBUS_SESSION_BUS_ADDRESS="unix:path=$test_dir/no-bus" QT_QPA_PLATFORM=offscreen timeout 10 quickshell -p "$test_dir/shell.qml" 2>&1)
printf '%s\n' "$output"
[[ "$output" == *CLIPBOARD_KEYS_PASSED* ]]
if [[ "$output" == *'FAIL '* || "$output" == *'ReferenceError:'* || "$output" == *'TypeError:'* || "$output" == *'Binding loop detected'* ]]; then exit 1; fi
python3 - "$test_dir" <<'PY'
import json, pathlib, sys
actions = [json.loads(line) for line in (pathlib.Path(sys.argv[1]) / 'actions.jsonl').read_text().splitlines()]
assert ['copy', '3'] in actions, actions
assert ['delete', '1'] in actions, actions
print('CLIPBOARD_ACTIONS_PASSED')
PY
