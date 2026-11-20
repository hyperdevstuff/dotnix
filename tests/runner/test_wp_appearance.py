#!/usr/bin/env python3
"""Exercise wp with an isolated home and stubbed desktop commands."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

WP = Path(__file__).resolve().parents[2] / 'dotfiles/bin/wp'


class AppearanceTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.bin = self.home / 'bin'
        self.bin.mkdir()
        self.wall = self.home / 'Pictures/walls/bw/paper.png'
        self.wall.parent.mkdir(parents=True)
        self.wall.touch()
        self.log = self.home / 'calls'
        self.env = dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.home / '.config'),
                        XDG_RUNTIME_DIR=str(self.home / 'runtime'), PATH=str(self.bin) + ':' + os.environ['PATH'],
                        TEST_WALL=str(self.wall), TEST_LOG=str(self.log))
        self.stub('awww', '''printf 'awww %s\\n' "$*" >> "$TEST_LOG"
if [ "${1:-}" = query ]; then printf '{"output":[{"displaying":{"image":"%s"}}]}\\n' "$TEST_WALL"; fi''')
        self.stub('matugen', '''printf 'matugen' >> "$TEST_LOG"
printf ' <%s>' "$@" >> "$TEST_LOG"
printf '\\n' >> "$TEST_LOG"''')
        self.stub('gsettings', 'exit 0')
        self.stub('dconf', 'exit 0')

    def stub(self, name, body):
        p = self.bin / name
        p.write_text('#!/usr/bin/env bash\n' + body + '\n')
        p.chmod(0o755)

    def wp(self, *args, ok=True):
        p = subprocess.run([str(WP), *args], env=self.env, text=True, capture_output=True)
        self.assertEqual(p.returncode == 0, ok, p.stderr)
        return p.stdout.strip()

    def calls(self):
        return self.log.read_text() if self.log.exists() else ''

    def test_selection_and_persistence(self):
        self.assertEqual(self.wp('scheme'), 'wallpaper')
        self.assertEqual(self.wp('variant'), 'auto')
        self.wp('scheme', '#a1B2c3')
        self.assertEqual(self.wp('scheme'), '#a1B2c3')
        self.assertIn('matugen <color> <hex> <#a1B2c3> <--type> <scheme-monochrome>', self.calls())
        self.wp('variant', 'scheme-vibrant')
        self.assertEqual(self.wp('variant'), 'scheme-vibrant')
        self.wp('theme', 'light')
        self.assertIn('<#a1B2c3> <--type> <scheme-vibrant> <--mode> <light>', self.calls())
        self.assertNotIn('awww img', self.calls())
        self.wp('scheme', 'wallpaper')
        self.assertIn('matugen <image> <' + str(self.wall) + '> <--type> <scheme-vibrant>', self.calls())
        self.wp(str(self.wall))
        self.assertIn('awww img', self.calls())
        self.assertIn('matugen <image> <' + str(self.wall) + '> <--type> <scheme-vibrant>', self.calls())

    def test_auto_variant_restores_wallpaper_default(self):
        self.wp('variant', 'scheme-vibrant')
        self.wp('variant', 'auto')
        self.assertEqual(self.wp('variant'), 'auto')
        self.assertIn('<scheme-monochrome>', self.calls().splitlines()[-1])
        self.assertNotIn('awww img', self.calls())

    def test_invalid_inputs_do_not_write_or_execute(self):
        for value in ['#12345', '#123456;touch /tmp/runner-injection', 'red']:
            self.wp('scheme', value, ok=False)
        for value in ['scheme-bogus', 'scheme-vibrant;id']:
            self.wp('variant', value, ok=False)
        self.assertFalse((self.home / '.config/wallpapers/scheme').exists())
        self.assertFalse((self.home / '.config/wallpapers/variant').exists())
        self.assertEqual(self.calls(), '')


if __name__ == '__main__':
    unittest.main()
