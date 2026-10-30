"""ART-001: the style guide and asset spec agree with the game and each other."""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
STYLE = GAME / "docs" / "art_style.md"
SPEC = GAME / "docs" / "asset_spec.md"
PROMPTS = ROOT / "codexandclaude" / "tasks" / "ART-001" / "prompts"
DEPRECATED = "> **已废弃，永不采用（用户 2026-10-29）**"


def dusk_constants():
    source = (GAME / "ui" / "style" / "dusk_style.gd").read_text(encoding="utf-8")
    return {name: value.lower() for name, value in re.findall(r'^const (\w+): Color = Color\("([0-9a-fA-F]{6})"\)', source, re.M)}


class ArtSpecTests(unittest.TestCase):
    def setUp(self):
        self.style = STYLE.read_text(encoding="utf-8")
        self.spec = SPEC.read_text(encoding="utf-8")

    def test_style_is_signed_off(self):
        self.assertIn("状态：**已定稿（2026-10-27，用户确认）**", self.style)
        body = self.style.split("## 10. 变更记录")[0]
        for leftover in ("待用户定稿", "待讨论", "进行中", "待定"):
            with self.subTest(leftover=leftover):
                self.assertNotIn(leftover, body)

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
        zoom = float(re.search(r"const ZOOM: float = ([\d.]+)",
                               (GAME / "world" / "gameplay_camera.gd").read_text(encoding="utf-8")).group(1))
        self.assertEqual(zoom, 1.875)
        self.assertIn("**游戏镜头 ×1.875**", self.spec)
        rows = re.findall(r"^\| [^|]+ \| (\d+)% \| (\d+) px \| (\d+) px[^|]*\| (\d+) px \|$", self.spec, re.M)
        self.assertEqual([int(r[0]) for r in rows], [100, 80, 200, 250])
        for percent, shown, on_screen, delivered in rows:
            with self.subTest(percent=percent):
                self.assertEqual(int(shown), round(player * int(percent) / 100))
                self.assertEqual(int(on_screen), round(int(shown) * zoom))
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
                                                 "06b_weapon_kintsugi_scatter.md", "07_weapon_shard_parts.md", "08_tian_warrior.md",
                                                 "09_player_parts.md"])
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
                                 ("天人战士", "**微笑面具是总指挥下发的稳定器**", "高冠 + 微笑面具与额心红宝石 + 化墨的黑袍下摆")):
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

    def test_humanoid_proportions_follow_the_player_only(self):
        # 用户 2026-10-29：2.5 头身不再是统一要求；2026-10-30：玩家「初页」约 5 头身，其他人形暂无方案。
        section = self.style.split("### 6.0 比例与气质")[1].split("### 6.1")[0]
        self.assertIn("**人形角色比例**：玩家「初页」约 5 头身", section)
        self.assertIn("天人战士的比例**暂无方案**", section)
        self.assertIn("2.5 头身不再是统一要求", section)
        self.assertNotIn("**所有人形角色 2.5 头身**", section)
        self.assertIn("**敌人造型语言参照《丝之歌》**", section)
        self.assertIn("**实体共用一套视觉语言**", section)
        self.assertIn("**风格参考图**", section)
        for approved in ("WSST_05", "BOSS_01", "BOSS_02_2", "tian_02"):
            self.assertIn(approved, section)
        self.assertIn("随原方案废弃，不再作为任何参考", section)
        self.assertIn("`assets_src/inbox/art/tian/tian_02_broken`", self.style)
        for word in ("**壳**", "**面甲**", "**细尖的腿**", "**角与触须**", "**披布**"):
            self.assertIn(word, section)
        self.assertIn("人形角色比例：玩家约 5 头身", self.spec)
        self.assertIn("其他人形角色暂无方案", self.spec)
        self.assertNotIn("头高约为显示高度的 40%", self.spec)

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

    def test_old_player_design_is_abandoned(self):
        # 用户 2026-10-29：“把现在的方案定为废弃，永不采用，并把其他文件中声明这份方案为地基、基础、标准的内容改为暂无方案”。
        section = self.style.split("### 6.0 比例与气质")[1].split("### 6.1")[0]
        self.assertIn("`Words/阶层设定.md`", section)
        self.assertIn("**面甲是实体的标志**", section)
        self.assertIn("玩家在背景故事里仍是匠首，但形象不再按阶层服饰绘制", section)
        self.assertNotIn("**玩家是匠首**", self.style)
        self.assertIsNone(re.search(r"^\| 玩家（匠首） \|", self.style, re.M))
        self.assertIsNone(re.search(r"^\| 玩家 \| \*\*暂无方案\*\*", self.style, re.M))
        self.assertIn("**玩家武器**：暂无方案", self.style)
        self.assertNotIn("**萤环与晶弦**（玩家的初始武器", self.style)
        self.assertNotIn("可选附加骨骼：玩家暂无方案", self.style)
        dead = self.style.split("### 6.3 已废弃的玩家方案")[1].split("## 7.")[0]
        for phrase in ("永不采用", "罩住全身的深银连帽长斗篷", "黑纱覆面透两点眼光", "萤环与晶弦", "`player_01_3`", "四套重设计草稿",
                       "不再作为参考、基础或标准", "reference_video"):
            with self.subTest(phrase=phrase):
                self.assertIn(phrase, dead)
        # 阶层服色仍在（世界观保留），但不再是玩家专属
        for name, value in (("匠首深蓝", "1f2740"), ("匠首深银", "b4bac4"), ("玫瑰金", "c08a78"), ("紫水晶", "8a5fa8"), ("萤石蓝紫", "7b84c9"), ("萤石光", "b9c0ff")):
            self.assertIsNotNone(re.search(r"^\| %s \| `#%s` \|" % (name, value), self.style, re.M), name)
        self.assertIn("玩家不再有固定身份色", self.style)
        self.assertNotIn("玩家：暂无方案", self.spec)
        self.assertIn("玩家武器：暂无方案", self.spec)
        self.assertNotIn("`hood` 兜帽", self.spec)
        self.assertNotIn("weapon_starter_part_shard_01.png", self.spec)
        for name in ("01_player_full.md", "06_weapon_crystal_string.md", "06b_weapon_kintsugi_scatter.md", "07_weapon_shard_parts.md", "09_player_parts.md"):
            with self.subTest(prompt=name):
                self.assertIn(DEPRECATED, (PROMPTS / name).read_text(encoding="utf-8").splitlines()[2])
        refs = ROOT / "codexandclaude" / "tasks" / "ART-001" / "references"
        for name in ("player_body_rig_v1.md", "player_cape_sheet_v1.md", "player_run_sheet_v1.md", "player_run_sheet_v2.md"):
            with self.subTest(reference=name):
                self.assertIn(DEPRECATED, (refs / name).read_text(encoding="utf-8"))

    def test_player_is_first_page(self):
        # 用户 2026-10-30：玩家形象定为 ART-003 方案 A「初页」；身份仍是匠首，只作背景设定；武器待设计。
        row = re.search(r"^\| 玩家（初页） \|(.*)$", self.style, re.M).group(1)
        for mark in ("**初页：承接颜色的人**", "约 **5 头身**", "**白色蓬松短发**", "**翻起的呆毛**", "**翻折的高立领**",
                     "**白色菱形扣**", "**三片式短三角披衣**", "**翻折靴口的短靴**", "**全身近乎纯白**", "**身份**：背景故事里仍是匠首",
                     "`phf/原案v0.1.png`", "`phf/步行逐帧图2.png`"):
            with self.subTest(mark=mark):
                self.assertIn(mark, row)
        for gone in ("斗篷", "连帽", "黑纱", "萤"):
            self.assertNotIn(gone, row)
        for name, value in (("初页白", "f9f7f4"), ("初页灰", "ddd6d3"), ("初页线", "3c393a")):
            self.assertIsNotNone(re.search(r"^\| %s \| `#%s` \|" % (name, value), self.style, re.M), name)
        tint = self.style.split("**初页的染色**")[1].split("- 可选附加骨骼")[0]
        for rule in ("**与同伴建立关系**", "**始终留白**", "脸与胸前不染", "独立颜色遮罩"):
            self.assertIn(rule, tint)
        bones = ("forelock", "hair_front", "hair_back", "collar", "clasp", "cape_back", "cape_front_near", "cape_front_far")
        extra = re.search(r"^- 可选附加骨骼：玩家用 (.*)$", self.style, re.M).group(1)
        for bone in bones:
            with self.subTest(bone=bone):
                self.assertIn("`%s`" % bone, extra)
                self.assertIn("`%s`" % bone, self.spec)
        parts = (ROOT / "codexandclaude" / "proposals" / "ART-003" / "first_page_v1" / "README.md").read_text(encoding="utf-8")
        for bone in bones:
            self.assertIn("| `%s` | `%s` |" % (bone, bone), parts)
        for path in ("原案v0.1.png", "三视图_1.png", "部件_1.png", "步行逐帧图2.png"):
            self.assertTrue((ROOT / "phf" / path).is_file(), path)
        self.assertIn("两只手腕都留武器挂点", self.style)
        self.assertIn("`player_tint_<骨骼名>_<两位序号>.png`", self.spec)
        self.assertIn("现行玩家形象为第 6.2 节的「初页」", self.style.split("### 6.3 已废弃的玩家方案")[1])
        self.assertIn("A-021", self.style.split("## 2.")[0])
        register = (ROOT / "Words" / "待决事项总表.md").read_text(encoding="utf-8")
        self.assertRegex(register, r"(?m)^\| A-021 \| 白色玩家「初页」与已定稿世界风格如何统一 \|.*\| 待裁决 \|$")

    def test_player_parts_list_is_complete(self):
        # ART-001 review R1: every player part has a file, contents, bone, layer,
        # source and overlap note, and the bones are those of asset_spec.md.
        parts = (PROMPTS / "09_player_parts.md").read_text(encoding="utf-8")
        self.assertIn("`09_player_parts.md`", (PROMPTS / "01_player_full.md").read_text(encoding="utf-8"))
        self.assertIn("player_01_3.png", parts)
        self.assertIn("**15% 重叠区**", parts)
        rows = re.findall(r"^\| `(player_part_\w+\.png)` \| ([^|]+) \| `(\w+)` \| (\d+) \| ([^|]+) \| ([^|]+) \|$", parts, re.M)
        names = [r[0] for r in rows]
        expected = {"cape_back": "chest", "cape_lining": "chest", "cape_front": "chest", "hood": "hood", "hood_rim": "hood",
                    "veil": "head", "head": "head", "chest": "chest", "hip": "hip",
                    "cloth_1": "cloth_1", "cloth_2": "cloth_2", "cloth_3": "cloth_3"}
        for side in ("near", "far"):
            for limb in ("arm_upper", "arm_lower", "hand", "leg_upper", "leg_lower", "foot"):
                expected["%s_%s" % (limb, side)] = "%s_%s" % (limb, side)
        self.assertEqual(sorted(names), sorted("player_part_%s.png" % k for k in expected))
        tree = self.spec.split("人形标准骨骼")[1].split("```")[1]
        bones = set(re.findall(r"[a-z_]+", tree)) | {"hood", "cloth_1", "cloth_2", "cloth_3"}
        layers = [int(r[3]) for r in rows]
        self.assertEqual(layers, list(range(1, len(rows) + 1)))
        by_name = {r[0]: r for r in rows}
        for key, bone in expected.items():
            row = by_name["player_part_%s.png" % key]
            with self.subTest(part=key):
                self.assertEqual(row[2], bone)
                self.assertIn(bone, bones)
                self.assertIn(row[4].strip(), ("切图", "补画", "切图 + 补画"))
                self.assertIn("15%", row[5])
        # Hidden parts are painted, far limbs lie behind the body and near ones in front.
        for side_part in ("arm_upper_far", "arm_lower_far", "hand_far", "leg_upper_far", "leg_lower_far", "foot_far", "head", "hip", "cape_back", "cape_lining"):
            self.assertEqual(by_name["player_part_%s.png" % side_part][4].strip(), "补画", side_part)
        layer = {k: int(by_name["player_part_%s.png" % k][3]) for k in expected}
        self.assertLess(layer["arm_upper_far"], layer["chest"])
        self.assertLess(layer["leg_upper_far"], layer["hip"])
        self.assertLess(layer["hood"], layer["head"])
        self.assertLess(layer["head"], layer["veil"])
        self.assertLess(layer["veil"], layer["hood_rim"])
        self.assertLess(layer["cape_back"], layer["chest"])
        self.assertLess(layer["chest"], layer["cape_front"])
        self.assertLess(layer["cape_front"], layer["arm_lower_near"])
        self.assertIn("`cloth_1` 挂 `hip`、`cloth_2` 挂 `cloth_1`、`cloth_3` 挂 `cloth_2`", parts)
        self.assertIn("This is the far-side limb", parts)
        self.assertIn("Draw the whole part, including what the cape hides", parts)
        self.assertIn("萤环不画在手上", parts)

    def test_kintsugi_scatter_study_is_marked_and_complete(self):
        study = (PROMPTS / "06b_weapon_kintsugi_scatter.md").read_text(encoding="utf-8")
        self.assertIn("**探索稿，已收尾**", study)
        self.assertIn("**不采纳**", study)
        for phrase in ("kintsugi", "exactly THIRTEEN", "FORMING", "SLASH", "SCATTER", "DOWNWARD STAB", "perfectly STRAIGHT and rigid",
                       "around the WRIST", "no gold", "**只改外观，不改玩法**"):
            with self.subTest(phrase=phrase):
                self.assertIn(phrase, study)

    def test_blade_prompt_is_kept_only_as_history(self):
        blade = (PROMPTS / "07_weapon_shard_parts.md").read_text(encoding="utf-8")
        self.assertIn(DEPRECATED, blade)
        self.assertIn("ONE complete, unbroken sword blade", blade)  # 历史内容原样保留
        self.assertNotIn("**工具沿参差的折线切成十三片**", self.style)
        self.assertNotIn("由切割工具把整刃沿参差的折线切成**十三片**", self.spec)

    def test_tian_warrior_follows_the_class_design(self):
        row = re.search(r"^\| 天人战士 \| \*\*世界最上层的人(.*)$", self.style, re.M).group(1)
        for mark in ("**高冠、高立领与及地黑袍**", "**电路般的直角几何纹**", "**红宝石核心**", "**重击前摇时红宝石亮起朱红**",
                     "**黑袍与墨分不清**", "**低血量时面具崩掉一角，缺口里是黑洞、没有脸，裂口渗出墨**", "**唯一保持人形**"):
            with self.subTest(mark=mark):
                self.assertIn(mark, row)
        self.assertNotIn("白色科技护甲", row)
        for name, value in (("红宝石", "8e1c2e"), ("黑曜石", "1a1620")):
            self.assertIsNotNone(re.search(r"^\| %s \| `#%s` \|" % (name, value), self.style, re.M), name)
        for part in ("`tian_part_mask.png`", "`tian_part_mask_cracked.png`", "`tian_part_crown.png`"):
            self.assertIn(part, self.spec)
        tian = (PROMPTS / "08_tian_warrior.md").read_text(encoding="utf-8")
        for phrase in ("exactly 2.5 heads tall", "tall pointed gold crown", "right-angled geometric lines like a circuit pattern", "NOT lightning",
                       "dissolved into dripping ink", "[MASK]", "NOT glowing", "has chipped off and is gone", "only flat pure black void, no face", "streaks of ink seep from the broken edge", "tian_02_broken.png", "do NOT give this character a pale face-plate",
                       "tian_01.png", "change ONLY the face", "clearly GOLD mask", "NOT a black face and NOT a black helmet", "clearly visible deep red ruby"):
            with self.subTest(phrase=phrase):
                self.assertIn(phrase, tian)

    def test_regions_carry_dark_room_traces_and_day_fade(self):
        scene = self.style.split("## 7. 场景")[1].split("## 8.")[0]
        rows = re.findall(r"^\| (荒地 HD|田野 TY|逆时战场 NSZC) \|", scene, re.M)
        self.assertEqual(rows, ["荒地 HD", "田野 TY", "逆时战场 NSZC"])
        for mark in ("**天空顶端有墨往下渗**", "**夕阳是一张扁平的纸剪太阳**", "**时间倒着走**", "**灰暗的暖灰**",
                     "**世界随日子褪色（D）**", "**只作用于背景层**", "**不画三套背景**", "**可读性**"):
            with self.subTest(mark=mark):
                self.assertIn(mark, scene)
        self.assertNotIn("淡蓝 → 白日纸色", scene)
        hd = (PROMPTS / "02_hd_background.md").read_text(encoding="utf-8")
        self.assertIn("dark ink (#2b2420) seeps down into the picture", hd)

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
