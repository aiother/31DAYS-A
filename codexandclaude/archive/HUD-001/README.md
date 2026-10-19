# HUD-001 试点归档

这是 Codex 与 Claude 第一次人工协作试点的历史记录（2026-10-19）。试点修复了灰盒 HUD 与存档错误提示的重叠，以及 Xbox A 键无法确认菜单的问题，并已合入 master。V2 协作方案就是在这次试点的基础上制定的。

本目录只供追溯，文件内容保持归档时的原样。其中的路径、命令和工作区（`worktrees/claude-hud`，分支 `claude/hud-layout-pilot`；`worktrees/codex-review`，分支 `codex/hud-layout-review`）反映的是试点当时的情况，不再作为现行流程或命令的依据。现行规则见上级目录的 README。

## 文件

| 文件 | 内容 |
| --- | --- |
| [first_review.md](first_review.md) | 试点前交给 Claude 的首次只读审查任务 |
| [hud_baseline.md](hud_baseline.md) | 试点基线核对：用户未提交的文件、工作区来源、冻结边界 |
| [hud_pilot.md](hud_pilot.md) | HUD-001 实现任务单：授权文件、先复现后修复、验证与交付要求 |
| [hud_pilot_delivery.md](hud_pilot_delivery.md) | Claude 的交付记录：复现前后测量与验证结果 |
| [hud_pilot_review.md](hud_pilot_review.md) | Codex 的独立审查：复跑、截图复查、手柄确认问题诊断 |
| [hud_acceptance.md](hud_acceptance.md) | 用户实机验收步骤 |
| [controller_confirm_fix.md](controller_confirm_fix.md) | Xbox A 确认键修复与复验 |
| [integration.md](integration.md) | 用户验收、合并授权与集成验证记录 |
| [tools/capture_hud_preview.gd](tools/capture_hud_preview.gd) | 截图复查与交互预览脚本（使用独立测试存档） |
| [tools/probe_controller_confirm.gd](tools/probe_controller_confirm.gd) | 手柄确认映射诊断脚本（不保存输入配置） |

以后的 UI 任务若要复用这两个脚本，应在任务卡中写明，把它们恢复到现行目录并按当时的工作区更新路径。
