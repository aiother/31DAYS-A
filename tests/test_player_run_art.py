"""Structural checks for the generated six-frame run draft, not motion approval."""
import unittest
from pathlib import Path

from PIL import Image

ART = Path(__file__).resolve().parents[1] / 'codexandclaude/tasks/ART-001/references'


class PlayerRunArtTests(unittest.TestCase):
    def test_six_separate_frames_fit_equal_cells(self):
        path = ART / 'player_run_sheet_v1.png'
        with Image.open(path) as image:
            self.assertEqual(image.format, 'PNG')
            image.verify()
        with Image.open(path) as image:
            self.assertEqual(image.mode, 'RGBA')
            self.assertEqual(image.size, (2172, 724))
            alpha = image.getchannel('A')
            self.assertEqual(alpha.getextrema(), (0, 255))
            # Ignore faint generation noise when locating visible silhouettes.
            visible = alpha.point(lambda value: 255 if value > 32 else 0)
            bounds = []
            occupied = []
            for x in range(image.width):
                occupied.append(visible.crop((x, 0, x + 1, image.height)).getbbox() is not None)
            starts = sum(on and (x == 0 or not occupied[x - 1]) for x, on in enumerate(occupied))
            self.assertEqual(starts, 6)
            for index in range(6):
                cell = visible.crop((index * 362, 0, (index + 1) * 362, 724))
                bound = cell.getbbox()
                self.assertIsNotNone(bound)
                left, top, right, bottom = bound
                self.assertGreaterEqual(left, 7)
                self.assertLess(right, 362)
                self.assertGreater(top, 0)
                self.assertLess(bottom, 724)
                self.assertGreater(right - left, 250)
                bounds.append(bound)
            # Compression poses sit below each adjacent contact/rise pose.
            for low, before, after in ((1, 0, 2), (4, 3, 5)):
                self.assertGreater(bounds[low][1], bounds[before][1] + 20)
                self.assertGreater(bounds[low][1], bounds[after][1] + 20)

    def test_prompt_provenance_and_draft_status_are_recorded(self):
        doc = (ART / 'player_run_sheet_v1.md').read_text(encoding='utf-8')
        for item in ('image_gen', 'player_01_3.png', 'exactly SIX frames',
                     '362 × 724', '12 fps', '初稿', '尚未接入', '第 6→1',
                     'No weapon', 'No red anywhere', 'No teal or cyan anywhere'):
            with self.subTest(item=item):
                self.assertIn(item, doc)


if __name__ == '__main__':
    unittest.main()
