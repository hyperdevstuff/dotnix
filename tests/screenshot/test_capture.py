import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[2] / 'dotfiles/bin/notchd-screenshot'


class Capture(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.log = self.root / 'log'
        self.env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ['PATH'],
                        XDG_RUNTIME_DIR=str(self.root / 'runtime'), CAPTURE_LOG=str(self.log))
        self.stub('quickshell', 'if [ "$6" = status ]; then echo \'{"locked":false}\'; fi')
        self.stub('slurp', 'printf "%s\\n" "-1920,20 320x240"')
        self.stub('grim', 'printf "%s\\n" "$*" >> "$CAPTURE_LOG"; printf PNG > "$3"')
        self.stub('swappy', 'test -s "$2"; printf "%s\\n" "$*" >> "$CAPTURE_LOG"')

    def stub(self, name, body):
        p = self.bin / name
        p.write_text('#!/usr/bin/env bash\nset -eu\n' + body + '\n')
        p.chmod(0o755)

    def run_capture(self):
        return subprocess.run([str(SCRIPT)], env=self.env, capture_output=True, text=True)

    def test_capture_opens_editor_and_removes_temporary_image(self):
        result = self.run_capture()
        self.assertEqual(result.returncode, 0, result.stderr)
        lines = self.log.read_text().splitlines()
        self.assertTrue(lines[0].startswith('-g -1920,20 320x240 '), lines)
        self.assertTrue(lines[1].startswith('-f '), lines)
        self.assertFalse(Path(lines[1][3:]).exists())

    def test_cancellation_does_not_capture_or_open_editor(self):
        self.stub('slurp', 'exit 1')
        self.assertEqual(self.run_capture().returncode, 0)
        self.assertFalse(self.log.exists())

    def test_invalid_geometry_is_rejected(self):
        self.stub('slurp', 'echo "bad input"')
        self.assertNotEqual(self.run_capture().returncode, 0)
        self.assertFalse(self.log.exists())

    def test_locked_session_is_rejected(self):
        self.stub('quickshell', 'echo \'{"locked":true}\'')
        self.assertNotEqual(self.run_capture().returncode, 0)
        self.assertFalse(self.log.exists())


if __name__ == '__main__':
    unittest.main()
