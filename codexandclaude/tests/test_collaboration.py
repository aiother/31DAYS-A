"""Check handoff entry points, project references and read-only task boundaries."""
from pathlib import Path
import ast
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]
COLLAB = ROOT / "codexandclaude"
ARCHIVE = COLLAB / "archive" / "HUD-001"
ARCHIVED = ("first_review.md", "hud_baseline.md", "hud_pilot.md", "hud_pilot_delivery.md",
            "hud_pilot_review.md", "hud_acceptance.md", "controller_confirm_fix.md",
            "integration.md", "tools/capture_hud_preview.gd", "tools/probe_controller_confirm.gd")


def links_in(document):
    return re.findall(r"\]\(([^)]+)\)", document.read_text(encoding="utf-8"))


class CollaborationTests(unittest.TestCase):
    def test_hud001_pilot_is_archived_with_an_index(self):
        index = links_in(ARCHIVE / "README.md")
        for name in ARCHIVED:
            with self.subTest(file=name):
                self.assertTrue((ARCHIVE / name).is_file())
                self.assertFalse((COLLAB / name).exists())
                self.assertIn(name, index)

    def test_readme_is_the_current_entry_point(self):
        links = set(links_in(COLLAB / "README.md"))
        required = {"plan_v2.md", "collaboration.md", "env.md", "BOARD.md",
                    "archive/HUD-001/README.md"}
        self.assertTrue(required.issubset(links), required - links)
        self.assertFalse([link for link in links if link.startswith(("hud_", "first_review"))])

    def test_board_lists_every_task_directory(self):
        board = (COLLAB / "BOARD.md").read_text(encoding="utf-8")
        rows = {line.split("|")[1].strip() for line in board.splitlines()
                if line.startswith("|") and not line.startswith("| ---")}
        self.assertIn("HUD-001", rows)
        for task in (COLLAB / "tasks").iterdir():
            with self.subTest(task=task.name):
                self.assertTrue((task / "task.md").is_file())
                self.assertIn(task.name, rows)

    def test_backlog_is_linked_and_well_formed(self):
        self.assertIn("BACKLOG.md", links_in(COLLAB / "README.md"))
        self.assertIn("BACKLOG.md", links_in(COLLAB / "BOARD.md"))
        rows = [[cell.strip() for cell in line.split("|")[1:-1]]
                for line in (COLLAB / "BACKLOG.md").read_text(encoding="utf-8").splitlines()
                if re.match(r"^\| BL-", line)]
        self.assertTrue(rows)
        ids = [row[0] for row in rows]
        self.assertEqual(len(ids), len(set(ids)))
        for row in rows:
            with self.subTest(item=row[0]):
                self.assertRegex(row[0], r"^BL-\d{3}$")
                self.assertEqual(len(row), 6)
                self.assertIn(row[1], ("P0", "P1", "P2", "P3"))
                self.assertTrue(all(row), row)
                self.assertRegex(row[5], r"^(待立项|进行中|观察中|已立项 \S+|已完成|已完成（\S+）|已取消)")

    def test_roadmap_covers_every_open_backlog_item(self):
        self.assertIn("ROADMAP.md", links_in(COLLAB / "README.md"))
        self.assertIn("ROADMAP.md", links_in(COLLAB / "BOARD.md"))
        roadmap = (COLLAB / "ROADMAP.md").read_text(encoding="utf-8")
        self.assertTrue(roadmap.startswith("# "))
        headings = re.findall(r"^## (\d+)\.", roadmap, re.M)
        self.assertEqual(list(map(int, headings)), list(range(1, len(headings) + 1)))
        backlog = {}
        for line in (COLLAB / "BACKLOG.md").read_text(encoding="utf-8").splitlines():
            if re.match(r"^\| BL-\d{3} \|", line):
                cells = [cell.strip() for cell in line.split("|")[1:-1]]
                backlog[cells[0]] = cells
        referenced = set(re.findall(r"BL-\d{3}", roadmap))
        self.assertEqual(referenced - set(backlog), set())
        # Only milestone/batch rows and the tooling line count as an assignment.
        units = {}
        for line in roadmap.splitlines():
            unit = re.match(r"^\| (M\d(?:-[a-z])?) \|", line)
            if unit:
                units[unit.group(1)] = set(re.findall(r"BL-\d{3}", line))
            elif line.startswith("并行的工具线"):
                units["工具线"] = set(re.findall(r"BL-\d{3}", line))
        assigned = set().union(*units.values())
        for item_id, cells in backlog.items():
            open_item = cells[5].startswith(("待立项", "已立项", "进行中"))
            if open_item and cells[1] in ("P1", "P2") and item_id != "BL-021":
                with self.subTest(item=item_id):
                    self.assertIn(item_id, assigned)
        self.assertIn(backlog["BL-021"][5], ("已立项 DOC-007", "已完成（DOC-007）"))
        for milestone in ("M1", "M2", "M3", "M4", "M5"):
            self.assertIn(milestone, units)
        # Spec-required UI needs (T7 checklist §3.1) trace to a backlog item and its batch.
        for need in ("G-02", "G-03", "G-04", "G-07", "G-08"):
            with self.subTest(need=need):
                rows = [line for line in roadmap.splitlines() if line.startswith(f"| {need} ")]
                self.assertEqual(len(rows), 1)
                cells = [cell.strip() for cell in rows[0].split("|")[1:-1]]
                items = re.findall(r"BL-\d{3}", cells[1])
                self.assertTrue(items)
                for item_id in items:
                    self.assertIn(need, backlog[item_id][2] + backlog[item_id][3])
                    self.assertIn(item_id, units[cells[2]])

    def test_roadmap_snapshot_mentions_existing_graybox_settings_and_audio(self):
        roadmap = (COLLAB / "ROADMAP.md").read_text(encoding="utf-8")
        life_ui = (ROOT / "game/ui/menus/life_ui.gd").read_text(encoding="utf-8")
        visual = (ROOT / "game/player/placeholder_visual.gd").read_text(encoding="utf-8")
        if "window_set_size" in life_ui:
            self.assertIn("窗口尺寸", roadmap)
        if "_hit_sound" in visual:
            self.assertIn("命中音", roadmap)
            self.assertIn("game/player/placeholder_visual.gd`（命中音", roadmap)

    def test_hud_pilot_scope_matches_real_inputs_and_future_test_paths(self):
        task = (ARCHIVE / "hud_pilot.md").read_text(encoding="utf-8")
        for path in ("game/ui/menus/life_ui.gd", "scripts/verify_game.py",
                     "tests/test_verification_runner.py"):
            with self.subTest(path=path):
                self.assertIn(path, task)
                self.assertTrue((ROOT / path).is_file())
        for path in ("game/tests/test_hud_layout.gd",
                     "codexandclaude/hud_pilot_delivery.md"):
            self.assertIn(path, task)
            self.assertTrue((ROOT / path).parent.is_dir())

    def test_hud_handoff_covers_reproduction_and_independent_review(self):
        task = (ARCHIVE / "hud_pilot.md").read_text(encoding="utf-8")
        for boundary in ("claude/hud-layout-pilot", "先复现，后修复", "基线应因重叠而失败",
                         "若未复现", "不复制、不提交、不覆盖", "两处套件数量",
                         "临时路径", "人工验收未完成时不能声称可最终合并",
                         "不要自行合并 master", "交付后停止"):
            self.assertIn(boundary, task)
        index = (ARCHIVE / "README.md").read_text(encoding="utf-8")
        self.assertIn("codex/hud-layout-review", index)
        ignores = (COLLAB / ".gitignore").read_text(encoding="utf-8").splitlines()
        self.assertIn("/worktrees/", ignores)
        self.assertIn("/runs/", ignores)

    def test_referenced_test_count_assertions_remain_present(self):
        # The handoff authorizes a count update, not removal of manifest checks.
        tree = ast.parse((ROOT / "tests/test_verification_runner.py").read_text(encoding="utf-8"))
        assertions = [node for node in ast.walk(tree)
                      if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute)
                      and node.func.attr == "assertEqual" and len(node.args) == 2
                      and isinstance(node.args[1], ast.Constant)
                      and isinstance(node.args[1].value, int)
                      and isinstance(node.args[0], ast.Call)
                      and isinstance(node.args[0].func, ast.Name)
                      and node.args[0].func.id == "len"
                      and "verifier.TESTS" in ast.unparse(node.args[0])]
        self.assertEqual(len(assertions), 2)

    def test_clean_worktree_validation_generates_reports_before_resource_checks(self):
        task = (ARCHIVE / "hud_pilot.md").read_text(encoding="utf-8")
        self.assertLess(task.index(" -X utf8 scripts/verify_game.py"),
                        task.index(" -X utf8 -m unittest discover -s tests"))
        self.assertIn("不得复制主目录旧报告或创建占位报告", task)

    def test_markdown_links_resolve_within_collaboration_directory(self):
        documents = [document for document in COLLAB.rglob("*.md")
                     if not {"worktrees", "runs"} & set(document.relative_to(COLLAB).parts)]
        self.assertIn(ARCHIVE / "README.md", documents)
        for document in documents:
            for target in links_in(document):
                with self.subTest(document=str(document.relative_to(COLLAB)), target=target):
                    resolved = (document.parent / target).resolve()
                    self.assertTrue(resolved.is_relative_to(COLLAB.resolve()))
                    self.assertTrue(resolved.is_file())

    def test_handoff_points_to_real_project_inputs(self):
        for path in ("Agents.md", "Words", "game/README.md",
                     "game/docs/technical_baseline.md", "game/project.godot",
                     "game/tests", "tests", "scripts/verify_game.py"):
            with self.subTest(path=path):
                self.assertTrue((ROOT / path).exists(), path)
        review = (ARCHIVE / "first_review.md").read_text(encoding="utf-8")
        for path in ("game/project.godot", "scripts/verify_game.py",
                     "codexandclaude/collaboration.md"):
            self.assertIn(path, review)

    def test_first_review_has_no_write_or_runtime_authorization(self):
        review = (ARCHIVE / "first_review.md").read_text(encoding="utf-8")
        for boundary in ("只读，不修改任何文件", "不创建报告文件", "不创建 Git commit",
                         "不要执行 Godot 导入", "T0–T8 保持冻结", "未经用户确认不得实施",
                         "不要声称测试通过", "独立 worktree"):
            self.assertIn(boundary, review)

    def test_plan_v2_is_kept_as_merged_history(self):
        plan = (COLLAB / "plan_v2.md").read_text(encoding="utf-8")
        self.assertIn("状态：已并入", plan)
        self.assertIn("](collaboration.md)", plan)
        self.assertNotIn("V2.2 试行中", plan)
        readme = (COLLAB / "README.md").read_text(encoding="utf-8")
        self.assertIn("协作规范 V2.3](collaboration.md)", readme)
        self.assertNotIn("试行中", readme)

    def test_collaboration_v23_keeps_v22_safeguards_and_adds_retrospective_rules(self):
        protocol = (COLLAB / "collaboration.md").read_text(encoding="utf-8")
        self.assertIn("状态：现行规范", protocol)
        headings = re.findall(r"^## (\d+)\.", protocol, re.M)
        self.assertEqual(list(map(int, headings)), list(range(1, len(headings) + 1)))
        carried = ("用户是唯一决策者", "仓库是唯一沟通渠道", "一人写，一人审", "不超过两轮",
                   "规格优先于代码", "冻结范围", "git switch --detach", "git revert",
                   "暂停后续所有集成", "不记录自身所在提交的哈希", "立即停止并报告",
                   "不能审查自己的实现后直接集成", "不重新触发 G2", "交付 SHA", "审查 SHA",
                   "不合并可移动的分支名", "不用 `git add -A`", "不推送远程",
                   "审查通过后、合并前", "主目录 `D:\\31days` 属于用户")
        added = ("方案探讨", "探索型任务", "变异检查", "优化建议", "批量合入",
                 "验收入口在任务卡阶段就要规划", "git commit -F",
                 "汇总所依据的 master SHA", "集成者可以在 master 上直接提交")
        for rule in carried + added:
            with self.subTest(rule=rule):
                self.assertIn(rule, protocol)
        for level in ("| S 小 |", "| M 中 |", "| L 大 |"):
            self.assertIn(level, protocol)
        env = (COLLAB / "env.md").read_text(encoding="utf-8")
        for detail in ("safe.directory", "git commit -F", "CRLF", ".svg.import"):
            self.assertIn(detail, env)

    def section(self, text, number):
        return re.split(r"^## \d+\. ", text, flags=re.M)[number]

    def test_proposals_live_outside_task_directories(self):
        # R1: a proposal must not create tasks/<ID>/ before its task card is registered.
        protocol = (COLLAB / "collaboration.md").read_text(encoding="utf-8")
        discussion = protocol.split("### 3.2")[1].split("### 3.3")[0]
        self.assertIn("proposals/<ID>.md", discussion)
        self.assertNotIn("在 `tasks/<ID>/proposal.md` 写出", protocol)
        self.assertIn("随任务卡一并移入", discussion)
        for proposal in (COLLAB / "proposals").glob("*.md") if (COLLAB / "proposals").is_dir() else []:
            with self.subTest(proposal=proposal.name):
                self.assertRegex(proposal.stem, r"^[A-Z]+-\d{3}$")
        exploration = protocol.split("### 3.3")[1].split("## 4.")[0]
        for rule in ("game/prototypes/<ID>/", "codexandclaude/prototypes/<ID>/", "最小测试"):
            self.assertIn(rule, exploration)

    def test_required_evidence_and_failure_attribution_are_kept(self):
        # R2: V2.2 section 7 evidence obligations stay in the current rulebook.
        gates = self.section((COLLAB / "collaboration.md").read_text(encoding="utf-8"), 7)
        for field in ("被测 SHA", "工作区是否有未提交改动", "工具版本", "实际执行的命令",
                      "套件完整性", "计数", "原有失败与新引入失败分开报告", "必填"):
            with self.subTest(field=field):
                self.assertIn(field, gates)

    def test_document_change_logs_and_decision_records_keep_their_fields(self):
        # R3: V2.2 section 9 traceability obligations stay in the current rulebook.
        docs = self.section((COLLAB / "collaboration.md").read_text(encoding="utf-8"), 10)
        for rule in ("每份规格文档", "日期、改了什么、来源", "其他文档只放链接",
                     "日期、结论、来源链接", "不直接删除"):
            with self.subTest(rule=rule):
                self.assertIn(rule, docs)
        self.assertNotIn("已改写为现行版的文档在文末保留变更记录表", docs)

    def test_protocol_preserves_pending_work_and_requires_tested_commits(self):
        protocol = (COLLAB / "collaboration.md").read_text(encoding="utf-8")
        for boundary in ("现有未提交变更必须保留", "未提交内容不会自动进入新 worktree",
                         "每次改动必须编写或更新相关测试", "创建对应 Git commit",
                         "只读审查没有文件改动", "当前仅人工触发", "不自动合并或推送"):
            self.assertIn(boundary, protocol)


if __name__ == "__main__":
    unittest.main()
