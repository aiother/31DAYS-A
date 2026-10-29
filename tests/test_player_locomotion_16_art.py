"""Check delivery integrity of the two 16-pose reference sheets."""
import unittest
import json
import math
from pathlib import Path

from PIL import Image, ImageStat
from scripts.build_player_locomotion_reference import pose, THIGH, SHIN, GROUND

ART = Path(__file__).resolve().parents[1] / 'codexandclaude/tasks/ART-001/references'


class PlayerLocomotion16ArtTests(unittest.TestCase):
    def test_fixed_bones_ground_contacts_and_two_flight_windows(self):
        data = json.loads((ART / 'player_locomotion_16_rig_v1.json').read_text())
        for motion in ('walk', 'run'):
            poses = data['motions'][motion]['poses']
            self.assertEqual(len(poses), 16)
            flights = []
            for n, frame in enumerate(poses):
                self.assertEqual(frame, json.loads(json.dumps(pose(motion, n / 16))))
                planted = sum(leg['planted'] for leg in frame['legs'].values())
                if motion == 'walk':
                    self.assertGreaterEqual(planted, 1)
                else:
                    self.assertLessEqual(planted, 1)
                if frame['flight']:
                    flights.append(n + 1)
                for leg in frame['legs'].values():
                    self.assertAlmostEqual(math.dist(leg['hip'], leg['knee']), THIGH)
                    self.assertAlmostEqual(math.dist(leg['knee'], leg['ankle']), SHIN)
                    self.assertAlmostEqual(math.dist(leg['heel'], leg['toe']), 11)
                    lowest = max(leg['heel'][1], leg['toe'][1])
                    self.assertLessEqual(lowest, GROUND + 1e-8)
                    if leg['planted']:
                        self.assertAlmostEqual(lowest, GROUND)
                    if frame['flight']:
                        self.assertLess(lowest, GROUND)
            self.assertEqual(flights, [] if motion == 'walk' else [7, 8, 15, 16])

    def test_loop_boundary_and_liftoff_are_continuous(self):
        for motion, lift in [('walk', .625), ('run', .36)]:
            for phase in (0, .5, lift, (lift + .5) % 1):
                before, after = pose(motion, phase - 1e-7), pose(motion, phase + 1e-7)
                for side in ('near', 'far'):
                    for joint in ('hip', 'knee', 'ankle', 'heel', 'toe'):
                        self.assertLess(math.dist(before['legs'][side][joint],
                                                  after['legs'][side][joint]), .001)

    def test_gifs_have_sixteen_distinct_frames_and_loop(self):
        for motion, duration in [('walk', 80), ('run', 50)]:
            with Image.open(ART / f'player_{motion}_16_preview_v1.gif') as image:
                self.assertEqual(image.n_frames, 16)
                self.assertEqual(image.info['loop'], 0)
                frames = []
                for n in range(16):
                    image.seek(n)
                    self.assertEqual(image.info['duration'], duration)
                    frames.append(image.convert('RGB').tobytes())
                self.assertEqual(len(set(frames)), 16)

    def test_both_sheets_decode_and_have_content_throughout_grid(self):
        for motion in ('walk', 'run'):
            with self.subTest(motion=motion):
                path = ART / f'player_{motion}_16_rig_v1.png'
                with Image.open(path) as image:
                    image.verify()
                with Image.open(path) as image:
                    self.assertEqual(image.format, 'PNG')
                    self.assertGreaterEqual(image.width, 1500)
                    self.assertGreaterEqual(image.height, 900)
                    # Coarse content coverage; does not certify pose or contact accuracy.
                    gray = image.convert('L')
                    for row in range(4):
                        for col in range(4):
                            region = gray.crop((col * image.width // 4,
                                                row * image.height // 4,
                                                (col + 1) * image.width // 4,
                                                (row + 1) * image.height // 4))
                            self.assertGreater(ImageStat.Stat(region).stddev[0], 12)

    def test_handoff_includes_both_prompts_and_playback_scope(self):
        doc = (ART / 'player_locomotion_16_rig_v1.md').read_text(encoding='utf-8')
        for text in ('image_gen', 'player_leg_rig_v1.png', '4×4', '16→01',
                     '非运行时', '目视', '骨长', '走路', '跑步',
                     'Walking gait', 'Running gait', '01', '16'):
            with self.subTest(text=text):
                self.assertIn(text, doc)


if __name__ == '__main__':
    unittest.main()
