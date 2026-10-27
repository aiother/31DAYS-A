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
        self.assertEqual([p.name for p in prompts], ["01_player_full.md", "02_hd_background.md", "03_colorless.md",
                                                 "04_boss_overlook.md", "05_boss_parasite.md", "06_weapon_crystal_string.md",
                                                 "06b_weapon_kintsugi_scatter.md"])
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
        self.assertIn("**实体共用一套视觉语言**", section)
        self.assertIn("**风格参考图**", section)
        for approved in ("WSST_05", "BOSS_01", "BOSS_02_2", "player_01_3"):
            self.assertIn(approved, section)
        for word in ("**壳**", "**面甲**", "**细尖的腿**", "**角与触须**", "**披布**"):
            self.assertIn(word, section)
        self.assertIn("头高约为显示高度的 40%", self.spec)
        player = (PROMPTS / "01_player_full.md").read_text(encoding="utf-8")
        self.assertIn("exactly 2.5 heads tall", player)
        self.assertNotIn("6.5", player)

    def test_boss_prompts_follow_the_designs(self):
        overlook = (PROMPTS / "04_boss_overlook.md").read_text(encoding="utf-8")
        for phrase in ("polished leather dress shoe", "sole facing DOWN", "muted gold (#d9a03a) on the shoe's lace eyelets",
                       "staff ID badge", "[FACE]", "contemptuous slits", "fawning crescents", "faint, half-width warm rim light"):
            with self.subTest(prompt="overlook", phrase=phrase):
                self.assertIn(phrase, overlook)
        parasite = (PROMPTS / "05_boss_parasite.md").read_text(encoding="utf-8")
        for phrase in ("two FRONT halves joined at the waist", "both heads awake and in control", "pleading", "broken iron shackle",
                       "#6e1f3a", "ring", "military field canteen", "this parasite end takes no warm light",
                       "NOT as a realistic or anime child", "pale paper face-plate", "not glossy, not fleshy", "Style reference:",
                       "never bright, pink or magenta", "Exactly two thin dark red flesh tubes"):
            with self.subTest(prompt="parasite", phrase=phrase):
                self.assertIn(phrase, parasite)
        for text in (overlook, parasite):
            self.assertIn("no dark background, no vignette, no glow", text)

    def test_player_is_an_artisan_chief(self):
        section = self.style.split("### 6.0 比例与气质")[1].split("### 6.1")[0]
        self.assertIn("`Words/阶层设定.md`", section)
        self.assertIn("**面甲是实体的标志**", section)
        self.assertIn("**玩家是匠首**", section)
        row = re.search(r"^\| 玩家（匠首） \|(.*)$", self.style, re.M).group(1)
        for mark in ("**深色的连体工装**", "**深银色连帽长斗篷**", "**黑色纱网覆面**", "**两点微弱的眼光**", "**识别锚点：萤环与晶弦**", "**兜帽贴着大圆头，帽顶一个软软垂下的尖角**", "**同一种萤石光**", "**内衬近黑的深蓝**", "**玫瑰金几何边纹**"):
            self.assertIn(mark, row)
        self.assertNotIn("围巾", row)
        for name, value in (("匠首深蓝", "1f2740"), ("匠首深银", "b4bac4"), ("玫瑰金", "c08a78"), ("紫水晶", "8a5fa8"), ("萤石蓝紫", "7b84c9"), ("萤石光", "b9c0ff")):
            self.assertIsNotNone(re.search(r"^\| %s \| `#%s` \|" % (name, value), self.style, re.M), name)
        self.assertIn("玩家 `cloth_1…3` 长斗篷下摆与 `hood` 兜帽", self.spec)
        player = (PROMPTS / "01_player_full.md").read_text(encoding="utf-8")
        for phrase in ("#1f2740", "#b4bac4", "no bags, no pouches, no belts, no straps", "NOT a bracelet of beads and NOT a chain", "floating in a loose ring around the WRIST (not around the palm or fingers)", "exactly thirteen small broken blue-violet fluorite fragments", "soft, floppy pointed tip", "lined inside with very dark navy", "same soft bluish fluorite light", "#b9c0ff", "black fine-mesh gauze veil", "two small eyes show, glowing the same soft bluish fluorite light",
                       "#7b84c9", "No scarf, no red anywhere", "floor-length hooded cape", "hangs from the edge of the hood", "do NOT give the character its pale face-plate"):
            with self.subTest(phrase=phrase):
                self.assertIn(phrase, player)
        self.assertNotIn("#b8382c", player)
        rig = self.style.split("**萤环与晶弦**")[1].split("- 可选附加骨骼")[0]
        for mark in ("**萤环**", "**十三枚破碎的萤石碎片**", "**悬浮着环绕手腕缓缓转动**", "**晶弦**", "**拼成一把刀剑**", "**互相契合、又留着细缝**", "**由碎片与光组成的分节直刃**", "**硬的**", "**只改外观，不改玩法**"):
            self.assertIn(mark, rig)
        moves = re.findall(r"^\| (待机|普通攻击 1 段|普通攻击 2 段|向上攻击|向下攻击（弹起）|弹反|奔跑、闪避|恢复|攻击范围成长) \|", rig, re.M)
        self.assertEqual(len(moves), 9)
        self.assertIn("`weapon_starter_part_shard_<两位序号>.png`", self.spec)
        weapon = (PROMPTS / "06_weapon_crystal_string.md").read_text(encoding="utf-8")
        for phrase in ("IDLE", "SLASH", "SWEEP", "DOWNWARD STAB", "NOT a soft silk whip, rope, chain or string of beads", "exactly THIRTEEN fluorite fragments", "NOT whole crystals", "match each other like pieces of a puzzle, yet keep thin even gaps", "perfectly STRAIGHT and rigid", "around the WRIST", "player_01_3.png", "#7b84c9", "#b9c0ff", "assets_src/inbox/art/weapon_starter/"):
            with self.subTest(weapon=phrase):
                self.assertIn(phrase, weapon)

    def test_kintsugi_scatter_study_is_marked_and_complete(self):
        study = (PROMPTS / "06b_weapon_kintsugi_scatter.md").read_text(encoding="utf-8")
        self.assertIn("**探索稿，未定稿**", study)
        for phrase in ("kintsugi", "exactly THIRTEEN", "FORMING", "SLASH", "SCATTER", "DOWNWARD STAB", "perfectly STRAIGHT and rigid",
                       "around the WRIST", "no gold", "**只改外观，不改玩法**"):
            with self.subTest(phrase=phrase):
                self.assertIn(phrase, study)

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
