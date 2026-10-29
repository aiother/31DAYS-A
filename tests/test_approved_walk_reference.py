"""Protect the user's explicitly approved pose source and extraction delivery."""
import hashlib
import unittest
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'codexandclaude/tasks/ART-001/references'


class ApprovedWalkReferenceTests(unittest.TestCase):
    def test_approved_source_is_preserved_verbatim(self):
        source = ART / 'human_walk_approved_v1.png'
        self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(),
                         '8cc08d4b9415c1a9848fd0d6843c813d3da23ad2e6f495d88322df08beed6c53')
        with Image.open(source) as image:
            image.verify()

    def test_leg_extraction_is_valid_wide_png(self):
        with Image.open(ART / 'human_walk_approved_legs_v1.png') as image:
            self.assertEqual(image.format, 'PNG')
            self.assertGreaterEqual(image.width, 1500)
            self.assertGreater(image.width / image.height, 2)
            image.verify()

    def test_animation_handoff_keeps_user_approved_reference(self):
        doc = (ROOT / 'game/docs/character_animation.md').read_text(encoding='utf-8')
        for text in ('human_walk_approved_v1.png', '01–10', '用户确认', '不作为已认可'):
            self.assertIn(text, doc)


if __name__ == '__main__':
    unittest.main()
