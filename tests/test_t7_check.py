"""Completeness guards for the T7 vs current-spec check table. Run: python -X utf8 -m unittest discover -s tests -v"""
from pathlib import Path
import re
import unittest

import openpyxl

WORDS = Path(__file__).resolve().parents[1] / "Words"
CHECK = WORDS / "T7核对表.md"
WORKBOOK = WORDS / "T7_UI_UX与存档规格填写模板.xlsx"
REGISTER = WORDS / "待决事项总表.md"
CATEGORIES = ("一致", "冲突", "待澄清", "T7 独有", "T7 未覆盖")
OPEN = ("冲突", "待澄清")
SHEETS = ("T7-A", "T7-B", "T7-C", "T7-D", "T7-E1", "T7-E2", "T7-E3", "T7-F")


def check_rows(text):
    return [[cell.strip() for cell in line.split("|")[1:-1]] for line in text.splitlines()
            if re.match(r"^\| T7-(?:A|B|C|D|E1|E2|E3|F) \|", line)]


class T7CheckTests(unittest.TestCase):
    def setUp(self):
        self.text = CHECK.read_text(encoding="utf-8")
        self.rows = check_rows(self.text)

    def test_frame_and_categories(self):
        self.assertTrue(self.text.startswith("# 《末日前31天》"))
        self.assertIn("整理日期：2026-10-19", self.text)
        headings = re.findall(r"^## (\d+)\.", self.text, re.M)
        self.assertEqual(list(map(int, headings)), list(range(1, len(headings) + 1)))
        self.assertTrue(self.rows)
        for row in self.rows:
            with self.subTest(row=row[:2]):
                self.assertEqual(len(row), 5)
                self.assertIn(row[2], CATEGORIES)
                self.assertTrue(all(row), row)

    def test_every_filled_t7_row_is_checked(self):
        # Each answered workbook row (sheets T7-A..T7-F) must appear by sheet and item name.
        book = openpyxl.load_workbook(WORKBOOK, data_only=True)
        checked = {(row[0], row[1]) for row in self.rows}
        expected = set()
        for sheet in book.worksheets:
            code = sheet.title.split(" ")[0]
            if code not in SHEETS:
                continue
            for values in sheet.iter_rows(min_row=6, values_only=True):
                cells = [value for value in values if value not in (None, "")]
                if code == "T7-E3":
                    continue  # the death/load flow is checked as one row below
                if len(cells) >= 3:
                    expected.add((code, str(cells[0]) if code not in ("T7-B",) else f"{cells[0]}：{cells[1]}"))
        expected.add(("T7-E3", "正常退出与死亡复活的区别"))
        self.assertEqual(expected - checked, set())

    def test_conflicts_map_one_to_one_to_open_register_items(self):
        conflict_ids = set()
        for row in self.rows:
            if row[2] in OPEN:
                ids = re.findall(r"A-\d{3}", row[4])
                self.assertTrue(ids, row[:2])
                conflict_ids.update(ids)
        register = REGISTER.read_text(encoding="utf-8")
        listed = set(re.findall(r"^\| (A-0(?:1[1-9]|20)) \|", register, re.M))
        self.assertEqual(conflict_ids, listed)

    def test_does_not_decide_for_the_user(self):
        self.assertNotRegex(self.text, "推荐")

    def test_derived_ui_ideas_are_not_presented_as_spec_requirements(self):
        # R1: G-01/G-05/G-06 have no explicit spec wording; they must sit with the optional suggestions.
        required = self.text.split("### 3.1")[1].split("### 3.2")[0]
        optional = self.text.split("### 3.2")[1].split("## 4.")[0]
        for item in ("G-01", "G-05", "G-06"):
            self.assertNotIn(f"| {item} |", required)
            self.assertIn(f"| {item} |", optional)
        for item in ("G-02", "G-03", "G-04", "G-07", "G-08"):
            self.assertIn(f"| {item} |", required)
        self.assertIn("待用户选择", optional)

    def test_ambiguous_rows_are_marked_for_clarification(self):
        # R2: omissions are not exclusions; these rows need clarification, not a forced either-or.
        by_key = {(row[0], row[1]): row for row in self.rows}
        for key in (("T7-A", "设置界面"), ("T7-D", "设置"), ("T7-A", "场景交互提示"),
                    ("T7-C", "NPC互动"), ("T7-C", "救助选择")):
            with self.subTest(row=key):
                self.assertEqual(by_key[key][2], "待澄清")
        self.assertIn("仅文案相容", by_key[("T7-C", "放弃确认")][4])
        countdown = by_key[("T7-B", "时间：最终战倒计时")][4]
        for branch in ("大于15分钟", "小于等于15分钟", "15分钟倒计时"):
            self.assertIn(branch, countdown)


if __name__ == "__main__":
    unittest.main()
