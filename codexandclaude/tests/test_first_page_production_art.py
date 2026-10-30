"""ART-003 A: validate the turnaround and numbered production-reference bundle."""
import hashlib
import json
import re
import unittest
from pathlib import Path

from PIL import Image

COLLAB = Path(__file__).resolve().parents[1]
ART = COLLAB / "proposals" / "ART-003" / "first_page_v1"


class FirstPageProductionArtTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads((ART / "manifest.json").read_text(encoding="utf-8"))
        cls.plan = json.loads((ART / "parts_plan.json").read_text(encoding="utf-8"))

    def test_two_original_deliverables_have_recorded_identity(self):
        manifest = self.manifest
        self.assertEqual(manifest["tool"], "image_gen")
        self.assertEqual(manifest["generation_mode"], "built-in")
        self.assertEqual(manifest["reference_sha256"],
                         "ac67b32000ae735089c0f0010740b533917425ef25f7db7aef90836dac0a2841")
        self.assertEqual(
            {item["role"]: item["file"] for item in manifest["images"]},
            {"turnaround": "player_a_turnaround_v1.png",
             "parts": "player_a_parts_breakdown_v1.png"},
        )
        self.assertEqual(len(manifest["images"]), 2)
        self.assertEqual(len({item["sha256"] for item in manifest["images"]}), 2)
        for item in manifest["images"]:
            with self.subTest(role=item["role"]):
                self.assertEqual(Path(item["file"]).name, item["file"])
                self.assertEqual(hashlib.sha256((ART / item["file"]).read_bytes()).hexdigest(),
                                 item["sha256"])

    def test_full_resolution_pngs_are_decodable_landscape_images(self):
        for item in self.manifest["images"]:
            with self.subTest(role=item["role"]):
                path = ART / item["file"]
                with Image.open(path) as image:
                    self.assertEqual(image.format, "PNG")
                    image.verify()
                with Image.open(path) as image:
                    image.load()
                    self.assertEqual(list(image.size), item["size"])
                    self.assertGreaterEqual(image.width, 1536)
                    self.assertGreaterEqual(image.height, 1024)
                    self.assertTrue(1.25 < image.width / image.height < 1.85)

    def test_initial_state_is_achromatic_with_visible_white_shapes(self):
        for item in self.manifest["images"]:
            with self.subTest(role=item["role"]), Image.open(ART / item["file"]) as image:
                sample = image.convert("RGB")
                sample.thumbnail((320, 240))
                pixels = [sample.getpixel((x, y)) for y in range(sample.height)
                          for x in range(sample.width)]
                colored = sum(max(p) - min(p) > 30 for p in pixels) / len(pixels)
                white = sum(min(p) >= 225 for p in pixels) / len(pixels)
                self.assertLess(colored, 0.005)
                self.assertGreater(white, 0.05)

    def test_turnaround_head_heights_and_sole_baselines_align(self):
        # The medium gray technical backdrop lets white silhouettes be measured.
        # Direction, anatomy and costume continuity are separately reviewed by eye.
        item = next(i for i in self.manifest["images"] if i["role"] == "turnaround")
        regions = item["view_regions"]
        self.assertEqual([r["name"] for r in regions], ["front", "right", "back"])
        with Image.open(ART / item["file"]) as image:
            bounds = []
            for region in regions:
                x0, y0, x1, y1 = region["box"]
                self.assertTrue(0 <= x0 < x1 <= 1 and 0 <= y0 < y1 <= 1)
                left, top = round(x0 * image.width), round(y0 * image.height)
                right, bottom = round(x1 * image.width), round(y1 * image.height)
                mask = image.crop((left, top, right, bottom)).convert("L")
                mask = mask.point(lambda p: 255 if p >= 230 else 0)
                bound = mask.getbbox()
                self.assertIsNotNone(bound, region["name"])
                bounds.append((top + bound[1], top + bound[3]))
            tops, soles = zip(*bounds)
            self.assertLessEqual(max(tops) - min(tops), image.height * 0.025)
            self.assertLessEqual(max(soles) - min(soles), image.height * 0.012)
            heights = [sole - top for top, sole in bounds]
            self.assertLessEqual(max(heights) - min(heights), image.height * 0.03)

    def test_parts_cover_bilateral_joints_and_form_an_acyclic_rig_plan(self):
        plan = self.plan
        self.assertEqual(plan["facing"], "right")
        self.assertEqual(plan["display_height_px"], 112)
        self.assertEqual(plan["future_asset_height_px"], 224)
        self.assertEqual(plan["overlap_ratio"], 0.15)
        self.assertEqual(plan["deliverable_type"], "numbered_parts_breakdown_sheet")
        self.assertEqual(set(plan["separate_effects"]), {"outer_glow", "companion_color_masks"})
        parts, bones = plan["parts"], plan["bones"]
        self.assertEqual([p["id"] for p in parts], [f"{i:02}" for i in range(1, 25)])
        names = {p["name"] for p in parts}
        self.assertEqual(len(names), 24)
        for side in ("near", "far"):
            for chain in (("arm_upper", "arm_lower", "hand"),
                          ("leg_upper", "leg_lower", "foot")):
                upper, lower, tip = (name + "_" + side for name in chain)
                self.assertTrue({upper, lower, tip} <= names)
                self.assertEqual(bones[lower], upper)
                self.assertEqual(bones[tip], lower)
        self.assertTrue({"head", "hair_back", "hair_front", "forelock", "collar", "clasp",
                         "cape_back", "cape_front_near", "cape_front_far", "chest", "hip", "neck"}
                        <= names)
        for part in parts:
            self.assertIn(part["bone"], bones)
            self.assertEqual(part["planned_filename"], "player_part_" + part["name"] + ".png")
        for bone in bones:
            seen = set()
            current = bone
            while current is not None:
                self.assertNotIn(current, seen, "Cyclic bone relationship")
                seen.add(current)
                self.assertIn(current, bones)
                current = bones[current]
        self.assertEqual(bones["root"], None)

    def test_documentation_links_every_image_and_preserves_final_prompts(self):
        document = (ART / "README.md").read_text(encoding="utf-8")
        prompts = (ART / "prompts.md").read_text(encoding="utf-8")
        for item in self.manifest["images"]:
            self.assertIn(item["file"], document)
            self.assertIn(item["file"], prompts)
        for document_path in (ART / "README.md", ART / "prompts.md"):
            text = document_path.read_text(encoding="utf-8")
            for target in re.findall(r"\]\(([^)]+)\)", text):
                resolved = (document_path.parent / target.split("#", 1)[0]).resolve()
                self.assertTrue(resolved.is_relative_to(ART.resolve()))
                self.assertTrue(resolved.is_file(), target)
        self.assertIn("制作参考", document)
        self.assertIn("15%", document)
        self.assertIn("24 个编号", document)


if __name__ == "__main__":
    unittest.main()

