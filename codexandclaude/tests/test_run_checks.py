"""Failure-path and orchestration tests; no installed tools are needed."""
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

SCRIPT = Path(__file__).resolve().parents[1] / 'tools/run_checks.py'
spec = importlib.util.spec_from_file_location('run_checks', SCRIPT)
checks = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checks)


class RunChecksTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='31days checks with spaces ')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()

    def args(self, **values):
        return SimpleNamespace(root=self.root, **{tool: values.get(tool) for tool in checks.TOOLS})

    def test_resolution_precedence_and_spaces(self):
        paths = []
        for name in ('cli tool.exe', 'config tool.exe', 'env tool.exe', 'auto tool.exe'):
            path = self.root / name
            path.touch()
            paths.append(str(path))
        with patch.object(checks, 'known_paths', return_value=[paths[3]]):
            self.assertEqual(checks.resolve_tool('node', self.args(node=paths[0]), {'node': paths[1]}, {'DAYS31_NODE': paths[2]}), paths[0])
            self.assertEqual(checks.resolve_tool('node', self.args(), {'node': paths[1]}, {'DAYS31_NODE': paths[2]}), paths[1])
            self.assertEqual(checks.resolve_tool('node', self.args(), {}, {'DAYS31_NODE': paths[2]}), paths[2])
            self.assertEqual(checks.resolve_tool('node', self.args(), {}, {}), paths[3])

    def test_missing_explicit_tool_does_not_fall_back(self):
        with patch.object(checks, 'known_paths') as auto:
            with self.assertRaisesRegex(checks.CheckFailure, 'Missing/unusable node'):
                checks.resolve_tool('node', self.args(node=str(self.root / 'missing')), {}, {})
            auto.assert_not_called()

    def test_python_discovery_rejects_missing_dependency(self):
        first, second = self.root / 'python1.exe', self.root / 'python2.exe'
        first.touch()
        second.touch()
        with patch.object(checks, 'known_paths', return_value=[first, second]), patch.object(checks.subprocess, 'run', side_effect=[SimpleNamespace(returncode=1), SimpleNamespace(returncode=0)]):
            self.assertEqual(checks.resolve_tool('python', self.args(), {}, {}), str(second))

    def runner(self):
        return checks.Runner(self.root, self.root, 10, {})

    def test_subprocess_argv_preserves_paths_and_nonzero_fails(self):
        process = Mock(returncode=9)
        process.communicate.return_value = ('broken', None)
        runner = self.runner()
        argv = ['C:/a path/python.exe', 'a test.py']
        with patch.object(checks.subprocess, 'Popen', return_value=process) as popen:
            with self.assertRaisesRegex(checks.CheckFailure, 'exit=9'):
                runner.run(argv)
            self.assertEqual(popen.call_args.args[0], argv)
            self.assertNotIn('shell', popen.call_args.kwargs)
        self.assertEqual(runner.commands[0]['exit_code'], 9)
        self.assertEqual((self.root / '001.txt').read_text(), 'broken')

    def test_timeout_fails_and_terminates_worker(self):
        process = Mock(returncode=-1, pid=1234)
        process.communicate.side_effect = [subprocess.TimeoutExpired('tool', 10), ('partial', None)]
        runner = self.runner()
        with patch.object(checks.subprocess, 'Popen', return_value=process), patch.object(checks.subprocess, 'run') as cleanup:
            with self.assertRaisesRegex(checks.CheckFailure, 'timeout=True'):
                runner.run(['tool'])
            process.kill.assert_called_once()
            if os.name == 'nt':
                self.assertEqual(cleanup.call_args.args[0], ['taskkill', '/PID', '1234', '/T', '/F'])
        self.assertTrue(runner.commands[0]['timed_out'])

    def test_launch_error_is_recorded(self):
        runner = self.runner()
        with patch.object(checks.subprocess, 'Popen', side_effect=FileNotFoundError('missing')):
            with self.assertRaises(checks.CheckFailure):
                runner.run(['missing'])
        self.assertEqual(runner.commands[0]['exit_code'], -1)

    def test_python_summary_must_exist_have_tests_and_pass(self):
        for output in ('', 'OK\n', 'Ran 0 tests in 0s\nOK\n', 'Ran 2 tests in 0s\nFAILED\n', 'Ran 2 tests in 0s\nOK (skipped=1)\n'):
            with self.subTest(output=output), self.assertRaises(checks.CheckFailure):
                checks.python_result(output)
        self.assertEqual(checks.python_result('Ran 3 tests in 0.1s\n\nOK\n'), 3)

    def test_g2_summary_requires_complete_nonduplicate_entries(self):
        verifier = SimpleNamespace(TESTS=[('suite', 'res://suite.gd', 'SUITE checks=')])
        good = 'PASS editor import\nPASS main scene180 frames\nPASS suite\nAll engine checks passed. Report: report.txt\n'
        self.assertEqual(checks.g2_result(good, verifier), 3)
        for output in (good.replace('PASS suite\n', ''), good + 'PASS suite\n', good.replace('All engine checks passed.', '')):
            with self.assertRaises(checks.CheckFailure):
                checks.g2_result(output, verifier)

    def execute_main(self, extra=(), failure=None, version='4.7.2.stable.abc', engine_output=None, resolve=None, snapshots=None):
        commands = []
        def fake_run(runner, argv, timeout=None, stdout_only=False):
            argv = list(map(str, argv))
            commands.append((argv, dict(runner.env)))
            if failure and failure in ' '.join(argv):
                raise checks.CheckFailure('simulated subprocess failure')
            if 'rev-parse' in argv:
                return 'a' * 40 + '\n'
            if 'status' in argv:
                return ' M tests/example.py\n'
            if '--version' in argv:
                return version if argv[0] == 'godot' else 'tool version'
            if 'import sys,openpyxl;' in ' '.join(argv):
                return '3.12\nopenpyxl=3.1\n'
            if '--report' in argv:
                Path(argv[argv.index('--report') + 1]).write_text('engine log')
                return engine_output if engine_output is not None else 'PASS editor import\nPASS main scene180 frames\nPASS suite\nAll engine checks passed. Report: engine.txt\n'
            if '-c' in argv:
                return 'FOCUSED_VERIFIER_PASS\n'
            return 'Ran 4 tests in 0.1s\nOK\n'
        verifier = SimpleNamespace(TESTS=[('suite', 'res://tests/suite.gd', 'SUITE checks=')])
        content = {'schema': 1, 'sha': 'a' * 40, 'scope': checks.evidence.SCOPE, 'dirty': True, 'full_sha256': 'f' * 64}
        with patch.object(checks.evidence, 'snapshot', return_value=content, side_effect=snapshots), patch.object(checks, 'resolve_tool', side_effect=resolve or (lambda tool, *unused: tool)), patch.object(checks.Runner, 'run', fake_run), patch.object(checks, 'load_verifier', return_value=verifier), contextlib.redirect_stdout(io.StringIO()):
            code = checks.main([*extra, '--root', str(self.root)])
        summary = json.loads(next((self.root / 'codexandclaude/runs').glob('*/summary.json')).read_text(encoding='utf-8'))
        rendered = next((self.root / 'codexandclaude/runs').glob('*/evidence.md')).read_text(encoding='utf-8')
        self.assertIn('总结果：**通过**' if code == 0 else '总结果：**不通过**', rendered)
        self.assertTrue(summary['finalized'])
        return code, summary, commands

    def test_environment_records_sha_dirty_paths_versions(self):
        code, summary, _ = self.execute_main(['env'])
        self.assertEqual(code, 0)
        self.assertEqual(summary['sha'], 'a' * 40)
        self.assertTrue(summary['dirty'])
        self.assertEqual(set(summary['tools']), set(checks.TOOLS))
        self.assertEqual(summary['checks'], [])
        self.assertIn('content', summary)
        self.assertIn('invocation', summary)

    def test_wrong_godot_version_fails(self):
        code, summary, _ = self.execute_main(['env'], version='4.6.stable.abc')
        self.assertEqual(code, 1)
        self.assertIn('Expected Godot', summary['reason'])

    def test_preflight_missing_tool_is_reported_with_sha(self):
        code, summary, _ = self.execute_main(['env'], failure='--version')
        self.assertEqual(code, 1)
        self.assertFalse(summary['passed'])
        self.assertEqual(summary['sha'], 'a' * 40)

    def test_full_calls_existing_verifier_then_both_python_directories(self):
        code, summary, commands = self.execute_main(['full'])
        self.assertEqual(code, 0)
        self.assertEqual([row['gate'] for row in summary['checks']], ['G2', 'G3', 'G3'])
        self.assertEqual(summary['checks'][0]['executed'], 3)
        self.assertEqual([row['directory'] for row in summary['checks'][1:]], ['tests', 'codexandclaude/tests'])
        invoked = [(args, env) for args, env in commands if '-m' in args]
        self.assertEqual(len(invoked), 2)
        self.assertTrue(all(env['DAYS31_NODE'] == 'node' for _, env in invoked))

    def test_full_rejects_zero_exit_missing_engine_summary(self):
        code, summary, commands = self.execute_main(['full'], engine_output='')
        self.assertEqual(code, 1)
        self.assertIn('Incomplete verifier', summary['reason'])
        self.assertFalse(any('-m' in args for args, _ in commands))

    def test_focused_python_all_never_calls_engine(self):
        code, summary, commands = self.execute_main(['focused', '--python-all'])
        self.assertEqual(code, 0)
        self.assertEqual(len(summary['checks']), 2)
        self.assertFalse(any('--report' in args or '--script' in args for args, _ in commands))

    def test_focused_module_runs_only_requested_module(self):
        code, summary, _ = self.execute_main(['focused', '--python-module', 'tests.test_game_project'])
        self.assertEqual(code, 0)
        self.assertEqual(summary['checks'][0]['module'], 'tests.test_game_project')

    def test_focused_godot_imports_then_uses_existing_execute(self):
        code, summary, commands = self.execute_main(['focused', '--godot-script', 'res://tests/suite.gd'])
        self.assertEqual(code, 0)
        adapters = [args for args, _ in commands if '-c' in args and 'v.execute' in args[2]]
        self.assertEqual([args[-1] for args in adapters], ['', 'res://tests/suite.gd'])
        self.assertEqual(len(summary['checks']), 2)
        self.assertIn('v.execute_suite', adapters[0][2])
        self.assertIn('v.SUITES', adapters[0][2])

    def test_unregistered_godot_script_rejected(self):
        code, summary, _ = self.execute_main(['focused', '--godot-script', 'res://other.gd'])
        self.assertEqual(code, 1)
        self.assertIn('Unregistered', summary['reason'])

    def test_empty_focused_is_error(self):
        code, summary, _ = self.execute_main(['focused'])
        self.assertEqual(code, 1)
        self.assertIn('requires', summary['reason'])

    @staticmethod
    def resolve_without(*missing):
        def resolve(tool, *unused):
            if tool in missing:
                raise checks.CheckFailure(f'Missing/unusable {tool}')
            return tool
        return resolve

    def test_python_only_focused_runs_without_godot(self):
        code, summary, commands = self.execute_main(['focused', '--python-all'], resolve=self.resolve_without('godot'))
        self.assertEqual(code, 0, summary['reason'])
        self.assertEqual(set(summary['tools']), {'git', 'python', 'node'})
        self.assertEqual(summary['tools_not_required'], ['godot'])
        self.assertFalse(any(args[0] == 'godot' for args, _ in commands))

    def test_godot_only_focused_does_not_require_node(self):
        code, summary, _ = self.execute_main(['focused', '--godot-script', 'res://tests/suite.gd'],
                                             resolve=self.resolve_without('node'))
        self.assertEqual(code, 0, summary['reason'])
        self.assertEqual(set(summary['tools']), {'git', 'python', 'godot'})
        self.assertEqual(summary['tools_not_required'], ['node'])

    def test_env_and_full_still_require_every_tool(self):
        for mode in ('env', 'full'):
            with self.subTest(mode=mode):
                for runs in (self.root / 'codexandclaude/runs').glob('*'):
                    for file in runs.iterdir():
                        file.unlink()
                    runs.rmdir()
                code, summary, _ = self.execute_main([mode], resolve=self.resolve_without('godot'))
                self.assertEqual(code, 1)
                self.assertIn('Missing/unusable godot', summary['reason'])

    def test_skipped_tests_fail_with_actionable_reason(self):
        for output, label in (('Ran 2 tests in 0s\n\nOK (skipped=1)\n', 'skipped=1'),
                              ('Ran 2 tests in 0s\n\nOK (expected failures=1)\n', 'expected failures=1')):
            with self.subTest(output=output):
                with self.assertRaisesRegex(checks.CheckFailure, 'not allowed') as caught:
                    checks.python_result(output)
                self.assertIn(label, str(caught.exception))

    def test_unexpected_exception_still_writes_summary(self):
        def broken(tool, *unused):
            raise KeyError('surprise')
        code, summary, _ = self.execute_main(['env'], resolve=broken)
        self.assertEqual(code, 1)
        self.assertFalse(summary['passed'])
        self.assertIn('KeyError', summary['reason'])
        self.assertIn('Traceback', summary['traceback'])

    def test_content_drift_preserves_gate_results_but_is_not_a_reusable_source(self):
        code, summary, _ = self.execute_main(['focused', '--python-all'], snapshots=[
            {'full_sha256': 'a'}, {'full_sha256': 'b'}])
        self.assertEqual(code, 0)
        self.assertFalse(summary['content_stable'])
        self.assertFalse(checks.evidence.compare(self.root, 'git', source_summary=summary)['reusable'])

    def test_unreadable_final_snapshot_is_failure_not_a_pass(self):
        code, summary, _ = self.execute_main(['env'], snapshots=[{'full_sha256': 'a'}, OSError('unreadable')])
        self.assertEqual(code, 1)
        self.assertIn('final content snapshot failed', summary['reason'])

    def test_keyboard_interrupt_is_not_swallowed(self):
        def interrupted(tool, *unused):
            raise KeyboardInterrupt
        with self.assertRaises(KeyboardInterrupt):
            self.execute_main(['env'], resolve=interrupted)

    def test_invalid_config_is_error(self):
        config = self.root / 'bad.json'
        config.write_text('{broken')
        code, summary, _ = self.execute_main(['env', '--config', str(config)])
        self.assertEqual(code, 1)
        self.assertFalse(summary['passed'])


if __name__ == '__main__':
    unittest.main()
