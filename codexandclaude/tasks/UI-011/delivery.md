# UI-011 交付记录

- 实现：Claude｜审查：Codex｜分支 `claude/UI-011`（worktree `codexandclaude/worktrees/claude-ui011`）｜基线 master@cc42d35。
- **实现 SHA**：`5332d03`（提交链 `5dfe21e` → `f78b48f` → `1fc5dcb` → `8b7b194` → `5332d03`）。

## 过程

1. `5dfe21e`：按用户第一句要求把时间轴挪到顶部。完整检查**未通过**：右上角的日期标签与“保存成功”提示重叠（`test_pause_menu.gd` 两项失败）。用户随后看过截图认为不好看，此版被取代。
2. `f78b48f`：按用户第二句要求隐藏时间轴、换日改为中上部动画；撤回顶部版的布局改动。
3. `1fc5dcb`：按用户第三句要求放大一倍，全部尺寸由 `DAY_SCALE` 控制；最终战期间不播放。
4. `8b7b194`：只整理任务卡依据顺序。完整检查**未通过**：`test_formal_hud.gd` 最终战用例与 UI-002 验收适配器自检仍直接读 `drawn["horizon"]`，触发脚本错误。此前专项只看了标记行未看总结论，漏掉了它。
5. `5332d03`：两处改为断言时间轴记录不存在；完整检查通过。

## 改动

| 文件 | 内容 |
| --- | --- |
| `game/ui/hud/formal_hud.gd` | `SHOW_HORIZON = false`（时间轴代码保留）；`_draw_banner` 改为换日动画：三层半透明半个太阳升起、三道细弧展开（外圈带刻度）、竖线升起到小菱形、“第 N 日”（`day_name()` 中文数字，超过十用阿拉伯数字）与“末日前 N 天”淡入，最后 0.9 秒淡出；`DAY_SCALE = 2.0`，区域 y 6～356；最终战期间不播放。 |
| `game/tests/test_formal_hud.gd` | 时间轴隐藏、时刻照常推进、动画三阶段、位置在保存错误行之上、两倍尺寸、中文数字、最终战期间不播放。 |
| `game/tests/test_day_clock_session.gd`、`game/tests/acceptance/ui002_hud.gd` | 不再读时间轴记录，改为断言其不存在且日期正确。 |
| `Words/T4_3天倒计时系统.md` | 第 2 节 HUD 时间显示改为隐藏时间轴、换日动画；变更记录附用户原话。 |
| `Words/待决事项总表.md` | A-015 裁决记录补 2026-10-31 修订说明。 |
| `game/docs/formal_hud_implementation.md` | 新增时间轴隐藏与换日动画的实施说明。 |
| `codexandclaude/references/日期切换.mp4` | 用户提供的参考（LFS）。 |
| `codexandclaude/tasks/UI-011/` | 任务卡、截图脚本 `capture_day_change.gd`、6 张动画截图。 |
| `codexandclaude/BOARD.md` | 登记 UI-011。 |

其余避让 HUD 的界面（交互提示、任务条、对话、敌人介绍卡、中心提示、战场横幅）都读取 HUD 发布的矩形，没有改代码；`horizon` 不再发布后它们的避让表自然缺席。

## 检查证据

- **完整检查**：`python codexandclaude/tools/run_checks.py full --jobs 4`，被测 SHA `5332d03`，工作区干净，`content_stable=true`，**通过**。G2 引擎登记 100 项（98 套件 + 导入 + 主场景，含 `FORMAL_HUD_TESTS checks=55`、`HUD_LAYOUT_TESTS checks=247`、`DAY_CLOCK_SESSION_TESTS checks=43`、`PAUSE_MENU_TESTS checks=53`），无脚本错误（此处原写 102 项，是笔误，审查 N2 已指出）；G3 `tests/` 188 + `codexandclaude/tests/` 83 项。摘要 `codexandclaude/runs/20261031T093518.139955Z/summary.json`（运行目录不入库）。
- **实际渲染**：`Godot --path game --resolution 1920x1080 --script res://../codexandclaude/tasks/UI-011/capture_day_change.gd`，`captures/` 下 0.2 / 0.45 / 0.7 / 1.0 / 1.6 / 3.4 秒六张截图；用户已看过两倍版并认可（“可以”）。

## 交给审查者（Codex）

- 重点：动画区域与各 HUD 区域、提示、错误行在各分辨率下的避让；“最终战期间不播放”的依据（最终战只在第 3 日，换日最多到第 3 日）是否成立；时间轴隐藏后是否还有代码读取 `horizon` 记录。
- 已知限制：`DAY_SCALE` 是常量，调大小要改代码；动画沿用现有 HUD 画法，UI 整体待美术重设计（BL-130）。

## 用户验收

用户已在截图上认可两倍大小的换日动画；实机观感可在下次实机验收时看（把当日剩余时间调短后等待换日）。
