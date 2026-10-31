# UI-011：时间轴隐藏与换日动画

状态：已交付，待 Codex 审查（2026-10-31 用户提出；实现 `5332d03`，见 [delivery.md](delivery.md)）｜级别：S｜实现：Claude｜审查：Codex
工作区：worktrees/claude-ui011｜基线：master@cc42d356d54b19c3ed7ef7d0b9bf2a0919f486d7｜依赖：无（与 SYS-013 的镜头改动无代码交集）

## 目标

游戏镜头改为 ×1.875、站立脚底在画面 88% 后，画在底边的时间轴挡住了玩家脚下的视野。第一版把它挪到顶部，用户看过后认为不好看，改为：**日常隐藏时间轴**；换日时在画面中上部播放**日期切换动画**，取代原来的换日纸签。

## 依据

- 用户 2026-10-31（SYS-013 实机验收时）：“时间轴有些碍事，会挡视野，考虑挪个位置，挪到顶上去吧？”
- 用户 2026-10-31 看过顶部版后：“不太好看，这个时间轴，先隐藏吧，改一下规则，切换到新的一天时，出现一个在屏幕中上部分的日期切换动画”，参考视频 `codexandclaude/references/日期切换.mp4`（约 5 秒：画面中上部半个琥珀色太阳淡入，外圈细弧与刻度展开，竖线穿过圆心，下方大字“DAY II”由淡到实）。
- 用户 2026-10-31 看过换日动画第一版后：“这个换日的需要再大100%，你看一下”。
- 规则来源：`Words/T4_3天倒计时系统.md` 第 2 节“HUD时间显示”、待决事项 A-015 裁决（EXP-001 方案四）。本任务修订这两处。
- 待办 BL-127 的 HUD 部分；UI 整体将由美术重新设计（BL-130），本任务是过渡调整，沿用现有 HUD 画法（DuskStyle / InkDraw），只借参考的结构与节奏，不照搬原作造型。

## 允许修改的文件

- `game/ui/hud/formal_hud.gd`（时间轴开关、换日动画）。
- `game/tests/test_formal_hud.gd`、`game/tests/test_day_clock_session.gd`、`game/tests/acceptance/ui002_hud.gd`（时间轴与换日相关断言）；`game/tests/test_day_change_dialogue.gd`（新增，换日后立即对话的回归，审查 R1）。
- `Words/T4_3天倒计时系统.md`（第 2 节与变更记录）、`Words/待决事项总表.md`（A-015 裁决记录的修订说明）、`game/docs/formal_hud_implementation.md`。
- `codexandclaude/references/日期切换.mp4`（用户提供的参考，LFS）。
- `codexandclaude/tasks/UI-011/`（截图脚本与截图）、`codexandclaude/BOARD.md`（登记本任务）。

## 完成标准

1. 日常不绘制地平线、时刻纸签与日期纸签，HUD 不再发布 `horizon` 区域；绘制代码保留，一个常量即可恢复。游戏内时刻照常推进。
2. 换日时画面中上部播放动画：半个太阳升起 → 细弧展开 → 竖线升起 → “第 N 日”（中文数字）与“末日前 N 天”淡入，约 4 秒（沿用 `announcement_seconds`）后淡出；读档、选槽不播放（沿用原换日纸签的触发规则）。
3. 动画按用户要求放大一倍（用户 2026-10-31：“这个换日的需要再大100%”），全部尺寸由一个缩放常量 `DAY_SCALE` 控制，方便再调。区域在保存错误行之上，与其他 HUD 区域、提示、对话、敌人介绍卡在各分辨率下都不重叠（`test_hud_layout.gd` 等）；最终战期间不播放（最终战只在第 3 日开始，换日最多到第 3 日，两者不会同时出现）；对话或开场演出期间延后、结束后从头完整播放，不遮挡对话（审查 R1）。
4. 其余避让 HUD 的界面沿用 HUD 发布的矩形，不需要改代码；对应测试全部通过。
5. G2、G3 通过；实际渲染截图确认。

## 检查

- G2：`python codexandclaude/tools/run_checks.py full --jobs 4`。
- 实际渲染：`Godot --path game --resolution 1920x1080 --script res://../codexandclaude/tasks/UI-011/capture_day_change.gd`，在 `captures/` 输出动画 6 个时刻的截图。

## 验收入口

- 与 SYS-013 一起实机看：底部是否清爽；换日动画的位置、节奏与观感（可用调试把当日剩余时间调短后等待换日）。

## 回滚方案

`git revert` 本任务提交；时间轴可单独把 `FormalHud.SHOW_HORIZON` 改回 `true`。

## 不在范围内

- “即将进入第 N 日”提示框（仍在右下角，只在每天最后几分钟出现）、徽章与其他 HUD 元素、暂停菜单时钟、HUD 风格（BL-130）。
