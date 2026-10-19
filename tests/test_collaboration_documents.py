"""协作交接资料的入口、链接和命令有效性检查。"""

from pathlib import Path
import re
import subprocess
import sys
import unittest


ROOT = Path(__file__).resolve().parents[1]
DOCUMENTS = (
    ROOT / 'CLAUDE.md',
    ROOT / 'docs/claude_collaboration.md',
    ROOT / 'docs/claude_first_review.md',
)


class CollaborationDocumentsTests(unittest.TestCase):
    def test_local_markdown_links_resolve_inside_repository(self):
        for document in DOCUMENTS:
            content = document.read_text(encoding='utf-8')
            self.assertNotIn('\ufffd', content)
            for target in re.findall(r'\]\(([^)]+)\)', content):
                with self.subTest(document=document.name, target=target):
                    resolved = (document.parent / target).resolve()
                    self.assertTrue(resolved.is_relative_to(ROOT))
                    self.assertTrue(resolved.is_file())

    def test_review_code_and_document_references_exist(self):
        content = DOCUMENTS[2].read_text(encoding='utf-8')
        references = re.findall(r'`((?:game|scripts|tests)/[^`]+\.(?:md|py))`', content)
        self.assertGreaterEqual(len(references), 8)
        for reference in references:
            with self.subTest(reference=reference):
                self.assertTrue((ROOT / reference).is_file())

    def test_documented_engine_arguments_are_supported(self):
        result = subprocess.run(
            [sys.executable, '-X', 'utf8', str(ROOT / 'scripts/verify_game.py'), '--help'],
            capture_output=True, text=True, encoding='utf-8', timeout=15,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        for option in ('--godot', '--jobs', '--report'):
            self.assertIn(option, result.stdout)


if __name__ == '__main__':
    unittest.main()
