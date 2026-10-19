"""Check handoff entry points, project references and read-only task boundaries."""
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]
COLLAB = ROOT / "codexandclaude"


class CollaborationTests(unittest.TestCase):
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
