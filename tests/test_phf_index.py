"""phf/README.md indexes every player-art package and names the current walk sheet."""
import hashlib
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PHF = ROOT / "phf"


class PhfIndexTests(unittest.TestCase):
    def setUp(self):
        self.readme = (PHF / "README.md").read_text(encoding="utf-8")

    def test_every_listed_entry_exists_and_every_entry_is_listed(self):
        listed = {name.rstrip("/") for name in re.findall(r"`([^`]+)`", self.readme)
                  if not name.startswith("..") and "/" not in name.rstrip("/")}
        on_disk = {p.name for p in PHF.iterdir() if p.name != "README.md"}
        self.assertEqual(on_disk, listed)

    def test_current_walk_sheet_is_the_no_halo_delivery(self):
        def digest(path):
            return hashlib.sha256(path.read_bytes()).hexdigest()
        current = PHF / "步行逐帧图2.png"
        self.assertEqual(digest(current), digest(PHF / "walk_no_halo_v3" / "walk_sheet_no_halo.png"))
        self.assertEqual(digest(current), digest(PHF / "run_12_v1" / "source" / "approved_walk.png"))
        self.assertEqual(digest(PHF / "步行逐帧图1.png"), digest(PHF / "walk_no_halo_v3" / "approved_source.png"))
        self.assertIn("**当前确认的 8 帧步行**", self.readme)

    def test_rejected_run_variants_and_scripts_are_removed(self):
        # User rejected all run variants; retain v1 assets for Claude's
        # planning update, but remove all five generation/packaging scripts.
        rejected_paths = (
            "phf/run_12_v2",
            "phf/run_12_v3",
            "scripts/build_phf_run12.py",
            "scripts/build_phf_run12_v2.py",
            "scripts/export_phf_run12_v2.cjs",
            "scripts/build_phf_run12_v3.cjs",
            "scripts/package_phf_run12_v3.py",
            "tests/test_phf_run12_v2.py",
            "tests/test_phf_run12_v3.cjs",
            "tests/test_phf_run12_v3.py",
        )
        for relative in rejected_paths:
            with self.subTest(path=relative):
                self.assertFalse((ROOT / relative).exists(), relative)


if __name__ == "__main__":
    unittest.main()
