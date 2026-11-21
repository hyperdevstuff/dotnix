#!/usr/bin/env python3
"""Private fixture: never reads or changes the session clipboard."""
import json
import os
from pathlib import Path
import sys

directory = Path(os.environ['NOTCHD_CLIPBOARD_TEST_DIR'])
deleted_file = directory / 'deleted.json'
deleted = json.loads(deleted_file.read_text()) if deleted_file.exists() else []
action = sys.argv[1]
ident = sys.argv[2] if len(sys.argv) > 2 else ''
if action == 'list':
    print(json.dumps([{'id': str(i), 'label': f'Fixture clip {i:02d}'} for i in range(32) if str(i) not in deleted]))
elif action == 'preview':
    print(json.dumps({'text': f'Fixture preview {ident}'}))
elif action in ('copy', 'delete'):
    with (directory / 'actions.jsonl').open('a') as stream:
        stream.write(json.dumps([action, ident]) + '\n')
    if action == 'delete':
        deleted_file.write_text(json.dumps(deleted + [ident]))
else:
    sys.exit(1)
