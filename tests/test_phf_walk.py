"""Regression checks for the delivered eight-frame 初页 walk and its actual rig."""
import hashlib
import json
import math
import subprocess
import unittest
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "phf/walk_8_v1"


class PhfWalkTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rig = json.loads((ART / "rig.json").read_text(encoding="utf-8"))
        cls.manifest = json.loads((ART / "manifest.json").read_text(encoding="utf-8"))
        cls.frames = []
        for i in range(8):
            with Image.open(ART / "frames" / f"walk_{i+1:02}.png") as image:
                cls.frames.append(image.convert("RGBA"))

    def test_eight_distinct_full_size_transparent_frames(self):
        self.assertEqual(self.rig["cell_size"], [768, 1024])
        self.assertEqual(len(self.frames), 8)
        self.assertEqual(len({f.tobytes() for f in self.frames}), 8)
        for image in self.frames:
            self.assertEqual(image.size, (768, 1024))
            self.assertEqual(image.mode, "RGBA")
            low, high = image.getchannel("A").getextrema()
            self.assertEqual(low, 0)
            self.assertGreater(high, 245)
            left, top, right, bottom = image.getchannel("A").point(lambda v: 255 if v > 32 else 0).getbbox()
            self.assertGreater(left, 24)
            self.assertGreater(top, 24)
            self.assertLess(right, 744)
            self.assertLess(bottom, 1000)

    def test_sheet_cells_are_pixel_exact(self):
        with Image.open(ART / "walk_sheet.png") as sheet:
            self.assertEqual(sheet.size, (3072, 2048))
            for i, expected in enumerate(self.frames):
                x, y = i % 4 * 768, i // 4 * 1024
                actual = sheet.crop((x, y, x+768, y+1024)).convert("RGBA")
                self.assertEqual(actual.tobytes(), expected.tobytes())

    def test_identity_completes_full_cycle_before_repeating(self):
        for side, offset in (("left", 0), ("right", 4)):
            actual = [f["legs"][side]["phase_index"] for f in self.rig["frames"]]
            self.assertEqual(actual, [(i+offset) % 8 for i in range(8)])
            self.assertEqual(set(actual), set(range(8)))
            for frame in self.rig["frames"]:
                leg = frame["legs"][side]
                self.assertEqual(leg["depth"], "near" if side == "left" else "far")
                self.assertEqual(leg["marker"], "orange_L" if side == "left" else "blue_R")

    def test_real_render_order_keeps_near_left_above_far_right(self):
        for frame in self.rig["frames"]:
            order = {t["name"]: t["order"] for t in frame["transforms"]}
            far = [order["right_"+part] for part in ("thigh", "shin", "boot")]
            near = [order["left_"+part] for part in ("thigh", "shin", "boot")]
            self.assertLess(max(far), min(near))
            for side in ("left", "right"):
                self.assertGreater(order[side+"_boot"], order[side+"_shin"])

    def test_no_missing_or_duplicate_bound_components(self):
        expected = {"cape_rear", "cape_near", "cape_far", "tunic", "shorts", "head_neck_collar_clasp"}
        expected.update(side+"_"+part for side in ("left", "right")
                        for part in ("thigh", "shin", "boot", "sleeve", "hand"))
        for frame in self.rig["frames"]:
            names = [t["name"] for t in frame["transforms"]]
            self.assertEqual(set(names), expected)
            self.assertEqual(len(names), len(expected))
            for part in frame["transforms"]:
                asset = part["asset"]
                source = ART / "source" / ("head.png" if asset == "head" else f"parts/{asset:02}.png")
                with Image.open(source) as image:
                    self.assertIsNotNone(image.getchannel("A").getbbox())

    def test_same_asset_pivot_and_uniform_scale_for_every_part(self):
        baseline = {t["name"]: t for t in self.rig["frames"][0]["transforms"]}
        for frame in self.rig["frames"]:
            for part in frame["transforms"]:
                original = baseline[part["name"]]
                self.assertEqual(part["asset"], original["asset"])
                self.assertEqual(part["source_anchor"], original["source_anchor"])
                self.assertEqual(part["scale"], original["scale"])
                self.assertEqual(part["shade"], original["shade"])
                self.assertGreater(part["scale"], 0)

    def test_thigh_and_shin_lengths_are_constant_and_knees_face_forward(self):
        for frame in self.rig["frames"]:
            for leg in frame["legs"].values():
                hip, knee, ankle = (leg[k] for k in ("hip", "knee", "ankle"))
                self.assertAlmostEqual(math.dist(hip, knee), 84, places=8)
                self.assertAlmostEqual(math.dist(knee, ankle), 86, places=8)
                dx, dy = ankle[0]-hip[0], ankle[1]-hip[1]
                cross = dx*(knee[1]-hip[1]) - dy*(knee[0]-hip[0])
                self.assertLess(cross, 0)

    def test_stance_feet_travel_back_then_recover_without_identity_swap(self):
        for side in ("left", "right"):
            phases = sorted((f["legs"][side] for f in self.rig["frames"]), key=lambda leg: leg["phase_index"])
            xs = [leg["ankle"][0] for leg in phases]
            self.assertTrue(all(a > b for a, b in zip(xs[:4], xs[1:5])))
            self.assertTrue(all(a < b for a, b in zip(xs[4:]+xs[:1], xs[5:]+xs[:1])))
            self.assertGreater(xs[0]-xs[4], 65)

    def test_walking_has_ground_support_and_clearance(self):
        for frame in self.rig["frames"]:
            self.assertTrue(any(leg["grounded"] for leg in frame["legs"].values()))
            for leg in frame["legs"].values():
                if leg["grounded"]:
                    self.assertAlmostEqual(leg["sole_y"], 450, places=6)
                else:
                    self.assertLess(leg["sole_y"], 445)
        # The raster silhouettes independently confirm one identical ground line.
        bottoms = [f.getchannel("A").point(lambda v: 255 if v > 32 else 0).getbbox()[3] for f in self.frames]
        self.assertEqual(bottoms, [901]*8)

    def test_eight_to_one_is_checked_for_both_legs(self):
        for side in ("left", "right"):
            legs = [f["legs"][side] for f in self.rig["frames"]]
            for a, b in zip(legs, legs[1:]+legs[:1]):
                self.assertLess(math.dist(a["ankle"], b["ankle"]), 44)
                self.assertLess(math.dist(a["knee"], b["knee"]), 46)

    def test_head_pixels_change_only_by_planned_vertical_bob(self):
        crops = []
        for index, frame in enumerate(self.frames):
            bob = [2, 5, 0, -6][index % 4] * 2
            crops.append(frame.crop((250, 80+bob, 540, 315+bob)).tobytes())
        self.assertEqual(len(set(crops)), 1)

    def test_cloth_and_opposite_arm_swing_are_animated(self):
        tracks = {}
        for frame in self.rig["frames"]:
            for part in frame["transforms"]:
                tracks.setdefault(part["name"], []).append(part["rotation"])
        for part in ("cape_rear", "cape_near", "cape_far", "left_sleeve", "right_sleeve", "left_hand", "right_hand"):
            self.assertGreater(max(tracks[part])-min(tracks[part]), 3)
        for values in zip(tracks["left_sleeve"], tracks["right_sleeve"]):
            self.assertAlmostEqual(sum(values), sum((tracks["left_sleeve"][0], tracks["right_sleeve"][0])), places=8)

    def test_apng_round_trip_matches_all_png_pixels_and_timing(self):
        with Image.open(ART / "walk_8.apng") as animation:
            self.assertEqual(animation.n_frames, 8)
            self.assertEqual(animation.info["loop"], 0)
            for index, expected in enumerate(self.frames):
                animation.seek(index)
                self.assertEqual(animation.info["duration"], 125)
                self.assertEqual(animation.convert("RGBA").tobytes(), expected.tobytes())

    def test_gif_previews_have_eight_frames_and_shared_duration(self):
        for name, durations in (("walk_preview.gif", [120, 130]*4),
                                ("walk_slow.gif", [250]*8), ("walk_leg_audit.gif", [250]*8)):
            with Image.open(ART / name) as image:
                self.assertEqual(image.n_frames, 8)
                self.assertEqual(image.size, (384, 512))
                self.assertEqual(image.info["loop"], 0)
                for index, duration in enumerate(durations):
                    image.seek(index)
                    self.assertEqual(image.info["duration"], duration)

    def test_audit_markers_are_separate_from_clean_art(self):
        for i, frame in enumerate(self.rig["frames"]):
            with Image.open(ART / "audit_frames" / f"walk_{i+1:02}.png") as image:
                for side in ("left", "right"):
                    x, y = frame["legs"][side]["marker_position"]
                    pixel = image.getpixel((round(x*2), round(y*2)))
                    self.assertGreater(pixel[3], 200)
                    if side == "left":
                        self.assertGreater(pixel[0]-pixel[2], 100)
                    else:
                        self.assertGreater(pixel[2]-pixel[0], 100)
            with Image.open(ART / "audit_frames" / f"walk_{i+1:02}.png") as image:
                self.assertNotEqual(image.tobytes(), self.frames[i].tobytes())

    def test_references_and_delivered_file_hashes(self):
        self.assertEqual(len(self.manifest["references"]), 5)
        for item in self.manifest["references"]:
            self.assertEqual(hashlib.sha256((ROOT / item["file"]).read_bytes()).hexdigest(), item["sha256"])
        for item in self.manifest["files"]:
            self.assertEqual(hashlib.sha256((ART / item["file"]).read_bytes()).hexdigest(), item["sha256"])

    def test_manifest_text_hashes_are_stable_on_windows_checkout(self):
        paths = ["phf/walk_8_v1/"+item["file"] for item in self.manifest["files"]
                 if Path(item["file"]).suffix in (".md", ".html", ".json")]
        result = subprocess.run(["git", "check-attr", "-z", "eol", "--", *paths],
                                cwd=ROOT, capture_output=True, check=True)
        fields = result.stdout.decode("utf-8").split("\0")[:-1]
        actual = {fields[i]: fields[i+2] for i in range(0, len(fields), 3)}
        self.assertEqual(set(actual), set(paths))
        self.assertTrue(all(value == "lf" for value in actual.values()))
        for path in paths + ["phf/walk_8_v1/manifest.json", "phf/walk_8_v1/qa_report.json"]:
            self.assertNotIn(b"\r\n", (ROOT / path).read_bytes())


if __name__ == "__main__":
    unittest.main()
