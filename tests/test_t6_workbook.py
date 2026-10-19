"""验证T6空白填写模板的覆盖、保留值、下拉及待验收状态。"""
from pathlib import Path
import os
import subprocess
import tempfile
import unittest
import openpyxl

FILE = Path(__file__).resolve().parents[1] / "Words" / "T6_资源配置填写模板.xlsx"
SHEETS = {
    "T6-A 实体资源": (16, 5, (4, 5)),
    "T6-B1 玩家动画": (19, 4, (3, 4)),
    "T6-B2 NPC敌人动画": (9, 4, (3, 4)),
    "T6-C 地图环境": (13, 4, (3, 4)),
    "T6-D1 视觉特效": (12, 4, (3, 4)),
    "T6-D2 音效音乐": (13, 4, (3, 4)),
    "T6-D3 剧情演出": (10, 5, (3, 4, 5)),
    "T6-E 制作原则": (12, 3, (3,)),
    "T6-F 最终验收": (14, 4, (4,)),
}


class T6WorkbookTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # 验证生成器的空白模板，而不是要求用户已经填写的工作簿保持为空。
        cls.temp_dir = tempfile.TemporaryDirectory(prefix="31days-t6-template-test-")
        cls.fixture = Path(cls.temp_dir.name) / "T6.xlsx"
        env = os.environ.copy()
        env["T6_OUTPUT_PATH"] = str(cls.fixture)
        env.pop("T6_PREVIEW_DIR", None)
        node = Path(os.environ["DAYS31_NODE"]) if os.environ.get("DAYS31_NODE") else Path(os.environ.get("USERPROFILE", "C:/Users/Administrator")) / ".cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe"
        builder = FILE.parents[1] / "scripts" / "build_t6.mjs"
        subprocess.run([str(node), str(builder)], env=env, check=True, capture_output=True, text=True, encoding="utf-8")
        cls.book = openpyxl.load_workbook(cls.fixture, data_only=False)

    @classmethod
    def tearDownClass(cls):
        cls.book.close()
        cls.temp_dir.cleanup()

    def test_all_sections_and_item_counts(self):
        self.assertEqual(self.book.sheetnames, ["填写说明", *SHEETS])
        self.assertEqual(sum(v[0] for v in SHEETS.values()), 118)
        for name, (count, cols, _) in SHEETS.items():
            sh = self.book[name]
            self.assertTrue(all(sh.cell(5, c).value for c in range(1, cols + 1)))
            self.assertTrue(all(sh.cell(r, 1).value for r in range(6, 6 + count)))
            self.assertEqual(sh.cell(6 + count, 1).value, None)
            self.assertIsNotNone(sh.freeze_panes)
            self.assertFalse(sh.sheet_view.showGridLines)

    def test_user_decisions_are_left_blank(self):
        for name, (count, _, inputs) in SHEETS.items():
            for row in range(6, 6 + count):
                for col in inputs:
                    if name == "T6-B1 玩家动画" and row == 12:
                        continue
                    with self.subTest(sheet=name, row=row, col=col):
                        self.assertIsNone(self.book[name].cell(row, col).value)

    def test_fixed_requirements_and_excluded_wall_actions(self):
        sh = self.book["T6-A 实体资源"]
        source = {sh.cell(r, 2).value: sh.cell(r, 3).value for r in range(6, 22)}
        self.assertEqual(source["检查点"], "8个逻辑节点")
        self.assertEqual(source["Boss及剧情奖励"], "无随机战利品系统")
        self.assertEqual(source["镰刀与锤的抗争者（10）"], "1名，参与实际战斗")
        self.assertIn("渴望俯视", source)
        self.assertIn("寄生同伴者", source)
        sh = self.book["T6-B1 玩家动画"]
        self.assertEqual([sh.cell(12, c).value for c in range(1, 5)], ["墙体互动", "V0.1不制作", 0, "已排除"])
        self.assertEqual(sh["B21"].value, "持续2.8秒的恢复动作")

    def test_acceptance_is_pending(self):
        sh = self.book["T6-F 最终验收"]
        for row in range(6, 20):
            self.assertEqual(sh.cell(row, 3).value, "待验收")
            self.assertIsNone(sh.cell(row, 4).value)
        self.assertEqual(sh["B12"].value, "27个关键Node有对应资源支持")

    def test_dropdowns_cover_all_requested_grade_columns(self):
        for name, col in (("T6-A 实体资源", "D"), ("T6-C 地图环境", "C"),
                          ("T6-D1 视觉特效", "C"), ("T6-D2 音效音乐", "C"), ("T6-D3 剧情演出", "D")):
            sh = self.book[name]
            rules = [d for d in sh.data_validations.dataValidation if d.type == "list" and "A,B,C" in str(d.formula1)]
            self.assertEqual(len(rules), 1)
            self.assertIn(f"{col}6", rules[0].sqref)
            self.assertIn(f"{col}{5 + SHEETS[name][0]}", rules[0].sqref)
        sh = self.book["T6-D3 剧情演出"]
        self.assertTrue(any("实时演出" in str(d.formula1) and "C6" in d.sqref for d in sh.data_validations.dataValidation))

    def test_instruction_scope_and_grade_definitions(self):
        sh = self.book["填写说明"]
        text = "\n".join(str(c.value) for row in sh for c in row if c.value is not None)
        for phrase in ("待制作测试确认", "不在本阶段重新设计", "技术方案留给T8", "T7 UI与存档", "共同验收"):
            self.assertIn(phrase, text)
        sh = self.book["T6-E 制作原则"]
        self.assertEqual([sh.cell(r, 1).value for r in range(21, 24)], ["A：独立制作", "B：复用制作", "C：临时占位"])
        for sh in self.book:
            for row in sh:
                for cell in row:
                    self.assertNotEqual(cell.data_type, "e", (sh.title, cell.coordinate))


if __name__ == "__main__":
    unittest.main()
