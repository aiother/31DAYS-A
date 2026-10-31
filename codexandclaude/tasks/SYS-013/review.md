# SYS-013 独立审查

结论：**通过（有两条非阻断测试建议）**｜审查：Claude｜日期：2026-10-30（用户当地日期）｜人工 G4 尚未进行。

- 基线 `cc42d35`；最终实现 `82df350`；交付 `9e1cc65`。固定 `9e1cc65` 审查；`git diff 82df350 9e1cc65` 只有 `delivery.md`，与交付说明一致。
- 工作区：`worktrees/claude-review`（detached `9e1cc65`）。

## 范围与实现核对

- **补审 `d2cb338`**：认可。构图换算（112 × 1.875 = 210 px、脚底提升 218.88）与我当时的实现一致；Codex 发现的缺陷成立且是真问题——`PlaceholderCinematics.begin` 里 `seven.first` 仍按半屏 960 计算，在 ×1.875 下 7 的位置会落在画面外。该遗漏是我实现 `d2cb338` 时的疏忽，修复（半屏宽按 `viewport / zoom / 2`，并计入镜头局部 x）最小且正确。
- **战斗拉远**：`GameplayCamera` 只写 `zoom` / `position`，`offset` 仍归演出与震动；按指数时间常数过渡，单帧步长受限，不会因卡顿跳变；倍率被 Room 尺寸钳制（`fitting_zoom`）。我核对了现有 Room：最小 1536×1080，任何战斗倍率下都不会误抬倍率。脚底仍保持在屏幕 88% 处，Boss 战只在水平方向向 Boss 偏移。
- **只读状态发布**：各会话以 `gameplay_camera_state()` 发布（Boss、营帐、战场），查询不改存档与战斗状态（测试断言）；演出 active 时让出控制，暂停时冻结。
- **实验场景**：只在 `movement_lab.tscn` 挂 `GameplayCamera`，其余三个实验场景继承它；全仓库只有两个场景含 `Camera2D`，没有重复镜头；测试实例化四个场景并断言类型。
- **视野核对报告**：12 个竖向 Room、28 张 1920×1080 截图，坐标与哈希可复现；报告明确只证明静态样本，不替代通关与 G4。结论与我的预期一致（普通构图脚底以下仅 69 世界单位；Boss 双方在房间两端时默认 ×1.5 盖不住）。只报告、不改关卡，符合任务卡。

## 非阻断建议

- N1：**玩家死亡后恢复普通镜头没有断言。** 任务卡与交付都写了“完成、停止或玩家死亡后平滑恢复”，但我把 `boss_session.gd` 里的 `player.life.is_alive()` 条件去掉后 `test_battle_camera.gd` 仍然通过（变异存活）。建议在 Boss 战中令玩家倒下，断言倍率回到 1.875。
- N2：**“朝对手偏移 35%”没有断言。** 把偏移系数改成 0 后 `test_battle_camera.gd` 仍然通过。现有测试只断言视野不越界。建议加一个断言：玩家与 Boss 相距较远时，镜头中心相对玩家的水平偏移按系数变化且不越界。
- N3：`gameplay_camera_state()` 每帧在会话上分配一个 Dictionary，当前规模无影响，仅记录。
- N4：演出期间镜头整体冻结，如果战斗刚结束就进入演出（例如 Boss 胜利演出），会带着 ×1.5 的构图直到演出结束才平滑恢复。这是演出所有权约定的结果，不算缺陷，G4 时可顺便观察是否可接受。

## 检查与变异证据

- **完整检查**：固定 `9e1cc65`、工作区干净，`python codexandclaude/tools/run_checks.py full --jobs 4` 通过，`content_stable=true`；G3：`tests/` **192** + `codexandclaude/tests/` **83**；引擎套件含 `BATTLE_CAMERA_TESTS checks=23 failures=0`、`CINEMATIC_CAMERA_ZOOM_TESTS checks=4 failures=0`。摘要 `codexandclaude/runs/20261031T054338.325484Z/summary.json`（运行目录不入库）。这是我自己复跑，没有复用 Codex 的 G2。
- **验收适配器**：无头 `--self-test --no-panel`：`SYS013_ACCEPTANCE_TESTS checks=15 failures=0`，与交付一致，临时存档已清理。
- **变异**（专项 Godot 套件，每次改一处后立即还原，工作区复核干净）：
  1. 镜头忽略演出所有权 → `test_battle_camera.gd` **失败**（被抓住）。
  2. 把 `seven.first` 半屏宽度改回 960 → `test_cinematic_camera_zoom.gd` **失败**（被抓住）。
  3. Boss 战忽略玩家死亡 → `test_battle_camera.gd` **仍通过**（见 N1）。
  4. 水平偏移系数 0.35 → 0 → `test_battle_camera.gd` **仍通过**（见 N2）。

## 用户 G4

自动检查不代表手感认可。请用户用交付里的验收入口观察：拉远时机与倍率、进出过渡、读招是否清楚、暂停、受击震动、结束后回正；并留意 N4 描述的演出衔接。
