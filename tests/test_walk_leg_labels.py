"""Delivery checks for the annotated source; not pose classification tests."""
import unittest
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'codexandclaude/tasks/ART-001/references'


class WalkLegLabelsTests(unittest.TestCase):
    def test_annotated_reference_decodes(self):
        with Image.open(ART / 'human_walk_leg_labels_v1.png') as image:
            self.assertEqual(image.format, 'PNG')
            self.assertGreaterEqual(image.width, 1500)
            self.assertGreater(image.width / image.height, 2)
            image.verify()

    def test_character_relative_left_right_convention_is_saved(self):
        doc = (ART / 'human_walk_leg_labels_v1.md').read_text(encoding='utf-8')
        for text in ('右腿＝虚线', '左腿＝实线', '角色自身', '01–10', 'image_gen'):
            self.assertIn(text, doc)
        animation_doc = (ROOT / 'game/docs/character_animation.md').read_text(encoding='utf-8')
        self.assertIn('右腿＝虚线、左腿＝实线', animation_doc)


if __name__ == '__main__':
    unittest.main()
