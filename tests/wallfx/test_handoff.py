"""Exercise wp's real handoff block with isolated CLI and daemon substitutes."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class Handoff(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.wall = self.root / "new # ' $ wallpaper.png"
        self.wall.touch()
        (self.root / "old.png").touch()
        self.log = self.root / "calls"
        self.env = dict(os.environ, HOME=str(self.root), XDG_RUNTIME_DIR=str(self.root),
                        PATH=str(self.bin) + ":" + os.environ["PATH"], MODE="ok", LOG=str(self.log))
        source = (ROOT / "dotfiles/bin/wp").read_text()
        block = source.split("# Serialize every wallpaper writer", 1)[1].split("\n", 1)[1].split('\ngenerate_palette "$wall"', 1)[0]
        self.script = self.root / "handoff"
        lock = 'appearance_lock() {' + source.split('appearance_lock() {', 1)[1].split('\n}\n', 1)[0] + '\n}\n'
        self.script.write_text('set -euo pipefail\nCONFIG="$HOME/.config"\nwall="$1"\ncurrent_wall() { printf "%s/old.png\\n" "$HOME"; }\n' + lock + block)
        self.mock("wallfx-map", 'printf "%s/map.png\\n%s/smooth.png\\n" "$HOME" "$HOME"\n')
        self.mock("qs", '''python3 - "$@" <<'MOCK'
import os,sys,json
args=sys.argv[1:]; mode=os.environ['MODE']
with open(os.environ['LOG'],'a') as f: f.write(json.dumps(['qs',*args])+'\\n')
if mode=='offline': sys.exit(1)
if 'play' in args: print('busy' if mode=='busy' else 'ok')
elif 'state' in args: print('held' if mode=='timeout' else 'idle')
elif 'result' in args: print('error' if mode=='error' else 'ok')
MOCK
''')
        self.mock("awww", '''python3 - "$@" <<'MOCK'
import os,json,sys,time
with open(os.environ['LOG'],'a') as f: f.write(json.dumps(['start',*sys.argv[1:]])+'\\n')
time.sleep(.15)
with open(os.environ['LOG'],'a') as f: f.write(json.dumps(['end'])+'\\n')
MOCK
''')

    def mock(self, name, body):
        p = self.bin / name
        p.write_text('#!/bin/sh\n' + body)
        p.chmod(0o755)

    def run_wp(self, mode="ok"):
        return subprocess.run(['bash', str(self.script), str(self.wall)], env=dict(self.env, MODE=mode),
                              capture_output=True, timeout=25)

    def calls(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def test_success_and_exact_filename(self):
        self.assertEqual(self.run_wp().returncode, 0)
        calls = self.calls()
        self.assertFalse(any(c[0] == 'start' for c in calls))
        self.assertIn(str(self.wall), next(c for c in calls if 'play' in c))

    def test_missing_shell_and_daemon_failure_fallback(self):
        for mode in ['offline', 'error']:
            with self.subTest(mode=mode):
                self.log.unlink(missing_ok=True)
                self.assertEqual(self.run_wp(mode).returncode, 0)
                starts = [c for c in self.calls() if c[0] == 'start']
                self.assertEqual(len(starts), 1)
                self.assertEqual(starts[0][-1], str(self.wall))

    def test_busy_does_not_start_competing_writer(self):
        self.assertNotEqual(self.run_wp('busy').returncode, 0)
        self.assertFalse(any(c[0] == 'start' for c in self.calls()))

    def test_concurrent_writers_are_serialized(self):
        env = dict(self.env, MODE='offline')
        a = subprocess.Popen(['bash', str(self.script), str(self.wall)], env=env, stdout=subprocess.DEVNULL)
        b = subprocess.Popen(['bash', str(self.script), str(self.wall)], env=env, stdout=subprocess.DEVNULL)
        self.assertEqual(a.wait(timeout=5), 0)
        self.assertEqual(b.wait(timeout=5), 0)
        self.assertEqual([c[0] for c in self.calls() if c[0] in ('start', 'end')],
                         ['start', 'end', 'start', 'end'])

    def test_timeout_is_bounded_and_never_overlaps(self):
        self.assertNotEqual(self.run_wp('timeout').returncode, 0)
        self.assertFalse(any(c[0] == 'start' for c in self.calls()))


if __name__ == '__main__':
    unittest.main()
