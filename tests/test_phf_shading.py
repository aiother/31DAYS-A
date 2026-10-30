"""Verify the user's selective 1/7/8 leg-value correction and exact preservation."""
import hashlib
import json
import unittest
from pathlib import Path

from PIL import Image, ImageChops, ImageStat

ART = Path(__file__).resolve().parents[1] / "phf/walk_shading_v2"


class PhfShadingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with Image.open(ART / "source/original.png") as image:
            cls.original = image.convert("RGBA")
        with Image.open(ART / "walk_sheet_corrected.png") as image:
            cls.corrected = image.convert("RGBA")
        cls.regions = json.loads((ART / "edit_regions.json").read_text(encoding="utf-8"))

    @staticmethod
    def value(image, point):
        x, y = point
        mean = ImageStat.Stat(image.crop((x-2, y-2, x+3, y+3))).mean
        return sum(mean[:3])/3

    def test_same_canvas_and_exact_original_alpha_silhouettes(self):
        self.assertEqual(self.corrected.size, (1536, 1024))
        self.assertEqual(self.corrected.size, self.original.size)
        self.assertEqual(self.corrected.getchannel("A").tobytes(), self.original.getchannel("A").tobytes())

    def test_frames_2_3_4_5_6_are_pixel_exact(self):
        for frame in (2, 3, 4, 5, 6):
            i = frame-1
            x, y = i % 4 * 384, i // 4 * 512
            box = (x, y, x+384, y+512)
            self.assertEqual(self.original.crop(box).tobytes(), self.corrected.crop(box).tobytes())

    def test_all_heads_faces_and_upper_costumes_are_pixel_exact(self):
        for i in range(8):
            x, y = i % 4 * 384, i // 4 * 512
            box = (x, y, x+384, y+310)
            self.assertEqual(self.original.crop(box).tobytes(), self.corrected.crop(box).tobytes())

    def test_all_changes_are_inside_selected_leg_regions(self):
        diff = ImageChops.difference(self.original.convert("RGB"), self.corrected.convert("RGB"))
        red, green, blue = diff.split()
        changed = ImageChops.lighter(ImageChops.lighter(red, green), blue).point(lambda v: 255 if v else 0)
        with Image.open(ART / "edit_mask.png") as image:
            allowed = image.getchannel("A").point(lambda v: 255 if v >= 128 else 0)
        self.assertIsNone(ImageChops.subtract(changed, allowed).getbbox())
        for frame in (1, 7, 8):
            i = frame-1
            x, y = i % 4 * 384, i // 4 * 512
            count = sum(v > 0 for v in changed.crop((x, y, x+384, y+512)).get_flattened_data())
            self.assertEqual(count, self.regions["changed_pixels"][str(frame)])
            self.assertGreater(count, 8000)

    def test_orange_right_leg_is_brighter_than_blue_left_leg_in_all_three_frames(self):
        pairs = [
            ((173, 349), (245, 355)),  # frame 1 upper legs
            ((139, 389), (253, 411)),  # frame 1 lower legs
            ((115, 470), (291, 482)),  # frame 1 boots
            ((966, 906), (950, 879)),  # frame 7 visible supporting/swinging skin
            ((966, 906), (993, 853)),  # frame 7 bent knee must also be dark
            ((989, 978), (913, 936)),  # frame 7 boots
            ((1319, 845), (1380, 853)),  # frame 8 upper legs
            ((1287, 887), (1399, 899)),  # frame 8 lower legs
            ((1255, 963), (1458, 956)),  # frame 8 boots
        ]
        for orange, blue in pairs:
            with self.subTest(orange=orange, blue=blue):
                self.assertGreater(self.value(self.corrected, orange)-self.value(self.corrected, blue), 25)

    def test_wrong_original_skin_values_changed_in_the_requested_direction(self):
        for point in ((173, 349), (139, 389), (966, 906), (1319, 845)):
            self.assertGreater(self.value(self.corrected, point)-self.value(self.original, point), 15)
        for point in ((245, 355), (253, 411), (993, 853), (950, 879), (1380, 853), (1399, 899)):
            self.assertLess(self.value(self.corrected, point)-self.value(self.original, point), -25)

    def test_all_marker_pixels_and_original_dark_ink_are_exact(self):
        original = self.original.tobytes()
        corrected = self.corrected.tobytes()
        marker_count = 0
        for q in range(0, len(original), 4):
            r, g, b, a = original[q:q+4]
            marker = (r > g+20 and g > b+10) or (b > r+20 and b > g+15)
            if marker or (r+g+b)/3 < 115:
                self.assertEqual(original[q:q+4], corrected[q:q+4])
            marker_count += marker and a > 180
        self.assertGreater(marker_count, 1500)

    def test_binary_provenance_and_output_hashes(self):
        manifest = json.loads((ART / "manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest["edited_frames"], [1, 7, 8])
        self.assertEqual(manifest["identity"]["right"], "orange dot, bright outer leg")
        self.assertEqual(manifest["identity"]["left"], "blue double dash, dark inner leg")
        for entry in manifest["files"]:
            self.assertEqual(hashlib.sha256((ART / entry["file"]).read_bytes()).hexdigest(), entry["sha256"])


if __name__ == "__main__":
    unittest.main()
