# SYS-013：镜头后续（大型战斗拉远、实验场景镜头）

状态：待审查（2026-10-30 用户指示开工；基线 master@cc42d35；完整验证结果与交接见 delivery.md）｜级别：M｜实现：Codex｜审查：Claude
工作区：worktrees/codex｜基线：本任务卡合入后的 master 最新提交（实现者在交付记录中写明完整 SHA）｜依赖：无；与 ENV-008 并行

## 目标

镜头改为 ×1.875 后，补上 T1 允许的大型战斗拉远，统一调试实验场景的镜头，并核对竖向 Room 与 Boss 出招预兆在新视野内是否可见。同时补审 2026-10-30 未经审查的镜头提交。

## 依据

- `Words/T1_核心玩法与玩家操作.md` 第 6 节：“镜头动态跟随玩家，大型战斗允许拉远，以保证多人战场可读性。具体镜头参数由实现验证确定。”
- 镜头 ×1.875、站立脚底在画面 88%：`d2cb338`（`game/world/gameplay_camera.gd`，用户 2026-10-30 按参考实机画面决定），依据与截图见 `codexandclaude/proposals/ART-003/player_scale_v1/`。
- 待办 BL-127（镜头部分）、BL-128。

## 允许修改的文件

- `game/world/gameplay_camera.gd` 与需要拉远的战斗会话脚本（Boss、战场波次）；镜头参数可放进配置资源。
- `game/debug/movement_lab.tscn`、`enemy_lab.tscn`、`combat_lab.tscn`、`checkpoint_lab.tscn` 的镜头。
- `game/tests/test_gameplay_camera.gd` 及新增测试（首行按 ENV-004 登记）。
- `codexandclaude/tasks/SYS-013/`。

## 接口与影响

- 拉远只改 `zoom` 与 `position`，不占用 `offset`（留给演出与屏幕震动，见 `gameplay_camera.gd` 注释）；屏幕震动按屏幕像素计算的约定不变。
- 拉远期间视野不越出 Room 边界；进入、退出平滑过渡，不与演出镜头冲突。

## 完成标准

1. **补审**：交付记录先写对 `d2cb338` 的只读审查结论（问题清单与建议），需要修的在本任务内修。
2. Boss 战与战场波次期间镜头拉远到可配置倍率（起草建议 ×1.5 左右，由实现验证确定），平滑进出；普通 Room 保持 ×1.875。
3. 四个调试实验场景改用 `GameplayCamera`。
4. 核对报告：列出竖向 Room 中玩家看不到上方或下方落点的位置，以及 Boss 出招预兆超出画面的情况，附截图；只报告，不改关卡。
5. G2、G3 通过。

## 检查

- G2：拉远倍率、过渡、边界限制、震动幅度、演出期间不冲突。
- G3：`python codexandclaude/tools/run_checks.py full --jobs 4`。

## 验收入口

- 验收适配器直达渴望俯视 Boss 战与一处战场波次，存档隔离；用户检查拉远时机、倍率与过渡手感。

## 回滚方案

`git revert` 本任务提交。

## 不在范围内

- HUD 尺寸（等 UI 美术重设计 BL-130）、关卡几何调整、调试文字在发行版中隐藏（另行处理）。
