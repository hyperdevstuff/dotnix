import runpy
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

HELPER = Path(__file__).resolve().parents[2] / 'dotfiles/bin/notchd-metrics'


class Metrics(unittest.TestCase):
    def setUp(self):
        self.module = runpy.run_path(str(HELPER))
        self.gpu = self.module['gpu_snapshot']
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        info = self.root / 'proc/driver/nvidia/gpus/0000:01:00.0/information'
        info.parent.mkdir(parents=True)
        info.write_text('Model: Test GPU\n')
        self.runtime = self.root / 'sys/bus/pci/devices/0000:01:00.0/power/runtime_status'
        self.runtime.parent.mkdir(parents=True)
        def fixture_path(value):
            value = str(value)
            return self.root / value.lstrip('/') if value.startswith(('/proc/', '/sys/')) else Path(value)
        self.patch = patch.dict(self.gpu.__globals__, Path=fixture_path)
        self.patch.start()
        self.addCleanup(self.patch.stop)

    def test_sleeping_gpu_never_invokes_driver(self):
        self.runtime.write_text('suspended')
        with patch('subprocess.run', side_effect=AssertionError('would wake GPU')):
            value = self.gpu()
        self.assertEqual(value['state'], 'Sleeping')
        self.assertIsNone(value['usage'])

    def test_gpu_query_timeout_returns_unavailable(self):
        self.runtime.write_text('active')
        with patch('shutil.which', return_value='/bin/nvidia-smi'), patch(
            'subprocess.run', side_effect=subprocess.TimeoutExpired('nvidia-smi', 0.8)
        ) as query:
            value = self.gpu()
        self.assertEqual(value['state'], 'Unavailable')
        self.assertIsNone(value['usage'])
        self.assertEqual(query.call_args.kwargs['timeout'], 0.8)

    def test_gpu_query_parses_percentage_and_temperature(self):
        self.runtime.write_text('active')
        with patch('shutil.which', return_value='/bin/nvidia-smi'), patch(
            'subprocess.run', return_value=subprocess.CompletedProcess([], 0, '18, 47\n')
        ):
            value = self.gpu()
        self.assertEqual((value['usage'], value['temperature']), (18, 47))


if __name__ == '__main__':
    unittest.main()
