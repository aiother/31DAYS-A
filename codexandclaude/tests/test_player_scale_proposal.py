"""ART-003 player-scale proposal: the evidence bundle behind the camera decision."""
import hashlib
import json
import unittest
from pathlib import Path

from PIL import Image

COLLAB = Path(__file__).resolve().parents[1]
BUNDLE = COLLAB / "proposals" / "ART-003" / "player_scale_v1"


class PlayerScaleProposalTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads((BUNDLE / "manifest.json").read_text(encoding="utf-8"))

    def test_decision_matches_reference_measurement(self):
        decision = self.manifest["decision"]
        self.assertEqual(decision["camera_zoom"], 1.875)
        self.assertEqual(decision["ground_screen_y"], 950)
        # Screen height is the unchanged world display height times the camera zoom.
        self.assertAlmostEqual(decision["player_world_display_height"] * decision["camera_zoom"],
                               decision["player_screen_height_1080p"])

    def test_every_image_is_recorded_and_unchanged(self):
        on_disk = sorted(p.relative_to(BUNDLE).as_posix() for p in BUNDLE.rglob("*")
                         if p.suffix in (".png", ".webp"))
        recorded = sorted(item["file"] for item in self.manifest["images"])
        self.assertEqual(on_disk, recorded)
        for item in self.manifest["images"]:
            with self.subTest(file=item["file"]):
                self.assertEqual(hashlib.sha256((BUNDLE / item["file"]).read_bytes()).hexdigest(),
                                 item["sha256"])

    def test_captures_are_full_hd_and_record_grounded_feet(self):
        captures = sorted((BUNDLE / "captures").glob("*.json")) + sorted((BUNDLE / "captures_ref").glob("*.json"))
        self.assertEqual(len(captures), 12)
        for path in captures:
            with self.subTest(capture=path.name):
                info = json.loads(path.read_text(encoding="utf-8"))
                self.assertEqual(info["image"], [1920, 1080])
                self.assertTrue(info["on_floor"])
                with Image.open(path.with_suffix(".png")) as image:
                    self.assertEqual(image.size, (1920, 1080))
                if path.parent.name == "captures_ref":
                    self.assertEqual(info["zoom"], 1.875)
                    self.assertAlmostEqual(info["feet_canvas"][1], 950, delta=1)

    def test_verify_captures_use_the_shipped_camera(self):
        captures = sorted((BUNDLE / "verify").glob("*.json"))
        self.assertEqual(len(captures), 2)
        for path in captures:
            with self.subTest(capture=path.name):
                info = json.loads(path.read_text(encoding="utf-8"))
                self.assertEqual(info["camera_script"], "res://world/gameplay_camera.gd")
                self.assertEqual(info["zoom"], self.manifest["decision"]["camera_zoom"])
                self.assertTrue(info["on_floor"])
                self.assertAlmostEqual(info["feet_canvas"][1], 0.88 * 1080, delta=1)

    def test_tools_write_inside_the_project(self):
        for name in ("scale_capture.gd", "ref_capture.gd", "verify_capture.gd"):
            text = (BUNDLE / "tools" / name).read_text(encoding="utf-8")
            with self.subTest(tool=name):
                self.assertIn('"res://../codexandclaude/proposals/ART-003/player_scale_v1/', text)
                self.assertNotIn("Temp", text)
        for name in ("compose.py", "compose_reference.py"):
            self.assertNotIn("Temp", (BUNDLE / "tools" / name).read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
