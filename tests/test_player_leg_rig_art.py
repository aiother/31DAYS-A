"""Delivery checks for the leg motion reference (not runtime animation tests)."""
import unittest
from pathlib import Path

from PIL import Image, ImageStat

ART = Path(__file__).resolve().parents[1] / 'codexandclaude/tasks/ART-001/references'


class PlayerLegRigArtTests(unittest.TestCase):
    def test_reference_decodes_and_is_readable_landscape(self):
        path = ART / 'player_leg_rig_v1.png'
        with Image.open(path) as image:
            image.verify()
        with Image.open(path) as image:
            self.assertEqual(image.format, 'PNG')
            self.assertGreaterEqual(image.width, 1500)
            self.assertGreaterEqual(image.height, 900)
            self.assertGreater(image.width, image.height)
            # Reject an empty/solid delivery; typography and diagram need contrast.
            self.assertGreater(ImageStat.Stat(image.convert('L')).stddev[0], 20)

    def test_handoff_documents_scope_and_existing_reference(self):
        doc = (ART / 'player_leg_rig_v1.md').read_text(encoding='utf-8')
        for item in ('image_gen', 'player_run_sheet_v2.png', '2.5', '髋', '膝',
                     '踝', '脚掌', '近腿', '远腿', '01', '06', '非运行时',
                     '目视', '骨长', '最终提示词'):
            with self.subTest(item=item):
                self.assertIn(item, doc)


if __name__ == '__main__':
    unittest.main()
