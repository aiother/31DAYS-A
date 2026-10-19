"""Check handoff entry points, project references and read-only task boundaries."""
from pathlib import Path
import ast
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]
COLLAB = ROOT / "codexandclaude"


class CollaborationTests(unittest.TestCase):
    def test_completed_pilot_entrypoint_reaches_each_handoff_stage(self):
        readme = (COLLAB / "README.md").read_text(encoding="utf-8")
        links = set(re.findall(r"\]\(([^)]+)\)", readme))
        required = {"hud_pilot_delivery.md", "hud_pilot_review.md",
                    "hud_acceptance.md", "controller_confirm_fix.md", "integration.md"}
        self.assertTrue(required.issubset(links), required - links)
        for stage in required:
            self.assertTrue((COLLAB / stage).is_file(), stage)

    def test_hud_pilot_scope_matches_real_inputs_and_future_test_paths(self):
        task = (COLLAB / "hud_pilot.md").read_text(encoding="utf-8")
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
        task = (COLLAB / "hud_pilot.md").read_text(encoding="utf-8")
        for boundary in ("claude/hud-layout-pilot", "先复现，后修复", "基线应因重叠而失败",
                         "若未复现", "不复制、不提交、不覆盖", "两处套件数量",
                         "临时路径", "人工验收未完成时不能声称可最终合并",
                         "不要自行合并 master", "交付后停止"):
            self.assertIn(boundary, task)
        readme = (COLLAB / "README.md").read_text(encoding="utf-8")
        self.assertIn("codex/hud-layout-review", readme)
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
        task = (COLLAB / "hud_pilot.md").read_text(encoding="utf-8")
        self.assertLess(task.index(" -X utf8 scripts/verify_game.py"),
                        task.index(" -X utf8 -m unittest discover -s tests"))
        self.assertIn("不得复制主目录旧报告或创建占位报告", task)

    def test_markdown_links_resolve_within_collaboration_directory(self):
        for document in COLLAB.glob("*.md"):
            for target in re.findall(r"\]\(([^)]+)\)", document.read_text(encoding="utf-8")):
                with self.subTest(document=document.name, target=target):
                    resolved = (document.parent / target).resolve()
                    self.assertTrue(resolved.is_relative_to(COLLAB.resolve()))
                    self.assertTrue(resolved.is_file())

    def test_handoff_points_to_real_project_inputs(self):
        for path in ("Agents.md", "Words", "game/README.md",
                     "game/docs/technical_baseline.md", "game/project.godot",
                     "game/tests", "tests", "scripts/verify_game.py"):
            with self.subTest(path=path):
                self.assertTrue((ROOT / path).exists(), path)
        review = (COLLAB / "first_review.md").read_text(encoding="utf-8")
        for path in ("game/project.godot", "scripts/verify_game.py",
                     "codexandclaude/collaboration.md"):
            self.assertIn(path, review)

    def test_first_review_has_no_write_or_runtime_authorization(self):
        review = (COLLAB / "first_review.md").read_text(encoding="utf-8")
        for boundary in ("只读，不修改任何文件", "不创建报告文件", "不创建 Git commit",
                         "不要执行 Godot 导入", "T0–T8 保持冻结", "未经用户确认不得实施",
                         "不要声称测试通过", "独立 worktree"):
            self.assertIn(boundary, review)

    def test_plan_v2_is_a_linked_proposal_with_core_safeguards(self):
        readme = (COLLAB / "README.md").read_text(encoding="utf-8")
        self.assertIn("](plan_v2.md)", readme)
        plan = (COLLAB / "plan_v2.md").read_text(encoding="utf-8")
        self.assertIn("状态：提案", plan)
        headings = re.findall(r"^## (\d+)\.", plan, re.M)
        self.assertEqual(list(map(int, headings)), list(range(1, len(headings) + 1)))
        for boundary in ("用户是唯一决策者", "仓库是唯一沟通渠道", "一人写，一人审",
                         "不超过两轮", "合并后", "全量", "主目录 `D:\\31days` 只属于用户",
                         "不用 `git add -A`", "不推送远程", "冻结范围",
                         "不让两个 Agent 自动互相调用", "规格优先于代码",
                         "git switch --detach", "git revert", "暂停后续所有集成",
                         "不记录自身所在提交的哈希", "立即停止并报告",
                         "不能审查自己的实现后直接集成", "不重新触发 G2",
                         "交付 SHA", "审查 SHA", "不合并可继续移动的分支名",
                         "res://../", "依赖 ENV-001", "以用户批准的本方案为准",
                         "审查通过后、合并前"):
            with self.subTest(boundary=boundary):
                self.assertIn(boundary, plan)
        for level in ("| S 小 |", "| M 中 |", "| L 大 |"):
            self.assertIn(level, plan)

    def test_protocol_preserves_pending_work_and_requires_tested_commits(self):
        protocol = (COLLAB / "collaboration.md").read_text(encoding="utf-8")
        for boundary in ("现有未提交变更必须保留", "未提交内容不会自动进入新 worktree",
                         "每次改动必须编写或更新相关测试", "创建对应 Git commit",
                         "只读审查没有文件改动", "当前仅人工触发", "不自动合并或推送"):
            self.assertIn(boundary, protocol)


if __name__ == "__main__":
    unittest.main()
