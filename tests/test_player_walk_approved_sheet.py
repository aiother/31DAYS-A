"""Check delivery and slicing safety, not biomechanical pose correctness."""
import unittest
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'codexandclaude/tasks/ART-001/references'


class PlayerWalkApprovedSheetTests(unittest.TestCase):
    def test_transparent_ten_cell_sheet_has_complete_separated_figures(self):
        path = ART / 'player_walk_approved_sheet_v1.png'
        with Image.open(path) as image:
            image.verify()
        with Image.open(path) as image:
            self.assertEqual(image.mode, 'RGBA')
            self.assertGreaterEqual(image.width, 1500)
            alpha = image.getchannel('A')
            self.assertEqual(alpha.getextrema()[0], 0)
            self.assertGreaterEqual(alpha.getextrema()[1], 250)
            for row in range(2):
                for col in range(5):
                    box = (round(col * image.width / 5), round(row * image.height / 2),
                           round((col + 1) * image.width / 5), round((row + 1) * image.height / 2))
                    cell = alpha.crop(box).point(lambda a: 255 if a > 32 else 0)
                    bound = cell.getbbox()
                    self.assertIsNotNone(bound, f'empty frame {row * 5 + col + 1}')
                    left, top, right, bottom = bound
                    self.assertGreaterEqual(left, 4)
                    self.assertGreaterEqual(top, 4)
                    self.assertLessEqual(right, cell.width - 4)
                    self.assertLessEqual(bottom, cell.height - 4)
                    self.assertGreater((right-left)*(bottom-top), cell.width*cell.height*.1)

    def test_source_roles_and_review_status_are_documented(self):
        doc = (ART / 'player_walk_approved_sheet_v1.md').read_text(encoding='utf-8')
        for item in ('player_01_3.png', 'human_walk_approved_legs_v1.png', '5×2',
                     '朝左', 'image_gen', '待用户', '未接入', '最终提示词'):
            self.assertIn(item, doc)


if __name__ == '__main__':
    unittest.main()
