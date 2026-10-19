# SYS-001 审查记录

审查者：Claude｜日期：2026-10-19
被审实现 SHA：`c47c4c0b4bc6048885ce8a73398bd5428aee8afd`
被审交付 SHA：`e315b3755939f8f645c242c670ef68be6c19a685`
工作区：`worktrees/claude`，以 `git switch --detach <交付SHA>` 固定后复跑，审查分支 `claude/SYS-001-review` 建在交付提交上。

## 结论：通过（待用户 G4 实机验收后方可合并）

完成标准 1～4 全部满足，改动严格在任务卡允许的文件内；独立复跑的 G1、变异检查、G2 + G3 全部通过。没有阻断问题，也没有需要用户裁决的事项。按任务卡，合并前还需用户完成 G4。

## 范围核对

- 基线 `1f9f0ff` 已包含 DOC-003（T1 §7 冻结键位表）与本任务规划；`git merge-base` 与交付记录一致。
- `git diff <实现SHA> <交付SHA>`：仅新增 `delivery.md`、更新任务卡首部状态。
- 实现相对基线：`game/project.godot`、`game/tests/test_input_bindings.gd` 与 `.uid`、`scripts/verify_game.py`（新增1行登记）、`tests/test_game_project.py`、`tests/test_verification_runner.py`（71→72）、任务卡首部。与任务卡允许清单一致。
- `game/project.godot` 差异只有两处：`move_left` 的 4194321（Right）→ 4194319（Left），`move_right` 的 4194323（PageUp）→ 4194321（Right）。紧凑格式、其他事件与其他节未变。

## 完成标准逐条核对

| 标准 | 结果 | 依据 |
| --- | --- | --- |
| 1 左右方向键各自触发对应动作，PageUp 不再绑定移动 | 满足 | 运行时测试注入 Left/Right/PageUp/A/D，检查动作、移动轴与松键复位（`test_input_bindings.gd:52-67, 98-102`） |
| 2 Python 测试逐项核对 T1 §7 每一行 | 满足 | `test_game_project.py` 对15个动作比对完整事件列表（键码区分物理/逻辑、手柄按钮与摇杆方向、鼠标左键），用 `assertCountEqual` 防止多绑或少绑；逐行对照 T1 §7 无遗漏 |
| 3 新 Godot 运行时测试通过并登记进全量验证 | 满足 | 已登记为 `INPUT_BINDINGS_TESTS`；全量中 89/89 |
| 4 `project.godot` 差异只涉及两个方向键事件 | 满足 | 见范围核对 |

## 独立复跑

环境：Godot 4.7.2.stable.official.ed1daf0bf；Python 3.12.14 + openpyxl 3.1.5；Git 2.56.0.windows.2；Node v24.19.0。

| 检查 | 命令 | 结果 |
| --- | --- | --- |
| G1 | `run_checks.py focused --python-module tests/test_game_project.py --godot-script res://tests/test_input_bindings.gd` | 导入通过、输入套件通过、`test_game_project.py` 11/11；sha=交付 SHA，dirty=false，退出码 0 |
| 变异检查（Godot） | 在审查工作区临时把两个方向键改回原错误值，再跑同一命令 | `INPUT_BINDINGS_TESTS checks=89 failures=9`，入口退出 1；与交付记录中修复前复现一致 |
| 变异检查（Python） | 同一临时改动下单跑 `tests.test_game_project` | `move_left`、`move_right` 两个子用例失败；检查后已 `git restore` 还原，工作区干净 |
| G2 + G3 全量 | `run_checks.py full --jobs 4` | G2 预期 74、实际 74（导入、主场景、72 套件），引擎报告 72 行 `failures=0`、0 行非零失败、0 个错误/解析失败/泄漏/超时标记，`INPUT_BINDINGS_TESTS checks=89 failures=0`；G3 81/81 + 37/37；退出码 0；sha=交付 SHA，dirty=false；UTC 17:24:25 至 17:35:15；engine.txt SHA256 `cdb88e7eba752f90ba1be0cb4288a9d5385a2e20b13a29571786aa9f6b2109c3` |

全量运行后两份 `.svg.import` 出现仅换行符变化（`git diff --ignore-cr-at-eol` 无内容差异），已还原，未提交。原始日志在审查工作区 `codexandclaude/runs/`，不入库。

交付记录中的预提交全量运行是在 sha=基线、dirty=true 的工作树上执行的，并给出六个文件的 blob 对应；本次审查在干净的交付 SHA 上重新全量通过，结论一致。

## 其他观察（非阻断）

- 交付记录说明已核对 movement_lab、checkpoint_lab、enemy_lab、combat_lab 与 start_room_session 的移动提示，没有发现与冻结表冲突的文字。本次审查未逐一复核这些提示。
- 交付记录指出主目录 `game/project.godot` 当前已无未提交差异（用户已还原）。合并时集成者仍需按 V2.2 再核对一次。

## G4 与合并

用户在本分支（或审查 SHA）上实机检查：

1. 左右方向键分别向左、向右移动，松开后停止；按 PageUp 不再移动。
2. A/D 移动正常；手柄左摇杆与十字键左右移动正常。

G4 通过后，待用户授权，由集成者合并**本审查记录所在提交（审查 SHA）**；合并后按矩阵（游戏代码、输入）在 master 跑 G2 + G3。
