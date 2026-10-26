"""ART-001: the style guide and asset spec agree with the game and each other."""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
STYLE = GAME / "docs" / "art_style.md"
SPEC = GAME / "docs" / "asset_spec.md"
PROMPTS = ROOT / "codexandclaude" / "tasks" / "ART-001" / "prompts"


def dusk_constants():
    source = (GAME / "ui" / "style" / "dusk_style.gd").read_text(encoding="utf-8")
    return {name: value.lower() for name, value in re.findall(r'^const (\w+): Color = Color\("([0-9a-fA-F]{6})"\)', source, re.M)}


class ArtSpecTests(unittest.TestCase):
    def setUp(self):
        self.style = STYLE.read_text(encoding="utf-8")
        self.spec = SPEC.read_text(encoding="utf-8")

    def test_palette_matches_dusk_style(self):
        colours = dusk_constants()
        rows = {"墨 INK": "INK", "珍珠白 PEARL": "PEARL", "白日纸色": "PAPER_DAY", "黄昏纸色": "PAPER_DUSK",
                "黄昏顶": "DUSK_TOP", "黄昏底": "DUSK_BOTTOM", "日光": "SUN", "生命红": "LIFE",
                "可能性青": "POSSIBILITY", "成长金": "GROWTH"}
        for label, constant in rows.items():
            with self.subTest(colour=label):
                row = re.search(r"^\| %s \| `#([0-9a-f]{6})`" % re.escape(label), self.style, re.M)
                self.assertIsNotNone(row)
                self.assertEqual(row.group(1), colours[constant])
        self.assertIn("`#9fe6d6`", self.style)
        self.assertEqual(colours["POSSIBILITY_GLOW"], "9fe6d6")

    def test_heights_follow_t6e_and_double_delivery(self):
        player = 112
        rows = re.findall(r"^\| [^|]+ \| (\d+)% \| (\d+) px \| (\d+) px \|$", self.spec, re.M)
        self.assertEqual([int(r[0]) for r in rows], [100, 80, 200, 250])
        for percent, shown, delivered in rows:
            with self.subTest(percent=percent):
                self.assertEqual(int(shown), round(player * int(percent) / 100))
                self.assertEqual(int(delivered), 2 * int(shown))
        self.assertIn("`Art` 节点缩放 0.5", self.spec)

    def test_capsules_named_as_in_the_player_scene(self):
        scene = (GAME / "player" / "player.tscn").read_text(encoding="utf-8")
        heights = dict(re.findall(r'\[sub_resource type="CapsuleShape2D" id="(\w+)"\]\n(?:[^\[]*?\n)?height = ([\d.]+)', scene))
        self.assertEqual(float(heights["Body"]), 96.0)
        self.assertEqual(float(heights["PhysicsBody"]), 88.0)
        self.assertIn("**受击胶囊高 96 px**（`Body`", self.spec)
        self.assertIn("**物理胶囊高 88 px**（`PhysicsBody`", self.spec)

    def test_spec_keeps_the_inbox_out_and_points_to_credits(self):
        self.assertIn("**整个 `assets_src/` 不入库**", self.spec)
        credits = (GAME / "assets" / "CREDITS.md").read_text(encoding="utf-8")
        for column in ("文件", "来源", "授权", "作者 / 署名", "日期", "改动", "备注"):
            self.assertIn("| %s |" % column, credits)
        self.assertIn("**禁止**任何 NC（禁止商用）或 ND（禁止改编）类授权", credits)

    def test_every_prompt_carries_the_style_block_and_checks(self):
        template = (PROMPTS / "template.md").read_text(encoding="utf-8")
        block = re.search(r"## 1\. 风格块.*?```\n(.*?)```", template, re.S).group(1).strip()
        first_sentence = block.split(". ")[0]
        prompts = sorted(PROMPTS.glob("0*.md"))
        self.assertEqual([p.name for p in prompts], ["01_player_full.md", "02_hd_background.md", "03_colorless.md"])
        for path in prompts:
            text = path.read_text(encoding="utf-8")
            with self.subTest(prompt=path.name):
                self.assertIn(first_sentence, text)
                self.assertIn("## 验收要点", text)
                self.assertIn("No teal or cyan anywhere" if "colorless" not in path.name else "No colours other than ink", text)
                self.assertIn("assets_src/inbox/art/", text)

    def test_enemies_keep_their_own_looks(self):
        table = self.style.split("## 6. 角色形象要点")[1].split("## 7.")[0]
        for name, mark in (("无色实体", "**没有自己的颜色**"), ("单色实体", "只用**一种**强调色"),
                           ("天人战士", "**金色装饰**"), ("渴望俯视（Boss）", "**悬空的巨眼**"),
                           ("寄生同伴者（Boss）", "**口与触须**")):
            with self.subTest(enemy=name):
                row = re.search(r"^\| %s \|(.*)$" % re.escape(name), table, re.M)
                self.assertIsNotNone(row)
                self.assertIn(mark, row.group(1))


if __name__ == "__main__":
    unittest.main()
