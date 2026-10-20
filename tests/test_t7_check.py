"""Completeness guards for the T7 vs current-spec check table. Run: python -X utf8 -m unittest discover -s tests -v"""
from pathlib import Path
import re
import unittest

import openpyxl

WORDS = Path(__file__).resolve().parents[1] / "Words"
CHECK = WORDS / "T7核对表.md"
WORKBOOK = WORDS / "T7_UI_UX与存档规格填写模板.xlsx"
REGISTER = WORDS / "待决事项总表.md"
CATEGORIES = ("一致", "冲突", "T7 独有", "T7 未覆盖")
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
            if row[2] == "冲突":
                ids = re.findall(r"A-\d{3}", row[4])
                self.assertTrue(ids, row[:2])
                conflict_ids.update(ids)
        register = REGISTER.read_text(encoding="utf-8")
        listed = set(re.findall(r"^\| (A-0(?:1[1-9]|20)) \|", register, re.M))
        self.assertEqual(conflict_ids, listed)

    def test_does_not_decide_for_the_user(self):
        self.assertNotRegex(self.text, "推荐")


if __name__ == "__main__":
    unittest.main()
