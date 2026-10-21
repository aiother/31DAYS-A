"""BL-113: checkout must not turn Godot's LF import metadata into CRLF."""
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class ImportLineEndingTests(unittest.TestCase):
    def test_import_checkout_preserves_godot_bytes_with_autocrlf(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / '.gitattributes').write_bytes((ROOT / '.gitattributes').read_bytes())

            def git(*args):
                return subprocess.run(
                    [shutil.which('git'), '-c', 'core.autocrlf=true', *args],
                    cwd=root, check=True, capture_output=True,
                ).stdout

            git('init', '-q')
            paths = ['player.svg.import', 'gray_tile.svg.import', 'font.ttf.import']
            godot_bytes = b'[remap]\nimporter="test"\n\n[deps]\n'
            for name in paths:
                (root / name).write_bytes(godot_bytes)
            git('add', '--', '.gitattributes', *paths)
            for name in paths:
                (root / name).unlink()
            git('checkout-index', '--all', '--force')
            for name in paths:
                with self.subTest(path=name):
                    self.assertEqual(godot_bytes, (root / name).read_bytes())
            attributes = git('check-attr', 'eol', '--', *paths).decode()
            self.assertEqual(3, attributes.count(': eol: lf'))


if __name__ == '__main__':
    unittest.main()
