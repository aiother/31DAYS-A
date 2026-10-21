# SYS-007 审查记录（续作 r2）

审查者：Claude｜日期：2026-10-21｜结论：**通过**（无阻断项；3 条非阻断建议，交 UI-006 时一并处理）

## 固定对象

- 基线：`f6844a38e6f89ec8144296de068fd4889d1c0e4c`
- 实现：`430333b08d1884105ce6286e85567eaabc6e0b6d`
- 交付／被审 SHA：`b9e40620d0668134e016a0a296bfbd6651c1a43b`（分支 `codex/SYS-007-r2`）；旧失败分支 `codex/SYS-007`（`b592666`）只作追溯，不合入。审查分支 `claude/SYS-007-review` 只新增本记录。
- 实现到交付：只有 `delivery.md` 与任务卡首部。

## 范围

`project.godot`（仅自动加载与总线布局两段）、新增 `default_bus_layout.tres`、`systems/game_settings.gd`、四个音效脚本各一行 `bus`、`pause_menu.gd` 设置页三项回调、`test_settings.gd`、`settings_implementation.md`。任务卡写的是 `life_ui.gd`，并注明“若 UI-003 已先合入，改其设置二级页的对应调用”——UI-003 已把设置页移到 `PauseMenu.show_settings()`，改那里符合卡意，布局未动。物理帧率、输入映射、存档未改。

## 编译问题

原失败为自定义 SceneTree 预加载 UI 时 `Identifier not found: GameSettings`。现 `pause_menu.gd` 用 `get_node("/root/GameSettings")` 运行时取接口，不再在编译期引用自动加载全局名；`test_settings.gd` 常量预加载真实场景，覆盖了该路径。合并预演的全量中 `test_acceptance_launcher.gd` 通过。

## 要求逐条核对

| 要求 | 结果 |
| --- | --- |
| 1 总线 | 成立。Master 下 `效果音`、`背景音`，send=Master；三个敌人前摇音与玩家命中音都指定 `效果音`；背景音只预留 |
| 2 设置项与默认值 | 成立。三项音量 0～100 默认 100；窗口 1280×720 / 1920×1080 默认 1280×720（与 `window_*_override` 一致）；全屏默认 false；帧率 30/60/120/0 默认 60，只设 `Engine.max_fps`，从不写物理帧率 |
| 3 保存 | 成立。独立 `user://settings.cfg`（version=1 的 JSON），`_enter_tree` 读取并应用，在首帧前；缺失/损坏/未知版本整体回默认，单字段越界或类型错单独回默认；`JSON.parse` 不打 ERROR。测试与无头冒烟自动改用缓存目录，不读写玩家文件 |
| 4 按键列表 | 成立。按 T1 §7 顺序返回 15 项，文字取自实际 `InputMap`，无修改接口 |
| 5 接口 | 成立。`get_values / set_value / restore_defaults / bindings / changed`，界面不直接碰文件或总线；灰盒三项改走接口，行为不变 |

## 非阻断建议（UI-006 接入时处理即可）

1. `set_value()` 每次都走完整 `_apply()`：改音量也会重设窗口模式与尺寸——玩家手动拖动过窗口大小时，调音量会把窗口弹回所选尺寸。建议只应用变化的那一项。
2. 音量滑条的 `value_changed` 每一步都写一次文件（拖动一次可能写几十次）。可接受；UI-006 若觉得卡顿，可在松手（`drag_ended`）时保存。
3. `bindings()` 包含 `debug_reset`（调试重置）。正式设置页的“按键列表”是否展示它由 UI-006 决定，建议隐藏。

## 独立检查（SYS-007、SYS-008 共用）

- **合并预演**：在 Claude 工作区 detached 于 `3041960`（SYS-008 交付），`git merge --no-ff b9e4062`（SYS-007 交付）得到临时提交 `d04a84e`，无冲突（两边改动文件不相交）。该提交不推送、不作为合入目标，只用于验证两项合在一起的结果。
- **完整门禁**：在 `d04a84e`、起点 dirty=false 执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：G2 **85/85**（基线 83 + 两个新套件），G3 `tests` **102/102**、`codexandclaude/tests` **67/67**，passed=true。content_stable=False，原因与 Codex 相同：导入生成 EXP-003 两个未跟踪 `.gd.uid`，已跟踪 diff 为空；结束后删除这两个文件。摘要 `codexandclaude/runs/20261021T143835.822390Z/`（不入库）。
- **变异**（在合并预演上临时改源文件，`run_checks.py focused --godot-script` 跑对应套件，按原字节恢复）：

| 变异 | 套件 | 结果 |
| --- | --- | --- |
| 摘要把无法读取槽当空槽 | test_title_flow | 106 项中 2 项失败，退出 1 |
| `return_to_title()` 不保存直接返回 | test_title_flow | 102 项中 18 项失败，退出 1 |
| 天的前摇音留在 Master | test_settings | 112 项中 1 项失败，退出 1 |
| `set_value()` 不写文件 | test_settings | 112 项中 20 项失败，退出 1 |

工具：Godot 4.7.2 stable（控制台版）、Codex 自带 Python 3.12.14 / openpyxl 3.1.5、Git 2.56.0.windows.2。

## 合入建议

两项都按各自交付 SHA 合入 master（`3041960`、`b9e4062`），先后不限、无冲突；合入后跑一次 full。

## 结论

通过。可按 `b9e4062` 合入 master。
