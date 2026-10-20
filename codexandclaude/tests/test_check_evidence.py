"""Real Git fixtures for evidence identity and conservative reuse boundaries."""
import importlib.util
import contextlib
import io
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'tools/check_evidence.py'
spec = importlib.util.spec_from_file_location('check_evidence', SCRIPT)
evidence = importlib.util.module_from_spec(spec)
spec.loader.exec_module(evidence)


class EvidenceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='31days evidence ')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.git = shutil.which('git')
        self.assertIsNotNone(self.git)
        self.git_run('init', '-q')
        self.git_run('config', 'user.name', 'Evidence test')
        self.git_run('config', 'user.email', 'evidence@example.invalid')
        self.git_run('config', 'core.autocrlf', 'false')
        self.write('.gitignore', 'codexandclaude/runs/\n')
        self.write('code.py', 'print(1)\n')
        self.source = self.commit('initial')

    def git_run(self, *args):
        return subprocess.run([self.git, *args], cwd=self.root, check=True,
                              capture_output=True).stdout.decode('utf-8').strip()

    def write(self, path, text):
        file = self.root / path
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_text(text, encoding='utf-8')

    def commit(self, title):
        self.git_run('add', '.')
        self.git_run('commit', '-qm', title)
        return self.git_run('rev-parse', 'HEAD')

    def summary(self):
        snapshot = evidence.snapshot(self.root, self.git)
        return {'mode': 'full', 'sha': self.source, 'dirty': False, 'passed': True,
                'finalized': True, 'content': snapshot, 'content_end': snapshot,
                'content_stable': True, 'planned_checks': ['G2', 'G3:tests', 'G3:codexandclaude/tests'],
                'checks': [{'gate': 'G2', 'expected': 3, 'executed': 3, 'passed': True},
                           {'gate': 'G3', 'directory': 'tests', 'executed': 2, 'complete': True, 'passed': True},
                           {'gate': 'G3', 'directory': 'codexandclaude/tests', 'executed': 4, 'complete': True, 'passed': True}],
                'commands': [], 'tools': {}, 'reason': None, 'finished_utc': '2026-10-20T00:00:00Z'}

    def test_dirty_diff_and_unicode_untracked_hashes_identify_bytes(self):
        clean = evidence.snapshot(self.root, self.git)
        self.write('code.py', 'print(2)\n')
        self.write('中文 空格.txt', 'new\n')
        dirty = evidence.snapshot(self.root, self.git)
        self.assertTrue(dirty['dirty'])
        self.assertNotEqual(clean['tracked_diff_sha256'], dirty['tracked_diff_sha256'])
        self.assertEqual([r['path'] for r in dirty['untracked']], ['中文 空格.txt'])
        first = dirty['untracked'][0]['sha256']
        self.write('中文 空格.txt', 'changed\n')
        self.assertNotEqual(first, evidence.snapshot(self.root, self.git)['untracked'][0]['sha256'])
        self.assertNotEqual(clean['scoped_sha256'], dirty['scoped_sha256'])

    def test_staged_deletion_and_rename_are_in_fingerprint(self):
        clean = evidence.snapshot(self.root, self.git)
        self.git_run('mv', 'code.py', 'renamed.py')
        renamed = evidence.snapshot(self.root, self.git)
        self.assertNotEqual(clean['scoped_sha256'], renamed['scoped_sha256'])
        self.assertNotEqual(clean['staged_diff_sha256'], renamed['staged_diff_sha256'])
        (self.root / 'renamed.py').unlink()
        self.assertNotEqual(renamed['scoped_sha256'], evidence.snapshot(self.root, self.git)['scoped_sha256'])

    def test_record_only_commit_is_equal_and_reports_changed_path(self):
        self.write('codexandclaude/tasks/ENV-005/delivery.md', 'record\n')
        target = self.commit('record')
        result = evidence.compare(self.root, self.git, source_ref=self.source, target_ref=target)
        self.assertTrue(result['reusable'])
        self.assertEqual(result['changed_paths'], ['codexandclaude/tasks/ENV-005/delivery.md'])
        self.assertEqual(result['non_record_changes'], [])
        self.assertNotEqual(result['source_tree'], result['target_tree'])
        self.assertIn('内容条件', result['reason'])

    def test_any_code_task_spec_test_or_tool_difference_blocks_reuse(self):
        for path in ('code.py', 'codexandclaude/tasks/ENV-005/task.md', 'Words/T0.md',
                     'codexandclaude/tests/test_x.py', 'codexandclaude/tasks/ENV-005/tool.py',
                     'codexandclaude/tasks/ENV-005/nested/delivery.md'):
            with self.subTest(path=path):
                self.write(path, 'changed\n')
                target = self.commit('code')
                result = evidence.compare(self.root, self.git, source_ref=self.source, target_ref=target)
                self.assertFalse(result['reusable'])
                self.assertIn(path, result['non_record_changes'])

    def test_successful_clean_summary_accepts_only_identical_scoped_content(self):
        summary = self.summary()
        self.assertTrue(evidence.compare(self.root, self.git, source_summary=summary)['reusable'])
        self.write('codexandclaude/tasks/ENV-005/delivery.md', 'record')
        self.commit('record')
        self.assertTrue(evidence.compare(self.root, self.git, source_summary=summary)['reusable'])
        self.write('code.py', 'changed')
        self.commit('code')
        self.assertFalse(evidence.compare(self.root, self.git, source_summary=summary)['reusable'])

    def test_mutations_missing_final_incomplete_gate_dirty_source_and_code_are_rejected(self):
        summary = self.summary()
        for mutate in (lambda s: s.pop('finalized'),
                       lambda s: s['checks'].pop(),
                       lambda s: s['checks'][0].update(executed=2),
                       lambda s: s.update(dirty=True),
                       lambda s: s.update(content_stable=False),
                       lambda s: s.update(passed=False),
                       lambda s: s['content'].update(scoped_sha256='0' * 64)):
            changed = json.loads(json.dumps(summary))
            mutate(changed)
            self.assertFalse(evidence.compare(self.root, self.git, source_summary=changed)['reusable'])
        self.write('code.py', 'mutation')
        target = self.commit('mutation')
        self.assertFalse(evidence.compare(self.root, self.git, source_summary=summary, target_ref=target)['reusable'])

    def test_dirty_target_and_missing_summary_cannot_claim_reuse(self):
        summary = self.summary()
        self.write('code.py', 'uncommitted')
        self.assertFalse(evidence.compare(self.root, self.git, source_summary=summary)['reusable'])
        self.assertFalse(evidence.compare(self.root, self.git, source_summary={})['reusable'])

    def test_cli_missing_final_summary_reports_not_reusable(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            code = evidence.main(['--root', str(self.root), '--git', self.git,
                                  '--source-summary', str(self.root / 'missing-summary.json')])
        self.assertEqual(code, 1)
        self.assertFalse(json.loads(output.getvalue())['reusable'])

    def test_malformed_summary_is_rejected_without_a_success_verdict(self):
        for summary in ([], {'checks': [None]}, {'commands': None}, {'content': None}):
            with self.subTest(summary=summary):
                self.assertFalse(evidence.compare(self.root, self.git, source_summary=summary)['reusable'])

    def test_untracked_record_hash_is_kept_even_when_scoped_fingerprint_is_unchanged(self):
        clean = evidence.snapshot(self.root, self.git)
        self.write('codexandclaude/tasks/ENV-005/delivery.md', 'draft')
        dirty = evidence.snapshot(self.root, self.git)
        self.assertEqual(clean['scoped_sha256'], dirty['scoped_sha256'])
        self.assertNotEqual(clean['full_sha256'], dirty['full_sha256'])
        self.assertEqual(dirty['untracked'][0]['path'], 'codexandclaude/tasks/ENV-005/delivery.md')
        self.assertTrue(dirty['untracked'][0]['sha256'])

    def test_failure_render_includes_reason_log_hash_and_no_failure_attribution_guess(self):
        summary = self.summary()
        summary.update(passed=False, reason='simulated failure')
        summary['commands'] = [{'argv': ['python', 'a path.py'], 'exit_code': 1,
                                'log': '001.txt', 'log_sha256': 'a' * 64, 'seconds': 2}]
        text = evidence.render(summary)
        self.assertIn('simulated failure', text)
        self.assertIn('001.txt', text)
        self.assertIn('a' * 64, text)
        self.assertIn('不自动区分旧失败与新失败', text)

    def test_environment_or_forged_scope_is_not_reusable_gate_evidence(self):
        summary = self.summary()
        summary.update(mode='env', planned_checks=[], checks=[])
        self.assertFalse(evidence.compare(self.root, self.git, source_summary=summary)['reusable'])
        summary = self.summary()
        summary['content']['scope'] = ['exclude everything']
        self.assertFalse(evidence.compare(self.root, self.git, source_summary=summary)['reusable'])

    def test_renderer_never_claims_missing_final_or_gate_passed(self):
        summary = self.summary()
        summary.update(started_utc='start', finished_utc='end')
        good = evidence.render(summary)
        self.assertIn('通过', good)
        summary['checks'][0]['executed'] = 2
        bad = evidence.render(summary)
        self.assertIn('不通过', bad)
        self.assertNotIn('总结果：**通过**', bad)
        summary.pop('finalized')
        self.assertIn('不通过', evidence.render(summary))
        summary['dirty'] = True
        self.assertIn('非干净运行', evidence.render(summary))


if __name__ == '__main__':
    unittest.main()
