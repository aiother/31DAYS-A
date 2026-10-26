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
        ignored = (ROOT / ".gitignore").read_text(encoding="utf-8").splitlines()
        self.assertIn("/assets_src/", [line.strip() for line in ignored])
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
        table = self.style.split("### 6.2 各角色")[1].split("## 7.")[0]
        for name, mark, sign in (("无色实体", "**空白的纸色面甲**", "空白面甲的墨壳 + 灰色的物件与遗存"),
                                 ("单色实体", "**只有一种颜色**", "弯角面甲 + 披着外套的壳 + 唯一的紫"),
                                 ("天人战士", "**唯一保持人形**", "微笑面具 + 尖顶白盔与披风 + 末端的墨")):
            with self.subTest(enemy=name):
                row = re.search(r"^\| %s \|(.*)$" % re.escape(name), table, re.M)
                self.assertIsNotNone(row)
                cells = [c.strip() for c in row.group(1).split("|")]
                self.assertIn(mark, cells[0])
                self.assertEqual(cells[1], sign)
        for boss, mark, sign in (("渴望俯视（Boss）", "**住在一只精致皮鞋里的飞虫**", "皮鞋壳 + 金鞋扣 + 随高低变脸"),
                                 ("寄生同伴者（Boss）", "**两个头都有主导意识**", "双前半身：哀求的人头 + 口器虫头")):
            with self.subTest(boss=boss):
                row = re.search(r"^\| %s \|(.*)$" % re.escape(boss), table, re.M)
                cells = [c.strip() for c in row.group(1).split("|")]
                self.assertIn(mark, cells[0])
                self.assertEqual(cells[1], sign)
        for part in ("`boss_overlook_part_item_shoe.png`", "`boss_overlook_part_face_scorn.png`", "`boss_overlook_part_face_fawn.png`",
                     "`boss_overlook_part_remnant_badge.png`", "`head_human`", "`head_parasite`", "`boss_parasite_part_item_canteen.png`"):
            with self.subTest(part=part):
                self.assertIn(part, self.spec)

    def test_enemy_framework_is_written_down(self):
        frame = self.style.split("### 6.1 敌人设计框架")[1].split("### 6.2")[0]
        self.assertIn("`Words/怪物设定.md`", frame)
        for phrase in ("**同化 = 压缩**", "**保留的细节量 = 保留的意识**", "**颜色即身份**", "**生前身份**",
                       "**姿态说明心智**", "**每个敌人一个清楚的动词**", "**克制**",
                       "**逐级去人化**", "**人的遗存**", "**生前最重要的那一部分**"):
            with self.subTest(rule=phrase):
                self.assertIn(phrase, frame)
        tiers = re.findall(r"^\| (无色实体|单色实体|天人战士) \|", frame, re.M)
        self.assertEqual(tiers, ["无色实体", "单色实体", "天人战士"])
        self.assertIn("**边光随意识递减**", self.style.split("## 4. 光")[1].split("## 5.")[0])
        self.assertNotIn("后室", self.style.split("## 10. 变更记录")[0])
        self.assertIn("`<对象>_part_item_<名称>.png`", self.spec)
        self.assertIn("幸存者战士、天人）：", self.spec)
        self.assertIn("`<对象>_part_remnant_<名称>.png`", self.spec)
        self.assertIn("**物件要考究**", frame)
        self.assertIn("**细节密度**", frame)
        for gone in ("interp = 0", "_part_embed_"):
            self.assertNotIn(gone, self.spec.split("## 9. 变更记录")[0])

    def test_characters_are_two_and_a_half_heads(self):
        section = self.style.split("### 6.0 比例与气质")[1].split("### 6.1")[0]
        self.assertIn("**所有人形角色 2.5 头身**", section)
        self.assertIn("**敌人造型语言参照《丝之歌》**", section)
        for word in ("**壳**", "**面甲**", "**细尖的腿**", "**角与触须**", "**披布**"):
            self.assertIn(word, section)
        self.assertIn("头高约为显示高度的 40%", self.spec)
        player = (PROMPTS / "01_player_full.md").read_text(encoding="utf-8")
        self.assertIn("exactly 2.5 heads tall", player)
        self.assertNotIn("6.5", player)

    def test_colorless_prompt_follows_the_framework(self):
        template = (PROMPTS / "template.md").read_text(encoding="utf-8")
        light = re.search(r"无色实体把风格块.*?```\n(.*?)```", template, re.S).group(1).strip()
        text = (PROMPTS / "03_colorless.md").read_text(encoding="utf-8")
        self.assertIn(light, text)
        self.assertNotIn("rim light (#f4b860)", text)
        for phrase in ("no face", "[OBJECT]", "[FORM]", "[REMNANT]", "no longer human in shape", "in the style of Silksong's creatures", "greyed out", "intact and true to life", "no dark background, no vignette, no glow", "three to five bold key features", "**按区域填三处**", "**人的遗存**"):
            with self.subTest(phrase=phrase):
                self.assertIn(phrase, text)

if __name__ == "__main__":
    unittest.main()
