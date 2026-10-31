"""SYS-013: the durable viewport report covers vertical Rooms and real captures."""
import hashlib
import json
from pathlib import Path
import re
import unittest

from PIL import Image
from tests.test_art_spec import gameplay_camera_defaults

ROOT = Path(__file__).resolve().parents[1]
BUNDLE = ROOT / 'codexandclaude/tasks/SYS-013'


class CameraVisibilityAuditTests(unittest.TestCase):
    def setUp(self):
        self.report = json.loads((BUNDLE / 'captures/audit.json').read_text(encoding='utf-8'))

    def test_every_vertical_room_has_platform_samples(self):
        expected = set()
        for path in (ROOT / 'game/data/world').glob('*.tres'):
            text = path.read_text(encoding='utf-8')
            bounds = re.search(r'(?m)^bounds = Rect2\(([^)]+)\)', text)
            identity = re.search(r'(?m)^room_id = "([^"]+)"', text)
            if bounds and identity and float(bounds[1].split(',')[-1]) > 1080:
                expected.add(identity[1])
        rooms = {room['id']: room for room in self.report['rooms']}
        self.assertEqual(expected, set(rooms))
        for room in rooms.values():
            self.assertEqual(len(room['samples']), 1 + len(room['platforms']))
            self.assertTrue(any('screenshot' in sample for sample in room['samples']))

    def test_recorded_blind_platforms_and_bounds_match_actual_view_rects(self):
        for room in self.report['rooms']:
            targets = {target['name']: target['point'] for target in room['platforms']}
            bx, by, bw, bh = room['bounds']
            for sample in room['samples']:
                with self.subTest(room=room['id'], at=sample['at']):
                    x, y, width, height = sample['view']
                    self.assertAlmostEqual(width, 1920 / gameplay_camera_defaults()["normal_zoom"])
                    self.assertAlmostEqual(height, 1080 / gameplay_camera_defaults()["normal_zoom"])
                    self.assertGreaterEqual(x, bx - 1)
                    self.assertGreaterEqual(y, by - 1)
                    self.assertLessEqual(x + width, bx + bw + 1)
                    self.assertLessEqual(y + height, by + bh + 1)
                    self.assertEqual(set(sample['above']), {name for name, point in targets.items() if point[1] < y})
                    self.assertEqual(set(sample['below']), {name for name, point in targets.items() if point[1] > y + height})

    def test_captures_are_real_full_hd_images_and_match_hash_manifest(self):
        entries = json.loads((BUNDLE / 'captures/manifest.json').read_text(encoding='utf-8'))
        referenced = {sample['screenshot'] for room in self.report['rooms'] for sample in room['samples'] if 'screenshot' in sample}
        referenced.update(sample['screenshot'] for sample in self.report['bosses'])
        self.assertEqual(referenced, set(entries))
        self.assertEqual(referenced, {'captures/' + path.name for path in (BUNDLE / 'captures').glob('*.png')})
        for relative, digest in entries.items():
            path = BUNDLE / relative
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), digest)
            with Image.open(path) as picture:
                self.assertEqual(picture.size, (1920, 1080))

    def test_boss_cues_report_near_and_boundary_cases_for_both_bosses(self):
        samples = self.report['bosses']
        self.assertEqual({(s['id'], s['case']) for s in samples}, {(identity, case) for identity in ('HD_10004_1', 'HD_20003_1') for case in ('near', 'far')})
        for sample in samples:
            x, y, width, height = sample['view']
            cx, cy = sample['cue']
            self.assertEqual(sample['cue_visible'], x <= cx < x + width and y <= cy < y + height)
            self.assertAlmostEqual(sample['zoom'], gameplay_camera_defaults()["battle_zoom"])
        self.assertTrue(any(not sample['cue_visible'] for sample in samples))


if __name__ == '__main__':
    unittest.main()
