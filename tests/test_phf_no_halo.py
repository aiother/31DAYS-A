"""Check the approved sheet's halo removal without changing its pose/leg cues."""
import hashlib
import json
import math
import unittest
from pathlib import Path

from PIL import Image, ImageStat

ART = Path(__file__).resolve().parents[1] / "phf/walk_no_halo_v3"


def markers(image):
    result = []
    for i in range(8):
        points = {"orange": [], "blue": []}
        ox, oy = i % 4 * 384, i // 4 * 512
        for y in range(oy+330, oy+490):
            for x in range(ox+65, ox+340):
                r, g, b = image.getpixel((x, y))
                if r > g+40 and g > b+15 and r > 150:
                    points["orange"].append((x, y))
                if b > r+35 and b > g+15:
                    points["blue"].append((x, y))
        result.append(points)
    return result


class PhfNoHaloTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with Image.open(ART / "approved_source.png") as image:
            cls.source = image.convert("RGB")
        with Image.open(ART / "walk_sheet_no_halo.png") as image:
            cls.output = image.convert("RGB")
        cls.source_marks, cls.output_marks = markers(cls.source), markers(cls.output)

    def test_canvas_and_eight_equal_cells_are_preserved(self):
        self.assertEqual(self.output.size, self.source.size)
        self.assertEqual(self.output.size, (1536, 1024))
        for i in range(8):
            x, y = i % 4 * 384, i // 4 * 512
            self.assertEqual(self.output.crop((x, y, x+384, y+512)).size, (384, 512))

    def test_background_has_no_radial_glow_or_vignette(self):
        means = []
        original_means = []
        for i in range(8):
            ox, oy = i % 4 * 384, i // 4 * 512
            for x, y in ((12, 12), (72, 120), (320, 380), (55, 400), (305, 75), (372, 490)):
                box = (ox+x-3, oy+y-3, ox+x+4, oy+y+4)
                stat = ImageStat.Stat(self.output.crop(box))
                self.assertLess(max(stat.stddev), 2)
                self.assertTrue(all(120 <= value <= 130 for value in stat.mean))
                means.append(sum(stat.mean)/3)
                original_means.append(sum(ImageStat.Stat(self.source.crop(box)).mean)/3)
        self.assertLess(max(means)-min(means), 3)
        self.assertGreater(max(original_means)-min(original_means), 40)

    def test_all_eight_orange_and_blue_markers_remain_at_original_locations(self):
        for original, output in zip(self.source_marks, self.output_marks):
            for color in ("orange", "blue"):
                a, b = original[color], output[color]
                self.assertGreater(len(a), 80)
                self.assertGreater(len(b), 80)
                center = lambda points: tuple(sum(p[k] for p in points)/len(points) for k in (0, 1))
                self.assertLess(math.dist(center(a), center(b)), 2)
                self.assertGreater(len(b)/len(a), .75)
                self.assertLess(len(b)/len(a), 1.25)

    def test_approved_skin_and_boot_values_are_not_reinterpreted(self):
        # Includes frame7's approved bright bent leg: this task changes only BG.
        points = [(173,349),(139,389),(245,355),(253,411),(291,482),
                  (976,906),(989,978),(993,853),(950,879),(913,936),
                  (1319,845),(1287,887),(1255,963),(1380,853),(1399,899),(1458,956)]
        for x, y in points:
            box = (x-2, y-2, x+3, y+3)
            original = sum(ImageStat.Stat(self.source.crop(box)).mean)/3
            output = sum(ImageStat.Stat(self.output.crop(box)).mean)/3
            self.assertLess(abs(original-output), 18, (x, y, original, output))

    def test_white_costume_and_hair_still_have_original_highlights(self):
        for i in range(8):
            ox, oy = i % 4 * 384, i // 4 * 512
            for x, y in ((210, 74), (212, 207)):
                before = sum(self.source.getpixel((ox+x, oy+y)))/3
                after = sum(self.output.getpixel((ox+x, oy+y)))/3
                # Cape facets can be darker than white hair in the source.
                self.assertGreater(after, 235 if y == 74 else 200)
                self.assertLess(abs(before-after), 15)

    def test_png_provenance_hashes(self):
        manifest = json.loads((ART / "manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest["tool"], "image_gen")
        self.assertEqual(manifest["mode"], "built-in")
        for item in manifest["files"]:
            self.assertEqual(hashlib.sha256((ART / item["file"]).read_bytes()).hexdigest(), item["sha256"])


if __name__ == "__main__":
    unittest.main()
