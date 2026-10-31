# SYS-013 交付记录

实现：Codex｜审查：Claude｜基线：`cc42d356d54b19c3ed7ef7d0b9bf2a0919f486d7`｜分支：`codex/SYS-013`｜工作区：`codexandclaude/worktrees/codex`

**最终实现 SHA：`82df350295e0f0e8840db4ab5c2b1688dc41aa33`**（实现 `3235a25` + 测试路径修正 `82df350`）。本记录单独提交；任务卡待审查状态已在实现内固定。未合并 master、未推送任务分支。

## 1. 补审 d2cb338（第一项）

结论：**原提交需修改；本任务已修复确认的问题**。

- 用户已确认的构图换算正确：112 世界单位 × 1.875 = 210 画面像素；1080 × (0.88 - 0.5) / 1.875 = 218.88 世界单位的脚底提升。碰撞、移动、Room 几何不变；震动除以当前 zoom 后保留屏幕像素幅度。
- 从干净 cc42d35 复跑原 `test_gameplay_camera.gd` 通过，摘要 `codexandclaude/runs/20261031T045338.840998Z/summary.json`。
- **确认缺陷**：`PlaceholderCinematics.begin` 的 seven.first 仍按旧半屏宽度 960 计算；真实田野入口玩家 x=160、7 在 x=1728，横移结束 offset=640、实际可见 x=640..1664，7 仍在画面外。只读探针在解除标题暂停后确认；早先保持暂停的探针没有形成有效证据。
- 新增 `test_cinematic_camera_zoom.gd` 在修复前失败（取景/居中断言），随后将半屏宽度改为 viewport / zoom / 2，并纳入 Camera 的局部水平位置。修复后新增 4 项断言、原田野流程均通过，摘要 `codexandclaude/runs/20261031T051115.516416Z/summary.json`。不改演出时长、剧情、输入或奖励。
- 非阻断建议：原镜头覆盖不足以证明竖向落点和全部远端预兆可见；本次用下面的独立报告记录盲区，未来几何/美术接入变化后重做核对。

**文件范围补充**：`game/systems/cinematics/placeholder_cinematics.gd` 不在起草时列举的主文件中，但它是上述 d2cb338 遗漏的实际实现位置。本次依据用户“补审发现需要修的在本任务内修”完成最小修复，并新增独立回归；未扩展演出功能。其余新增测试及 UID、任务目录中的报告/采集脚本均属于卡中范围。

## 2. 实现与触发

- `GameplayCamera.battle_zoom` 默认 1.5，可配置；`transition_seconds` 默认 0.25（指数过渡时间常数），普通状态仍为 1.875。限制单帧过渡步长，避免加载卡顿后瞬间跳变；以 Room 尺寸钳制最小倍率，不能拉出边界。
- 镜头位置随倍率调整脚底构图；Boss 战水平方向向 Boss 偏移 35%。只写 zoom / position，offset 继续由演出与震动管理。
- 会话以只读 `gameplay_camera_state()` 发布状态：两场 Boss 从实际开战至死亡；营帐 WARNING/ACTIVE/INTERVAL；战场开战与最终波次预警。完成、停止或玩家死亡后平滑恢复。查询不改存档/战斗状态。
- 演出 active 时不更新 gameplay 镜头缩放或位置，暂停也冻结；保留现有震动按屏幕像素计算。
- 四个实验场景都继承 movement_lab；只在该基础场景挂 GameplayCamera，四者实例化均已实测，避免重复镜头资源。
- 新增引擎套件 `test_battle_camera.gd`、`test_cinematic_camera_zoom.gd`，首行按 ENV-004 登记，UID 一并入库。新增 Python 报告/截图校验四项。

## 3. 视野核对（只报告，不改关卡）

见 [视野报告](visibility_report.md)：**12 个竖向 Room、69 个静态位置样本、28 张 1920×1080 实际渲染截图**，完整坐标与截图哈希在 `captures/audit.json` / `manifest.json`。

