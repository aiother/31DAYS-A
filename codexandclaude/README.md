# Codex 与 Claude 协作入口

当前阶段：HUD 防重叠和 Xbox A 确认修复已获用户实机验收，并按用户明确指令合并 master。本次人工协作试点已完成；后续仍保持手动审批，不开展自动协作。

## 文件入口

- [协作方案 V2.2（试行中）](plan_v2.md)：用户已确认试行；试行期间与协作规范冲突时以本方案为准，复盘后正式并入。
- [协作规范](collaboration.md)：职责、冻结范围、Git 和验收规则。
- [Claude 首次只读任务](first_review.md)：用户手工交给 Claude Code 的完整任务。
- [HUD 试点任务](hud_pilot.md)：只在 Claude 独立工作区执行的首个实现任务。
- [Claude 试点交付](hud_pilot_delivery.md)：原始修复、复现前后测量及验证记录。
- [试点基线核对](hud_baseline.md)：用户未提交输入、工作区来源及本轮冻结边界。
- [Codex 独立审查](hud_pilot_review.md)：修复提交审查、独立复跑及真实截图复查，含剩余人工验收事项。
- [截图复查工具](tools/capture_hud_preview.gd)：使用独立测试存档捕获真实渲染结果，包含图像与清理验证。
- [人工验收步骤](hud_acceptance.md)：启动固定测试状态的交互预览，检查窗口、全屏和实际输入。
- [确认键诊断工具](tools/probe_controller_confirm.gd)：仅在测试进程预览 Xbox A 确认映射，不保存输入配置；诊断结果见独立审查记录。
- [Xbox 确认修复与复验](controller_confirm_fix.md)：用户另行批准的 A 键映射、回归证据和实机复验步骤。
- [最终验收与集成](integration.md)：用户验收和合并授权、集成验证以及原有未提交内容的保护结果。
- [规范验证](tests/test_collaboration.py)：验证入口、任务边界和项目引用。

Claude 可以在整个 `D:\31days` 项目按任务工作；`codexandclaude/` 只存放双方协作规范、交接、审查记录及相关验证，不是它的项目访问边界。游戏源码及游戏测试仍按原工程组织。

首次使用：在 Claude Code 中粘贴本目录 first_review.md 的任务，或要求其读取并执行该文件。审查结果先返回 Claude 会话，由用户转交 Codex；此轮不写审查报告文件。

本轮使用 worktrees/claude-hud（分支 claude/hud-layout-pilot）实现，用 worktrees/codex-review（分支 codex/hud-layout-review）审查与集成。二者以同一个任务准备提交创建，游戏代码源自 36d0582；当前共享工作目录已有用户未提交变更，不允许双方同时编辑主工作目录。工作区准备状态以实际 git worktree list 为准。

写入授权仅限 hud_pilot.md 中的文件清单；first_review.md 是保留的历史只读任务，不再作为本轮任务入口。Claude 完成后用户转交结果，再由 Codex 进行独立审查；未获得合并确认前不合并 master。

后续补充授权：用户实机发现手柄无法确认并明确同意修复，Codex 在审查分支单独调整 game/project.godot 的 ui_accept，添加菜单输入测试并同步测试登记/数量，详见 controller_confirm_fix.md。其他输入和玩法仍不在此次修改范围。

运行协作规范验证（在项目根目录）：

```powershell
python -X utf8 -m unittest discover -s codexandclaude/tests -v
```

文档验证通过不代表游戏运行、视觉效果、Claude 审查或双 Agent 集成已经验收。
