"""ART-003: keep the three darkroom/white-future proposals complete and reproducible."""
import hashlib
import json
import re
import unittest
from pathlib import Path

from PIL import Image

COLLAB = Path(__file__).resolve().parents[1]
PROPOSAL = COLLAB / "tasks" / "ART-003" / "proposal.md"
ART = COLLAB / "proposals" / "ART-003"
EXPECTED = {
    "A": ("初页", "a_first_page.png"),
    "B": ("余曝", "b_after_exposure.png"),
    "C": ("缝明", "c_mended_dawn.png"),
}


def sampled_pixels(image):
    sample = image.convert("RGB")
    sample.thumbnail((320, 240))
    return [sample.getpixel((x, y))
            for y in range(sample.height) for x in range(sample.width)]


class PlayerRedesignConceptTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads((ART / "manifest.json").read_text(encoding="utf-8"))
        cls.images = cls.manifest["images"]

    def test_three_distinct_proposals_have_recorded_provenance(self):
        self.assertEqual(self.manifest["tool"], "image_gen")
        self.assertEqual(self.manifest["generation_mode"], "built-in")
        self.assertEqual(self.manifest["date"], "2026-10-30")
        self.assertEqual(self.manifest["status"], "exploration")
        self.assertEqual([item["id"] for item in self.images], ["A", "B", "C"])
        self.assertEqual(len({item["sha256"] for item in self.images}), 3)
        for item in self.images:
            with self.subTest(concept=item["id"]):
                self.assertEqual((item["title"], item["file"]), EXPECTED[item["id"]])
                self.assertEqual(Path(item["file"]).name, item["file"])
                self.assertEqual(
                    hashlib.sha256((ART / item["file"]).read_bytes()).hexdigest(),
                    item["sha256"],
                )

    def test_full_resolution_landscape_pngs_decode_without_truncation(self):
        for item in self.images:
            with self.subTest(concept=item["id"]):
                path = ART / item["file"]
                with Image.open(path) as image:
                    self.assertEqual(image.format, "PNG")
                    image.verify()
                with Image.open(path) as image:
                    image.load()
                    self.assertEqual(list(image.size), item["size"])
                    self.assertGreaterEqual(image.width, 1024)
                    self.assertGreaterEqual(image.height, 768)
                    self.assertGreater(image.width / image.height, 1.25)
                    self.assertLess(image.width / image.height, 1.85)

    def test_sheet_is_grayscale_dominant_with_localized_acquired_color(self):
        # Measures the shared palette requirement, not character identity or anatomy.
        # Those remain a separate visual review recorded in the proposal.
        for item in self.images:
            with self.subTest(concept=item["id"]), Image.open(ART / item["file"]) as image:
                pixels = sampled_pixels(image)
                color = sum(max(p) - min(p) > 30 for p in pixels) / len(pixels)
                white = sum(min(p) >= 225 for p in pixels) / len(pixels)
                self.assertGreater(color, 0.0005, "The acquired-color examples are missing.")
                self.assertLess(color, 0.15, "Color overwhelms the monochrome world/white hero.")
                self.assertGreater(white, 0.04, "The luminous white subject has been lost.")

    def test_initial_hero_stays_achromatic_and_contains_white(self):
        for item in self.images:
            with self.subTest(concept=item["id"]), Image.open(ART / item["file"]) as image:
                region = item["initial_hero_region"]
                self.assertEqual(len(region), 4)
                x0, y0, x1, y1 = region
                self.assertTrue(0 <= x0 < x1 <= 1 and 0 <= y0 < y1 <= 1)
                crop = image.crop((
                    round(x0 * image.width), round(y0 * image.height),
                    round(x1 * image.width), round(y1 * image.height),
                ))
                pixels = sampled_pixels(crop)
                color = sum(max(p) - min(p) > 30 for p in pixels) / len(pixels)
                white = sum(min(p) >= 225 for p in pixels) / len(pixels)
                self.assertLess(color, 0.01, "The initial hero already has acquired colors.")
                self.assertGreater(white, 0.10)

    def test_proposal_and_final_prompts_link_every_deliverable(self):
        document = PROPOSAL.read_text(encoding="utf-8")
        prompts = (ART / "prompts.md").read_text(encoding="utf-8")
        for item in self.images:
            with self.subTest(concept=item["id"]):
                self.assertIn(f"ART-003/{item['file']}", document)
                self.assertIn(item["file"], prompts)
                self.assertIn(f"{item['id']} · {item['title']}", document)
                self.assertIn(f'{item["id"]} · {item["title"]}', prompts)
        for target in re.findall(r"\]\(([^)]+)\)", document):
            resolved = (PROPOSAL.parent / target.split("#", 1)[0]).resolve()
            self.assertTrue(resolved.is_relative_to(COLLAB.resolve()), target)
            self.assertTrue(resolved.is_file(), target)
        # Prevent accidental promotion of concept art into approved production lore.
        self.assertIn("推荐不代表用户已定稿", document)
        self.assertIn("演示色", document)
        self.assertIn("不是可直接使用的动画帧或正式游戏素材", document)


if __name__ == "__main__":
    unittest.main()

