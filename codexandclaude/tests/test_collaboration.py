"""Check handoff entry points, project references and read-only task boundaries."""
from pathlib import Path
import ast
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]
COLLAB = ROOT / "codexandclaude"


class CollaborationTests(unittest.TestCase):
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

    def test_protocol_preserves_pending_work_and_requires_tested_commits(self):
        protocol = (COLLAB / "collaboration.md").read_text(encoding="utf-8")
        for boundary in ("现有未提交变更必须保留", "未提交内容不会自动进入新 worktree",
                         "每次改动必须编写或更新相关测试", "创建对应 Git commit",
                         "只读审查没有文件改动", "当前仅人工触发", "不自动合并或推送"):
            self.assertIn(boundary, protocol)


if __name__ == "__main__":
    unittest.main()
