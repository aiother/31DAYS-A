"""Check the cape sheet's delivery format, white margins and provenance."""
import unittest
from pathlib import Path

from PIL import Image

ART = Path(__file__).resolve().parents[1] / 'codexandclaude/tasks/ART-001/references'


class PlayerCapeArtTests(unittest.TestCase):
    def test_complete_white_background_sheet(self):
        path = ART / 'player_cape_sheet_v1.png'
        with Image.open(path) as image:
            self.assertEqual(image.format, 'PNG')
            image.verify()
        with Image.open(path) as source:
            self.assertEqual(source.size, (1536, 1024))
            self.assertEqual(source.mode, 'RGB')
            image = source.convert('RGB')
            width, height = image.size
            # No dark backdrop or clipping along any canvas edge.
            border = [(x, 0) for x in range(width)] + [(x, height - 1) for x in range(width)]
            border += [(0, y) for y in range(height)] + [(width - 1, y) for y in range(height)]
            self.assertTrue(all(min(image.getpixel(point)) >= 240 for point in border))
            # Both halves contain substantial cloth, rather than an empty view.
            for box in ((0, 0, width // 2, height), (width // 2, 0, width, height)):
                panel = image.crop(box).convert('L')
                ink = sum(panel.histogram()[:180])
                self.assertGreater(ink, panel.width * panel.height // 5)
            self.assertGreaterEqual(min(image.getpixel((800, 100))), 240)

    def test_prompt_and_delivery_limitations_are_recorded(self):
        doc = (ART / 'player_cape_sheet_v1.md').read_text(encoding='utf-8')
        for item in ('image_gen', 'player_01_3.png', 'LEFT:', 'RIGHT:', '#b4bac4',
                     '#1f2740', '#c08a78', 'No hood', 'no clasp', 'No red anywhere',
                     'No teal or cyan anywhere', '非透明', '未拆分'):
            with self.subTest(item=item):
                self.assertIn(item, doc)


if __name__ == '__main__':
    unittest.main()
