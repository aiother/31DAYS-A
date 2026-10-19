"""验证T7新模板保留约束、留空决策字段，且不预先宣告验收完成。"""
from pathlib import Path
import os
import subprocess
import tempfile
import unittest
import openpyxl

FILE = Path(__file__).resolve().parents[1] / "Words" / "T7_UI_UX与存档规格填写模板.xlsx"
COUNTS = {
    "T7-A 界面导航": (11, 4), "T7-B HUD信息": (17, 5),
    "T7-C 对话交互反馈": (16, 4), "T7-D 暂停系统菜单": (9, 4),
    "T7-E1 存档操作": (9, 4), "T7-E2 数据状态": (16, 4),
    "T7-F 异常情况": (12, 3), "T7-G 最终验收": (11, 3),
}


class T7WorkbookTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # 模板回归只检查独立生成的模板，允许制作人在原表中填写决策。
        cls.temp_dir = tempfile.TemporaryDirectory(prefix="31days-t7-template-test-")
        cls.fixture = Path(cls.temp_dir.name) / "T7.xlsx"
        env = os.environ.copy()
        env["T7_OUTPUT_PATH"] = str(cls.fixture)
        env.pop("T7_PREVIEW_DIR", None)
        node = Path(os.environ["DAYS31_NODE"]) if os.environ.get("DAYS31_NODE") else Path(os.environ.get("USERPROFILE", "C:/Users/Administrator")) / ".cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node.exe"
        subprocess.run([str(node), str(FILE.parents[1] / "scripts" / "build_t7.mjs")],
                       env=env, check=True, capture_output=True, text=True, encoding="utf-8")
        cls.book = openpyxl.load_workbook(cls.fixture, data_only=False)

    @classmethod
    def tearDownClass(cls):
        cls.book.close()
        cls.temp_dir.cleanup()

    def test_all_sections_and_counts(self):
        self.assertEqual(self.book.sheetnames, ["填写说明与Todo", *list(COUNTS)[:6], "T7-E3 死亡加载流程", *list(COUNTS)[6:]])
        self.assertEqual(sum(v[0] for v in COUNTS.values()), 101)
        for name, (count, cols) in COUNTS.items():
            sh = self.book[name]
            self.assertTrue(all(sh.cell(5, c).value for c in range(1, cols + 1)))
            self.assertTrue(all(sh.cell(r, 1).value for r in range(6, 6 + count)))
            self.assertIsNone(sh.cell(6 + count, 1).value)
            self.assertIsNotNone(sh.freeze_panes)

    def test_decisions_remain_blank_and_acceptance_pending(self):
        for name, (count, col) in COUNTS.items():
            for row in range(6, count + 6):
                self.assertEqual(self.book[name].cell(row, col).value, "待验收" if name.startswith("T7-G") else None)
        sh = self.book["T7-G 最终验收"]
        self.assertTrue(any("待验收" in str(d.formula1) and "C16" in d.sqref for d in sh.data_validations.dataValidation))
        self.assertIsNone(self.book["T7-E3 死亡加载流程"]["B15"].value)

    def test_frozen_resource_rules_are_preserved(self):
        sh = self.book["T7-B HUD信息"]
        rules = {sh.cell(r, 2).value: sh.cell(r, 3).value for r in range(6, 23)}
        self.assertEqual(rules["当前生命值"], "初始上限5，受击扣除")
        self.assertEqual(rules["负数透支"], "最低可至-9")
        self.assertEqual(rules["恢复进度"], "长按2.8秒，完成后恢复生命")
        self.assertEqual(rules["连续闪避状态"], "最多三次，消耗递增")
        self.assertEqual(rules["Boss生命信息"], "T5已有两名Boss")
        self.assertIn("15分钟", rules["最终战倒计时"])

    def test_save_rules_and_edge_cases_are_present(self):
        sh = self.book["T7-E2 数据状态"]
        rules = {sh.cell(r, 1).value: sh.cell(r, 3).value for r in range(6, 22)}
        self.assertEqual(rules["当前日期"], "保留时间进度，不允许日期倒退")
        self.assertEqual(rules["7的注视"], "不得重复领取成长奖励")
        self.assertEqual(rules["普通敌人"], "不永久保存普通敌人死亡状态")
        self.assertEqual(rules["Boss击败"], "未击败Boss死亡后重置")
        for item in ("最终战胜利同时倒计时归零", "10登场后玩家死亡", "游戏退出时尚未到达下一个检查点"):
            self.assertIn(item, [self.book["T7-F 异常情况"].cell(r, 1).value for r in range(6, 18)])

    def test_death_flow_and_development_todo(self):
        sh = self.book["T7-E3 死亡加载流程"]
        self.assertEqual([sh.cell(r, 1).value for r in range(6, 13)], list(range(1, 8)))
        self.assertEqual(sh["B12"].value, "3秒复活无敌，恢复操作")
        self.assertEqual(sh["B11"].value, "重置临时敌人，保留永久事件")
        info = self.book["填写说明与Todo"]
        self.assertEqual(info["B25"].value, "完成")
        self.assertEqual(info["B26"].value, "正在进行")
        self.assertEqual(info["B27"].value, "尚未开始")

    def test_scope_instructions_and_no_formula_errors(self):
        sh = self.book["填写说明与Todo"]
        text = "\n".join(str(c.value) for row in sh for c in row if c.value is not None)
        for term in ("不增加背包成长", "复杂任务日志", "存档不等于死亡回档", "具体按键映射留给T8", "实时演出"):
            self.assertIn(term, text)
        for sh in self.book:
            self.assertFalse(sh.sheet_view.showGridLines)
            for row in sh:
                for cell in row:
                    self.assertNotEqual(cell.data_type, "e")


if __name__ == "__main__":
    unittest.main()
