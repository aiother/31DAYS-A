"""Validate the supplemental rig reference without external imaging libraries."""
import struct
import unittest
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'codexandclaude/tasks/ART-001/references'


class PlayerBodyArtTests(unittest.TestCase):
    def test_png_is_intact_rgba_with_transparent_top_margin(self):
        data = (ART / 'player_body_rig_v1.png').read_bytes()
        self.assertEqual(data[:8], b'\x89PNG\r\n\x1a\n')
        offset, chunks = 8, {}
        while offset < len(data):
            size = struct.unpack('>I', data[offset:offset + 4])[0]
            kind = data[offset + 4:offset + 8]
            payload = data[offset + 8:offset + 8 + size]
            crc = struct.unpack('>I', data[offset + 8 + size:offset + 12 + size])[0]
            self.assertEqual(zlib.crc32(kind + payload) & 0xffffffff, crc)
            chunks.setdefault(kind, []).append(payload)
            offset += size + 12
        self.assertEqual(offset, len(data))
        self.assertIn(b'IEND', chunks)
        width, height, depth, colour, compression, filtering, interlace = struct.unpack('>IIBBBBB', chunks[b'IHDR'][0])
        self.assertGreaterEqual(min(width, height), 1024)
        self.assertEqual((depth, colour, compression, filtering, interlace), (8, 6, 0, 0, 0))
        raw = zlib.decompress(b''.join(chunks[b'IDAT']))
        self.assertEqual(len(raw), height * (width * 4 + 1))
        # First row has no previous row. Undo its PNG filter to inspect alpha.
        mode, row = raw[0], bytearray(raw[1:width * 4 + 1])
        self.assertIn(mode, range(5))
        for i in range(len(row)):
            left = row[i - 4] if i >= 4 else 0
            predictor = left if mode in (1, 4) else left // 2 if mode == 3 else 0
            row[i] = (row[i] + predictor) & 255
        self.assertTrue(all(alpha == 0 for alpha in row[3::4]))

    def test_provenance_and_prompt_preserve_user_constraints(self):
        doc = (ART / 'player_body_rig_v1.md').read_text(encoding='utf-8')
        for constraint in ('player_01_3.png', 'image_gen', '2.5 heads', '#1f2740',
                           'NO features', 'No red anywhere', 'No teal or cyan anywhere',
                           'transparent background', '15%'):
            with self.subTest(constraint=constraint):
                self.assertIn(constraint, doc)


if __name__ == '__main__':
    unittest.main()