- 普通构图脚底以下仅 69.12 世界单位，塔楼/堑壕等高平台回看下层会遇到盲区。
- 两场 Boss 的 near 静态样本预兆中心可见；双方处于房间两端的 far 压力样本中心超出画面。它证明构图边界，不断言该状态是 AI 同一前摇内的真实可达轨迹。
- 采样包括入口、根节点及嵌套水平矩形平台；不替代完整通关，动态平台、落石、未来美术整幅轮廓仍须接入时复核。报告没有修改任何关卡几何。
- `capture_audit.gd` 可复现采集，玩法/物理禁用，只挂载生产 Room；不启动正式存档，不生成动作帧。

## 4. 检查证据

最终全量：`python codexandclaude/tools/run_checks.py full --jobs 4`。

- 被测 SHA：`82df350295e0f0e8840db4ab5c2b1688dc41aa33`，工作区干净且检查期间内容稳定。
- G2：预期/实际 **102 / 102** 项（100 套件 + 导入 + 主场景），全部通过，汇总 failures=0，无错误、解析失败、泄漏或超时。
- G3：`tests/` **192** 项，`codexandclaude/tests/` **83** 项，全部通过。
- 摘要：`codexandclaude/runs/20261031T051723.479676Z/summary.json`；引擎报告 SHA256：`3fbedaa1c13d538b0170a304b800884edb2aa0bef74dca3e575a1c78efb3659b`。
- 工具：Godot 4.7.2.stable.official.ed1daf0bf、Python 3.12.14 / openpyxl 3.1.5、Node v24.22.1、Git 2.56.0.windows.2。
- 最终交付只新增本记录；G2 可按 ENV-005 复用，G3 在本记录加入后实际重跑，仍为 **192 + 83** 全通过，记录检查摘要见同一工作区 runs 目录的最后一次 focused。
- 修复前证据：新战斗镜头测试在旧实现上拉远及实验场景断言失败；首次新实现测试被真实敌人攻击/死亡干扰，已把镜头专项夹具中的 Room 物理隔离；不改生产敌人行为。7 的新增专项在修复前取景断言失败，修复后通过。
- 首轮 full 的旧清单 G2 **101** 项通过，但运行中加入了补审修复，因此不复用该轮内容身份；该轮 G3 还发现格式化 `res://debug/%s.tscn` 被静态检查识别为不存在资源，82df350 已改成四个真实路径。上述最终 full 是完整重跑，不把首次失败写成通过。

## 5. 验收入口与自检

在本工作区根目录执行（Godot 为已配置的 4.7.2 console 程序）：

```powershell
# 渴望俯视 Boss 战
Godot --path game --script res://tests/acceptance/run_acceptance.gd -- --adapter=res://tests/acceptance/sys013_camera.gd

# 营帐波次入口：向右走出安全区触发
Godot --path game --script res://tests/acceptance/run_acceptance.gd -- --adapter=res://tests/acceptance/sys013_camera.gd --checkpoint=HD_20002_2_N001

# 自动自检
Godot --headless --path game --script res://tests/acceptance/run_acceptance.gd -- --adapter=res://tests/acceptance/sys013_camera.gd --self-test --no-panel
```

适配器使用 ENV-006 缓存临时目录，ready 前重定向存档，退出清理；不改正式槽。默认跳过已见过的 Boss 登场直达战斗；需要看完整首次演出的情况由原演出回归覆盖。

- 无头自检：**15** 项全部通过。
- 有渲染 `--self-test --capture --no-panel`：**23** 项全部通过，窗口退出、临时存档目录清理。截图在忽略目录 `codexandclaude/runs/SYS-013-g4/`，已查看 Boss 战与波次预警画面；它们是验收辅助证据，耐久截图为第 3 节的 28 张。
- **人工 G4 尚未完成**：请在 Claude 审查通过后观察拉远时机、倍率、过渡手感、读招、暂停、受击震动，以及结束后回正。自动检查不代表用户手感认可。

## 6. 交接与回滚

Claude 请固定交付提交，先确认与实现 82df350 的差异只有本 delivery.md，再复跑 G3 和所需 G2/专项（ENV-005 的 G2 复用需核对工具/环境及内容条件）。重点审查只读状态发布、演出所有权、最小倍率边界和补审的取景修复。不要把静态视野报告当作全流程实机验收。

回滚按提交链使用 git revert（82df350 为测试路径修正，3235a25 为主体实现），保留审查历史。ART-003 认可标准/引导图/提示词尚未交接，本次没有生成动作帧。
