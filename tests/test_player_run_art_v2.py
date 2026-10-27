"""Validate corrected sheet separation and visible leg identity cues."""
import unittest
from pathlib import Path

from PIL import Image

ART = Path(__file__).resolve().parents[1] / 'codexandclaude/tasks/ART-001/references'


class PlayerRunV2Tests(unittest.TestCase):
    def test_six_visible_sprites_fit_cells_and_bob_twice(self):
        with Image.open(ART / 'player_run_sheet_v2.png') as image:
            image.verify()
        with Image.open(ART / 'player_run_sheet_v2.png') as image:
            self.assertEqual(image.mode, 'RGBA')
            self.assertEqual(image.size, (2172, 724))
            alpha = image.getchannel('A')
            self.assertEqual(alpha.getextrema(), (0, 255))
            visible = alpha.point(lambda value: 255 if value > 32 else 0)
            occupied = [visible.crop((x, 0, x + 1, 724)).getbbox() is not None for x in range(2172)]
            self.assertEqual(sum(on and (x == 0 or not occupied[x - 1]) for x, on in enumerate(occupied)), 6)
            bounds = []
            for index in range(6):
                bound = visible.crop((index * 362, 0, (index + 1) * 362, 724)).getbbox()
                self.assertIsNotNone(bound)
                left, top, right, bottom = bound
                self.assertGreaterEqual(left, 8)
                self.assertLessEqual(right, 354)
                self.assertGreater(top, 0)
                self.assertLess(bottom, 724)
                bounds.append(bound)
            for start in (0, 3):
                self.assertGreater(bounds[start + 1][1], bounds[start][1] + 5)
                self.assertGreater(bounds[start + 1][1], bounds[start + 2][1] + 20)

    def test_forward_boot_colour_alternates_between_half_cycles(self):
        with Image.open(ART / 'player_run_sheet_v2.png') as image:
            scores = {}
            for index in (0, 2, 3, 5):
                cell = image.crop((index * 362, 0, (index + 1) * 362, 724))
                left, top, right, bottom = cell.getchannel('A').point(lambda value: 255 if value > 32 else 0).getbbox()
                # Lower forward tip: inspect boot colour, excluding transparent edge pixels.
                boot = cell.crop((right - (right - left) // 3, bottom - (bottom - top) // 6, right, bottom))
                pixels = [boot.getpixel((x, y)) for y in range(boot.height) for x in range(boot.width)]
                solid = [pixel for pixel in pixels if pixel[3] > 200]
                self.assertGreater(len(solid), 100)
                scores[index] = sum(pixel[0] - pixel[1] for pixel in solid) / len(solid)
            self.assertLess(scores[0], 0)  # Near blue boot contacts first.
            self.assertGreater(scores[3], 10)  # Far violet boot contacts next.
            self.assertGreater(scores[2], 10)  # Far boot swings forward.
            self.assertLess(scores[5], 0)  # Near boot swings forward next.

    def test_constraints_and_visual_review_scope_are_documented(self):
        doc = (ART / 'player_run_sheet_v2.md').read_text(encoding='utf-8')
        for item in ('image_gen', 'player_01_3.png', 'HIDE BOTH ARMS AND HANDS',
                     'under the cape', 'near LIGHT foot', 'far DARK foot',
                     '362 × 724', '目视检查斗篷遮臂', '待动作验收', '6→1'):
            with self.subTest(item=item):
                self.assertIn(item, doc)


if __name__ == '__main__':
    unittest.main()
