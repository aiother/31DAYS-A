import contextlib
import io
from pathlib import Path
import subprocess
import tempfile
import threading
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from scripts import verify_game as verifier


class VerificationRunnerTests(unittest.TestCase):
    def execute(self, output, code=0, expected='DEMO_TESTS checks='):
        with patch.object(verifier.subprocess, 'run', return_value=SimpleNamespace(returncode=code, stdout=output, stderr='')):
            return verifier.execute('engine', 'project', 'demo', [], expected)

    def test_success_requires_actual_summary(self):
        self.assertTrue(self.execute('DEMO_TESTS checks=2 failures=0\n')[3])
        self.assertFalse(self.execute('unrelated failures=0\n')[3])
        self.assertFalse(self.execute('DEMO_TESTS checks=2 failures=1\n')[3])

    def test_nonzero_exit_cannot_pass(self):
        self.assertFalse(self.execute('DEMO_TESTS checks=2 failures=0\n', code=1)[3])

    def test_errors_and_leaks_cannot_pass_with_good_summary(self):
        for marker in verifier.ERROR_MARKERS:
            with self.subTest(marker=marker):
                self.assertFalse(self.execute(marker+'\nDEMO_TESTS checks=2 failures=0\n')[3])

    def test_timeout_retains_output_and_fails(self):
        error = subprocess.TimeoutExpired('engine', 60, output=b'partial output', stderr=b'partial error')
        with patch.object(verifier.subprocess, 'run', side_effect=error):
            _, code, output, passed = verifier.execute('engine', 'project', 'demo', [])
        self.assertEqual(code, 124)
        self.assertIn('partial output', output)
        self.assertIn('partial error', output)
        self.assertFalse(passed)

    def test_manifest_keeps_all_suites_and_real_files(self):
        self.assertEqual(len(verifier.TESTS), 71)
        self.assertEqual(len({path for _, path, _ in verifier.TESTS}), 71)
        for _, path, _ in verifier.TESTS:
            self.assertTrue((verifier.ROOT/'game'/path.removeprefix('res://')).is_file())

    def test_survey_uses_fixed_60hz_and_separate_bounded_budget(self):
        with patch.object(verifier.subprocess,'run',return_value=SimpleNamespace(returncode=0,stdout='SURVEY_TESTS checks=1 failures=0\n',stderr='')) as run:
            result=verifier.execute('engine','project','survey',['--script','res://tests/test_pursuit_survey_a.gd'],'SURVEY_TESTS checks=')
        self.assertTrue(result[3])
        self.assertEqual(run.call_args.kwargs['timeout'],600)
        self.assertIn('--fixed-fps',run.call_args.args[0])
        self.assertIn('60',run.call_args.args[0])

    def test_ordinary_suites_keep_realtime_60_second_budget(self):
        with patch.object(verifier.subprocess,'run',return_value=SimpleNamespace(returncode=0,stdout='',stderr='')) as run:
            verifier.execute('engine','project','normal',['--script','res://tests/test_platform_pursuit.gd'])
        self.assertEqual(run.call_args.kwargs['timeout'],60)
        self.assertNotIn('--fixed-fps',run.call_args.args[0])

    def test_parallel_execution_follows_import_and_keeps_ordered_report(self):
        barrier = threading.Barrier(2)
        threads = set()
        setup = []
        def fake_run(command, **_kwargs):
            if '--version' in command:
                return SimpleNamespace(stdout='4.7.2.stable.test')
            if '--script' not in command:
                setup.append('import' if '--import' in command else 'main')
                return SimpleNamespace(returncode=0, stdout='', stderr='')
            self.assertEqual(setup, ['import', 'main'])
            threads.add(threading.get_ident())
            barrier.wait(timeout=3)
            return SimpleNamespace(returncode=0, stdout='DEMO_TESTS checks=1 failures=0\n', stderr='')
        cases = [('first', 'res://first.gd', 'DEMO_TESTS checks='), ('second', 'res://second.gd', 'DEMO_TESTS checks=')]
        with tempfile.TemporaryDirectory() as directory:
            report = Path(directory)/'report.txt'
            arguments = ['verify_game.py', '--godot', 'fake', '--jobs', '2', '--report', str(report)]
            with patch.object(verifier, 'TESTS', cases), patch.object(verifier.subprocess, 'run', side_effect=fake_run), patch('sys.argv', arguments), contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(verifier.main(), 0)
            text = report.read_text(encoding='utf-8')
            self.assertLess(text.index('=== first:'), text.index('=== second:'))
        self.assertEqual(len(threads), 2)


if __name__ == '__main__':
    unittest.main()
