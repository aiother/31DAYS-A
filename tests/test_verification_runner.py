import contextlib
import io
import json
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
        files = {'res://' + path.relative_to(verifier.ROOT / 'game').as_posix()
                 for path in (verifier.ROOT / 'game/tests').rglob('test_*.gd')}
        self.assertEqual({path for _, path, _ in verifier.TESTS}, files - set(verifier.EXCLUDED_TESTS))
        self.assertEqual(len({path for _, path, _ in verifier.TESTS}), len(verifier.TESTS))
        for _, path, _ in verifier.TESTS:
            self.assertTrue((verifier.ROOT/'game'/path.removeprefix('res://')).is_file())

    def test_survey_uses_fixed_60hz_and_separate_bounded_budget(self):
        with patch.object(verifier.subprocess,'run',return_value=SimpleNamespace(returncode=0,stdout='SURVEY_TESTS checks=1 failures=0\n',stderr='')) as run:
            suite = next(s for s in verifier.SUITES if s.path == 'res://tests/test_pursuit_survey_a.gd')
            run.return_value.stdout = suite.marker + '1 failures=0\n'
            result=verifier.execute_suite('engine','project',suite)
        self.assertTrue(result[3])
        self.assertEqual(run.call_args.kwargs['timeout'],600)
        self.assertIn('--fixed-fps',run.call_args.args[0])
        self.assertIn('60',run.call_args.args[0])

    def test_ordinary_suites_keep_realtime_60_second_budget(self):
        with patch.object(verifier.subprocess,'run',return_value=SimpleNamespace(returncode=0,stdout='',stderr='')) as run:
            suite = next(s for s in verifier.SUITES if s.path == 'res://tests/test_platform_pursuit.gd')
            verifier.execute_suite('engine','project',suite)
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
            marker = 'FIRST' if 'res://first.gd' in command else 'SECOND'
            return SimpleNamespace(returncode=0, stdout=marker + ' checks=1 failures=0\n', stderr='')
        cases = [verifier.Suite('first', 'res://first.gd', 'FIRST checks=', None, 60),
                 verifier.Suite('second', 'res://second.gd', 'SECOND checks=', None, 60)]
        with tempfile.TemporaryDirectory() as directory:
            report = Path(directory)/'report.txt'
            arguments = ['verify_game.py', '--godot', 'fake', '--jobs', '2', '--report', str(report)]
            with patch.object(verifier, 'discover_suites', return_value=cases), patch.object(verifier.subprocess, 'run', side_effect=fake_run), patch('sys.argv', arguments), contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(verifier.main(), 0)
            text = report.read_text(encoding='utf-8')
            self.assertLess(text.index('=== first:'), text.index('=== second:'))
        self.assertEqual(len(threads), 2)

    def fixture(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        project = Path(directory.name)
        (project / 'tests').mkdir()
        return project

    def suite_file(self, project, filename='test_demo.gd', **changes):
        data = dict(name=filename, path='res://tests/' + filename,
                    marker=filename.upper().replace('.', '_') + ' checks=', fixed_fps=None, timeout=60)
        data.update(changes)
        path = project / 'tests' / filename
        path.write_text('# verify-suite: ' + json.dumps(data) + '\nextends SceneTree\n', encoding='utf-8')
        return path

    def test_new_suite_needs_only_its_own_file(self):
        project = self.fixture()
        self.suite_file(project)
        first = verifier.discover_suites(project)
        self.suite_file(project, 'test_another.gd', timeout=180, fixed_fps=60)
        second = verifier.discover_suites(project)
        self.assertEqual({s.path for s in second} - {s.path for s in first}, {'res://tests/test_another.gd'})
        self.assertEqual(next(s.timeout for s in second if s.fixed_fps == 60), 180)

    def test_new_unregistered_file_fails(self):
        project = self.fixture()
        self.suite_file(project)
        (project / 'tests/test_missing.gd').write_text('extends SceneTree\n')
        with self.assertRaisesRegex(ValueError, 'Missing suite metadata'):
            verifier.discover_suites(project)

    def test_removing_existing_registration_fails(self):
        project = self.fixture()
        path = self.suite_file(project)
        path.write_text(path.read_text().split('\n', 1)[1])
        with self.assertRaisesRegex(ValueError, 'Missing suite metadata'):
            verifier.discover_suites(project)

    def test_duplicate_path_marker_and_name_fail(self):
        for field, value in [('path', 'res://tests/test_first.gd'), ('marker', 'FIRST checks='), ('name', 'first')]:
            with self.subTest(field=field):
                project = self.fixture()
                self.suite_file(project, 'test_first.gd', name='first', marker='FIRST checks=')
                self.suite_file(project, 'test_second.gd', **{field: value})
                with self.assertRaisesRegex(ValueError, 'Duplicate'):
                    verifier.discover_suites(project)

    def test_missing_and_wrong_owner_paths_fail(self):
        project = self.fixture()
        self.suite_file(project, path='res://tests/test_nonexistent.gd')
        with self.assertRaisesRegex(ValueError, 'does not exist'):
            verifier.discover_suites(project)
        (project / 'tests/test_helper.gd').write_text('extends SceneTree\n')
        self.suite_file(project, path='res://tests/test_helper.gd')
        with self.assertRaisesRegex(ValueError, 'own file'):
            verifier.discover_suites(project)

    def test_invalid_metadata_and_runtime_parameters_fail(self):
        for change in ({'timeout': 0}, {'timeout': True}, {'fixed_fps': -1}, {'fixed_fps': True},
                       {'path': 'res://../escape.gd'}, {'name': ''}, {'marker': 'not a summary'}, {'unknown': 1}):
            with self.subTest(change=change):
                project = self.fixture()
                self.suite_file(project, **change)
                with self.assertRaises(ValueError):
                    verifier.discover_suites(project)
        project = self.fixture()
        (project / 'tests/test_bad.gd').write_text('# verify-suite: {broken}\n')
        with self.assertRaises(ValueError):
            verifier.discover_suites(project)

    def test_exclusion_requires_existing_file_reason_and_no_registration(self):
        project = self.fixture()
        self.suite_file(project)
        path = project / 'tests/test_helper.gd'
        path.write_text('extends SceneTree\n')
        excluded = {'res://tests/test_helper.gd': 'Fixture loaded by another suite, not runnable alone'}
        self.assertEqual([s.path for s in verifier.discover_suites(project, excluded)], ['res://tests/test_demo.gd'])
        for invalid in ({'res://tests/test_helper.gd': ''}, {'res://tests/test_absent.gd': 'reason'}):
            with self.assertRaises(ValueError):
                verifier.discover_suites(project, invalid)
        self.suite_file(project, 'test_helper.gd')
        with self.assertRaisesRegex(ValueError, 'also registered'):
            verifier.discover_suites(project, excluded)

    def test_actual_execution_set_rejects_missing_extra_and_duplicate(self):
        suites = verifier.SUITES
        paths = [s.path for s in suites]
        verifier.validate_executed(suites, paths)
        for changed in (paths[:-1], paths + ['res://tests/test_unknown.gd'], paths + paths[:1]):
            with self.subTest(changed=changed[-1:]), self.assertRaisesRegex(ValueError, 'execution set'):
                verifier.validate_executed(suites, changed)

    def test_runtime_options_are_metadata_not_filename_rules(self):
        suite = verifier.Suite('renamed survey', 'res://tests/test_completely_new.gd', 'NEW checks=', 37, 321)
        with patch.object(verifier.subprocess, 'run', return_value=SimpleNamespace(returncode=0, stdout='NEW checks=1 failures=0\n', stderr='')) as run:
            self.assertTrue(verifier.execute_suite('engine', 'project', suite)[3])
        self.assertEqual(run.call_args.kwargs['timeout'], 321)
        self.assertEqual(run.call_args.args[0][-4:], ['--fixed-fps', '37', '--script', suite.path])

    def test_main_fails_if_a_completed_suite_is_missing(self):
        cases = [verifier.Suite('one', 'res://tests/test_one.gd', 'ONE checks=', None, 60),
                 verifier.Suite('two', 'res://tests/test_two.gd', 'TWO checks=', None, 60)]
        def fake_run(command, **kwargs):
            if '--version' in command:
                return SimpleNamespace(stdout='4.7.2.stable.test')
            marker = 'ONE' if cases[0].path in command else 'TWO'
            return SimpleNamespace(returncode=0, stdout=marker + ' checks=1 failures=0\n', stderr='')
        def omit_one(futures):
            return iter(list(futures)[:1])
        with tempfile.TemporaryDirectory() as directory:
            arguments = ['verify_game.py', '--godot', 'fake', '--report', str(Path(directory) / 'report.txt')]
            with patch.object(verifier, 'discover_suites', return_value=cases), patch.object(verifier.subprocess, 'run', side_effect=fake_run), patch.object(verifier, 'as_completed', side_effect=omit_one), patch('sys.argv', arguments), contextlib.redirect_stdout(io.StringIO()) as output, contextlib.redirect_stderr(io.StringIO()) as errors:
                self.assertEqual(verifier.main(), 1)
            self.assertIn('execution set', errors.getvalue())
            self.assertNotIn('All engine checks passed.', output.getvalue())


if __name__ == '__main__':
    unittest.main()
