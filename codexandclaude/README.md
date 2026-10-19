# Codex 与 Claude 协作入口

当前阶段：REVIEW-001 只读审查已由用户转交；用户已同意 HUD 防重叠试点。Claude Code 保持手动审批，仅授权任务清单中的局部布局修复，不开展自动协作。

## 文件入口

- [协作规范](collaboration.md)：职责、冻结范围、Git 和验收规则。
- [Claude 首次只读任务](first_review.md)：用户手工交给 Claude Code 的完整任务。
- [HUD 试点任务](hud_pilot.md)：只在 Claude 独立工作区执行的首个实现任务。
- [试点基线核对](hud_baseline.md)：用户未提交输入、工作区来源及本轮冻结边界。
- [规范验证](tests/test_collaboration.py)：验证入口、任务边界和项目引用。

Claude 可以在整个 `D:\31days` 项目按任务工作；`codexandclaude/` 只存放双方协作规范、交接、审查记录及相关验证，不是它的项目访问边界。游戏源码及游戏测试仍按原工程组织。

首次使用：在 Claude Code 中粘贴本目录 first_review.md 的任务，或要求其读取并执行该文件。审查结果先返回 Claude 会话，由用户转交 Codex；此轮不写审查报告文件。

本轮使用 worktrees/claude-hud（分支 claude/hud-layout-pilot）实现，用 worktrees/codex-review（分支 codex/hud-layout-review）审查与集成。二者以同一个任务准备提交创建，游戏代码源自 36d0582；当前共享工作目录已有用户未提交变更，不允许双方同时编辑主工作目录。工作区准备状态以实际 git worktree list 为准。

写入授权仅限 hud_pilot.md 中的文件清单；first_review.md 是保留的历史只读任务，不再作为本轮任务入口。Claude 完成后用户转交结果，再由 Codex 进行独立审查；未获得合并确认前不合并 master。

运行协作规范验证（在项目根目录）：

```powershell
python -X utf8 -m unittest discover -s codexandclaude/tests -v
```

文档验证通过不代表游戏运行、视觉效果、Claude 审查或双 Agent 集成已经验收。
