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

---

## 用户 G4（2026-10-31）

结论：**通过，参数暂定**。

- Claude 用交付里的验收入口为用户打开渴望俯视 Boss 战窗口（临时存档，关窗清理；窗口自检 9 项通过、正常退出）。
- 用户原话：“镜头目前没问题了，后续我们往后测试可能会接着调整，暂时别写死。”
- 用户在验收中另提出 HUD 时间轴挡视野，已拆出为 UI-011（时间轴隐藏与换日动画），不属于本任务。

### 对“暂时别写死”的落实建议（交 Codex）

- N5：`GameplayCamera` 里普通倍率 `ZOOM = 1.875` 与脚底位置 `GROUND_RATIO = 0.88` 仍是 `const`，只有 `battle_zoom`、`transition_seconds` 可调。建议改成导出参数（默认值不变），静态辅助函数 `feet_lift()`、`world_length()` 改为读取实例值或接收参数；`game/docs/asset_spec.md` 第 1 节与 `tests/test_art_spec.py` 中“×1.875”的表述注明“暂定，可调”，测试读取默认值而不是写死数字。
- 已有的 `battle_zoom 1.5`、`transition_seconds 0.25`、Boss 偏移 35% 同样视为暂定，后续测试可直接调。

---

## 第 2 轮复审（2026-10-31，针对 N5 与 N1、N2）

结论：**通过**。

- 固定交付 `732ccc7`；实现 `8569ee3`。`git diff 8569ee3 732ccc7` 只有 `delivery.md`；`git diff 4427940 8569ee3` 涉及镜头脚本、规格、测试与截图采集脚本，与交付说明一致。审查分支已快进到交付提交，保留两轮历史。

### 核对

- **N5（暂时别写死）已落实**：`ZOOM`、`GROUND_RATIO` 改为导出参数 `normal_zoom`（默认 1.875）、`ground_ratio`（默认 0.88），默认值不变；`feet_lift()`、`world_length()` 改为实例方法，可接收实际倍率，战斗拉远时用当前倍率计算脚底位置。`asset_spec.md` 第 1 节注明“暂定默认值，可调”并记下用户原话；`tests/test_art_spec.py` 从脚本读取默认值，不再写死数字；Boss 偏移 35% 注明为暂定值。
- **N1、N2 已补断言**：Boss 战中玩家真实受到致命一击后镜头回到普通倍率、复活后恢复战斗倍率；镜头中心按 35% 朝 Boss 偏移。

### 变异（每次改一处后立即还原，工作区复核干净）

1. Boss 战忽略玩家死亡 → `test_battle_camera.gd` **失败**（第 1 轮存活，现被抓住）。
2. Boss 偏移系数 0.35 → 0 → `test_battle_camera.gd` **失败**（第 1 轮存活，现被抓住）。
3. `world_length()` 忽略传入的实际倍率（战斗拉远时脚底位置算错）→ `test_battle_camera.gd` 仍通过，`test_gameplay_camera.gd` **失败**（有覆盖）。

### 非阻断建议

- N6：`battle_zoom` 的导出范围上限仍是 1.875，而 `normal_zoom` 已可调到 4.0；若以后把普通倍率调高，编辑器里战斗倍率的上限会不一致。可把上限放宽或改为运行时按 `normal_zoom` 钳制（现在已有钳制，只是编辑器范围）。
- N7：35% 偏移仍是常量，若之后要调，可同样改为导出参数。
- N8：战斗套件没有直接断言“拉远后脚底仍在画面 88%”，目前靠普通镜头套件覆盖辅助函数。

### 检查证据

- 固定 `732ccc7`、工作区干净：`python codexandclaude/tools/run_checks.py full --jobs 4` **通过**，`content_stable=true`，引擎日志 0 条脚本错误。G2 登记 102 项，含 `BATTLE_CAMERA_TESTS checks=27`、`GAMEPLAY_CAMERA_TESTS checks=13`、`CINEMATIC_CAMERA_ZOOM_TESTS checks=4`；G3 `tests/` 192 + `codexandclaude/tests/` 83 项。摘要 `codexandclaude/runs/20261031T111326.465359Z/summary.json`（运行目录不入库）。

### 合入前提

审查通过、用户 G4 通过（2026-10-31，参数暂定）。可在用户批准时与其他卡一起合入；任务分支不推送。
