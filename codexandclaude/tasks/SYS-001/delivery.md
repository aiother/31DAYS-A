# SYS-001 交付记录

实现者：Codex｜日期：2026-10-19｜状态：待 Claude 独立审查，G4 尚未进行，未合入 master。

- 基线：`1f9f0ff61a620792f1eb0e0d0472a7c1daae29c5`，DOC-003 与 SYS-001/002 规划均已合入。
- 实现 SHA：`c47c4c0b4bc6048885ce8a73398bd5428aee8afd`。
- 分支：`codex/SYS-001`；工作区：`D:/31days/codexandclaude/worktrees/codex`。

## 实际修改

| 文件 | 内容 |
| --- | --- |
| game/project.godot | 只修改两个方向键事件：move_left 的4194321改为4194319（Left），move_right 的4194323改为4194321（Right）；保留紧凑格式、其他事件及全部其他节。 |
| tests/test_game_project.py | 原键位测试改为核对 T1 §7 全部15个动作的完整事件列表：物理/逻辑键码、鼠标按钮、手柄按钮及摇杆轴方向；保留 LB 提示检查。 |
| game/tests/test_input_bindings.gd、.uid | 新增89项运行时检查，以 Godot KEY/JoyButton/JoyAxis 枚举核对实际 InputMap；经 Input.parse_input_event 注入 Left、Right、PageUp、A、D，检查左右动作、运动轴与松键复位。等待引擎初始化后开始输入，按下/松开使用不同事件实例，不修改 InputMap。 |
| scripts/verify_game.py | 只登记新输入套件；原验证判断不变。 |
| tests/test_verification_runner.py | 只将套件总数及路径唯一计数由71同步为72。 |
| codexandclaude/tasks/SYS-001/task.md | 只更新首部状态；实现提交先记进行中，本交付提交改为待审查。 |
| codexandclaude/tasks/SYS-001/delivery.md | 本交付记录。 |

核对了 movement_lab、checkpoint_lab、enemy_lab、combat_lab 和 start_room_session 的相关移动提示；未发现错误方向或与冻结表冲突的绑定文字，没有修改提示、菜单或 HUD。

## 复现与验证

| 检查 | 命令与结果 |
| --- | --- |
| 修复前 Python | `python -m unittest discover -s tests -p test_game_project.py -v`：11个测试中键位测试的 move_left、move_right 两个子用例失败，分别定位到原右键与PageUp键码；日志 runs/SYS-001-before-python.txt。 |
| 修复前 Godot | 通过现有 focused 入口运行已登记的新套件；89项检查9失败，检出左键无效、右键触发左移、PageUp触发右移及映射错误。无沙盒环境错误的复现见 runs/20261019T170733.961346Z/008.txt，入口退出1。 |
| 修复后 G1＋G3 | `python codexandclaude/tools/run_checks.py focused --python-all --godot-script res://tests/test_input_bindings.gd`：导入、输入套件89/89、tests/ 81/81、codexandclaude/tests/ 37/37，退出0；runs/20261019T170840.288999Z/summary.json。 |
| 完整 G2＋G3 | `python codexandclaude/tools/run_checks.py full --jobs 4`：预期74、实际74条目（导入、主场景180帧、72个套件），全部退出0；72个套件汇总均为 failures=0，错误/解析失败/泄漏/非零失败标记为0。随后 G3 为81/81＋37/37，summary.passed=true，入口退出0。 |
| 干净实现 SHA 的 G3 | 提交后 `python codexandclaude/tools/run_checks.py focused --python-all`：sha=上述实现 SHA，dirty=false，81/81＋37/37，退出0；runs/20261019T172109.065722Z/summary.json。 |

完整回归时间为 UTC 2026-10-19 17:09:04 至17:19:46。原始汇总在本工作区 `codexandclaude/runs/20261019T170904.492286Z/summary.json`，同目录 engine.txt 是原验证器报告；终端汇总为 runs/SYS-001-full-console.txt。engine.txt SHA256：`0fc80778c34ae814ef476f3a3f45ebd149e3914f88a3205ee34e0916c6fb5ccd`。原始日志不提交。

工具：Godot 4.7.2.stable.official.ed1daf0bf、Python 3.12.14、openpyxl 3.1.5、Git 2.56.0.windows.2、Node v24.19.0；工具绝对路径、每条命令、退出码和日志哈希在对应 summary.json。Godot 验证使用沙盒外执行权限，避免用户日志目录与系统证书访问限制干扰结果。

## 被测内容与提交对应

完整回归按“先验证再提交实现”执行，所以汇总 sha 为基线、dirty=true。验证过程中没有更改实现文件；以下六个文件在全量验证期间、结束后和实现提交中的 Git blob 一致：

| 文件 | Git blob |
| --- | --- |
| game/project.godot | 47048966b8b4d2db2242109c761fd891a8f23aec |
| game/tests/test_input_bindings.gd | 2d50181355a9a110ae3838b307ae43990acf93ea |
| game/tests/test_input_bindings.gd.uid | baa55edcd45cb94e2f08c62236e82c5dd66b0ada |
| scripts/verify_game.py | d37f3cfcd9ea4ba3da18a524408896b33ca64cce |
| tests/test_game_project.py | 2527e34c681895016be8123c376ff92941280d78 |
| tests/test_verification_runner.py | 0c9ed4e4235db87e8d7b49e50e190151cec077c1 |

全量导入曾让本工作区两份 SVG .import 文件出现纯换行差异（Git 内容 diff 为空），已恢复为基线原样，不提交导入生成物。完整回归后只更新任务状态和证据，提交前再次运行 G3 与差异检查，不因证据更新重复 G2。

主目录 `game/project.godot` 未被操作，SHA256 仍为 `683572e7c869772b23f73ac50914b3e11dad7821411cbbcc0a9f46526cddc5a7`。当前 Git 未显示它有未提交差异；不能据此免除将来的合并前检查。若届时存在未提交改动，集成者必须停止并报告，不自行还原或 stash。

## G4 与审查交接

自动注入事件不等于真实键盘/手柄验收。Claude 审查通过后，用户在本分支游戏的可移动场景检查：

1. 左右方向键分别向左/向右移动，松开后停止；PageUp不再导致移动。
2. A/D 移动仍正常；手柄左摇杆和十字键左右移动仍正常。

请 Claude 用 `git switch --detach <交付SHA>` 固定审查；核对实现 SHA 到交付 SHA 只有本记录及任务卡状态变化，确认 project.godot 仅改两个事件，并独立复跑 G1、完整 G2＋G3。无需现在操作主目录配置文件；用户会在 SYS-001 最终合并前处理它。

审查和 G4 完成后仍待用户授权合并固定审查 SHA，合并后 master 应跑 G2＋G3。本轮没有合入 SYS-001 实现、没有启动 SYS-002、没有推送。
