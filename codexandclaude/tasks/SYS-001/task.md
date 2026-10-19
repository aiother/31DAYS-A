# SYS-001：冻结V0.1键位并修复方向键

状态：已完成（2026-10-19 用户 G4 通过并授权合并，master 的 G2＋G3 全量通过；见 integration.md）｜级别：M｜实现：Codex｜审查：Claude
工作区：worktrees/codex｜基线：DOC-003 合并、本任务卡合入后的 master 最新提交（实现者在交付记录中写明完整 SHA）｜依赖：DOC-003（T1 §7 冻结键位表须先合入）

## 目标

让 `game/project.godot` 的输入映射与 T1 §7 冻结键位表完全一致，修复左右方向键绑定错误，并用测试锁定每个动作绑定的具体按键，防止以后再出现同类错误。

## 依据

- T1 §7 冻结键位表（DOC-003 写入）；待决事项总表 A-010（用户 2026-10-19 裁决：按表冻结并修复方向键）。
- Claude 于 2026-10-19 用 Godot 4.7.2 的 `OS.get_keycode_string` 核对：当前 `move_left` 绑定 A 与 4194321（Right），`move_right` 绑定 D 与 4194323（PageUp）；左方向键应为 4194319（Left），右方向键为 4194321（Right）。

## 现状

- 其余动作（瞄准、跳跃、攻击、闪避、恢复、跑步、互动、药包、暂停、菜单确认、全屏、调试重置）的键盘、鼠标与手柄绑定，与 T1 §7 一致。
- `tests/test_game_project.py::test_keyboard_controller_and_future_actions` 只检查每个动作“有键盘键、有手柄键”，不检查具体是哪个键，所以没有发现方向键错误。
- 主目录 `D:\31days` 中 `game/project.godot` 有用户未提交的改动（编辑器重新保存导致的格式变化）。

## 允许修改的文件

- `game/project.godot`：只改 `[input]` 节中 `move_left`、`move_right` 的方向键事件；保持文件现有的紧凑写法，不让编辑器把其他动作展开成冗长格式，不改其他节
- `tests/test_game_project.py`：把键位检查改为逐动作核对 T1 §7 中的具体键码、手柄按钮/摇杆方向与鼠标键
- `game/tests/test_input_bindings.gd`（新增）及其 `.uid`：运行时检查 InputMap，模拟按下左右方向键分别触发 `move_left`、`move_right`
- `scripts/verify_game.py`（只登记新套件）、`tests/test_verification_runner.py`（只同步套件数量）
- `codexandclaude/tasks/SYS-001/task.md`（只更新首部状态）、`codexandclaude/tasks/SYS-001/delivery.md`（新增）

## 接口与影响

- 输入映射是全局配置，影响所有 Room 的移动操作。只改两个方向键事件，A/D、手柄与其他动作不变。
- 若发现游戏内按键提示文字与冻结表不一致（例如写错方向键），在交付记录中列出，不在本任务中修改。

## 完成标准

1. 左方向键触发 `move_left`，右方向键触发 `move_right`；PageUp 不再绑定任何移动动作。
2. `tests/test_game_project.py` 对 T1 §7 每一行逐项核对具体绑定（键盘键码、手柄按钮或摇杆方向、鼠标左键），新增断言在修复前对方向键失败、修复后通过。
3. 新增的 Godot 运行时测试通过，并已登记进全量验证。
4. `project.godot` 的差异只涉及两个方向键事件。

## 检查

- G1：`tests/test_game_project.py`、`game/tests/test_input_bindings.gd`。
- G2 + G3：`python codexandclaude/tools/run_checks.py full --jobs 4`。
- G4（审查通过后、合并前，用户实机）：在游戏中用左右方向键移动，确认方向正确；A/D 与手柄移动不受影响。

## 合并注意

合并前用户需先还原主目录中未提交的 `game/project.godot`（`git -c safe.directory=D:/31days restore -- game/project.godot`）。集成者发现主目录该文件仍有未提交改动时，按 V2.2 停止并报告，不自动 stash、覆盖或还原。

## 回滚方案

`git revert` 本任务的实现提交即可；不涉及存档。

## 不在范围内

- 修改其他动作的绑定，或新增玩家自定义按键功能（属于 T7 后续工作）。
- 修改游戏内提示文字、菜单或 HUD。
