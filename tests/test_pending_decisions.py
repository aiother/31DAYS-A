"""Structure guards for the pending-decisions register. Run: python -X utf8 -m unittest discover -s tests -v"""
from pathlib import Path
import re
import unittest

WORDS = Path(__file__).resolve().parents[1] / "Words"
REGISTER = WORDS / "待决事项总表.md"
DOCS = {"T0": "T0_", "T1": "T1_", "T2": "T2_", "T3": "T3_", "T4": "T4_", "T5": "T5_",
        "T5.1": "T5.1_", "T5.2": "T5.2_", "T5.3": "T5.3_", "T5.4": "T5.4_"}
SECTIONS = {"A": "A 待用户裁决", "B": "B 已由后续修订解决", "C": "C 留待灰盒或实现确定"}


def table_rows(section):
    return [[cell.strip() for cell in line.split("|")[1:-1]]
            for line in section.splitlines()
            if line.startswith("|") and not line.startswith("| ---") and not line.startswith("| 编号")]


class PendingDecisionsTests(unittest.TestCase):
    def setUp(self):
        self.content = REGISTER.read_text(encoding="utf-8")
        parts = re.split(r"^## \d+\. ", self.content, flags=re.M)
        self.sections = {part.splitlines()[0]: part for part in parts[1:]}

    def section(self, title):
        matches = [body for name, body in self.sections.items() if name.startswith(title)]
        self.assertEqual(len(matches), 1, title)
        return matches[0]

    def test_document_frame(self):
        self.assertTrue(self.content.startswith("# 《末日前31天》"))
        self.assertIn("整理日期：2026-10-19", self.content)
        headings = re.findall(r"^## (\d+)\.", self.content, re.M)
        self.assertEqual(list(map(int, headings)), list(range(1, len(headings) + 1)))
        for title in (*SECTIONS.values(), "裁决记录"):
            self.section(title)
        width = None
        for line in self.content.splitlines():
            if line.startswith("|"):
                current = len(line.split("|")) - 2
                width = current if width is None else width
                self.assertEqual(current, width, line)
            else:
                width = None

    def test_ids_are_well_formed_unique_and_in_their_section(self):
        seen = set()
        for prefix, title in SECTIONS.items():
            rows = table_rows(self.section(title))
            self.assertTrue(rows, title)
            for row in rows:
                with self.subTest(row=row[0]):
                    self.assertRegex(row[0], rf"^{prefix}-\d{{3}}$")
                    self.assertNotIn(row[0], seen)
                    seen.add(row[0])
                    self.assertTrue(all(row), row)

    def test_every_source_names_an_existing_planning_document(self):
        files = [path.name for path in WORDS.glob("*.md")]
        for title in SECTIONS.values():
            for row in table_rows(self.section(title)):
                with self.subTest(row=row[0]):
                    refs = set(re.findall(r"T(?:5\.[1-4]|[0-5])(?![\d.])", row[2]))
                    self.assertTrue(refs, row[2])
                    for ref in refs:
                        self.assertTrue(any(name.startswith(DOCS[ref]) for name in files), ref)

    def test_a_status_and_decision_log_agree(self):
        decided = set()
        for row in table_rows(self.section(SECTIONS["A"])):
            self.assertIn(row[-1], ("待裁决", "已裁决"), row[0])
            if row[-1] == "已裁决":
                decided.add(row[0])
        logged = {row[0] for row in table_rows(self.section("裁决记录")) if row[0] != "—"}
        self.assertEqual(logged, decided)
        self.assertNotRegex(self.section(SECTIONS["A"]), "推荐|建议")

    def test_b_rows_cite_a_dated_confirmed_revision(self):
        for row in table_rows(self.section(SECTIONS["B"])):
            with self.subTest(row=row[0]):
                self.assertRegex(row[4], r"2026-10-\d{2}")

    def b_row(self, item_id):
        rows = [row for row in table_rows(self.section(SECTIONS["B"])) if row[0] == item_id]
        self.assertEqual(len(rows), 1, item_id)
        return rows[0]

    def test_rescue_expiry_keeps_the_legacy_slot_exception(self):
        row = self.b_row("B-005")
        conclusion, source = row[3], row[4]
        for rule in ("尚未见过", "旧存档", "已见过", "未主动放弃", "永久保留一次救助机会"):
            self.assertIn(rule, conclusion)
        self.assertIn("旧槽兼容", source)

    def test_trench_forward_path_requires_breaking_the_rubble(self):
        conclusion = self.b_row("B-016")[3]
        trench = conclusion.split("NSZC_10002_2")[1].split("；")[0]
        for rule in ("清敌保存后开返回", "清敌与挑战均保存后", "攻击打碎碎石堆", "保存成功", "永久开前路"):
            self.assertIn(rule, trench)
        self.assertLess(trench.index("清敌与挑战均保存后"), trench.index("攻击打碎碎石堆"))
        self.assertLess(trench.index("攻击打碎碎石堆"), trench.index("永久开前路"))

    def test_decisions_of_2026_10_19_are_logged(self):
        statuses = {row[0]: row[-1] for row in table_rows(self.section(SECTIONS["A"]))}
        self.assertEqual(set(statuses.values()), {"已裁决"})
        log = {row[0]: row for row in table_rows(self.section("裁决记录"))}
        self.assertEqual(set(log), set(statuses))
        for item_id, rules in {"A-002": ("50%", "10-15秒", "1-2个", "3只", "+2", "不含堑壕"),
                               "A-003": ("友军击杀",), "A-008": ("HD_10002_3", "珍珠"),
                               "A-009": ("按天划分",), "A-010": ("F11", "方向键")}.items():
            for rule in rules:
                with self.subTest(item=item_id, rule=rule):
                    self.assertIn(rule, log[item_id][2])
        for row in log.values():
            self.assertEqual(row[1], "2026-10-19")

    def test_known_open_items_are_collected(self):
        for keyword in ("货币", "剧情奖励", "重复帮助", "残存可能性实体"):
            with self.subTest(keyword=keyword):
                self.assertIn(keyword, self.content)
        a_section = self.section(SECTIONS["A"])
        for keyword in ("货币", "残存可能性实体"):
            self.assertIn(keyword, a_section)


if __name__ == "__main__":
    unittest.main()
