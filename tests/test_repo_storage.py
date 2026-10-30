"""Large binary references go through Git LFS so the GitHub backup stays lean."""
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VIDEO = "codexandclaude/references/动作参考.mp4"


class RepoStorageTests(unittest.TestCase):
    def test_reference_video_lives_outside_specs_and_uses_lfs(self):
        self.assertTrue((ROOT / VIDEO).is_file())
        self.assertFalse((ROOT / "Words" / "动作参考.mp4").exists())
        result = subprocess.run(["git", "-c", f"safe.directory={ROOT.as_posix()}", "check-attr", "filter", "--", VIDEO],
                                cwd=ROOT, capture_output=True, text=True, encoding="utf-8", check=True)
        self.assertTrue(result.stdout.strip().endswith("filter: lfs"), result.stdout)


if __name__ == "__main__":
    unittest.main()
