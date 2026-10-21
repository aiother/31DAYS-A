# SYS-008 审查记录

审查者：Claude｜日期：2026-10-21｜结论：**通过**（无阻断项；2 条非阻断建议）

## 固定对象

- 基线：`f6844a38e6f89ec8144296de068fd4889d1c0e4c`（第五批规划合入后的 master）
- 实现：`857feb57f010dabf19bca77d4f45a9fdf4d9638b`
- 交付／被审 SHA：`30419607ef7b9a38ca5d788c4530e81b1a298e38`；审查分支 `claude/SYS-008-review` 只新增本记录。
- 实现到交付：只有 `delivery.md` 与任务卡首部。

## 范围

`checkpoint_lab.gd`、`life_ui.gd`（仅 `show_title()` 回退占位）、新增 `systems/save/slot_summaries.gd`、`test_title_flow.gd`、`title_flow_implementation.md`，均在任务卡允许范围内。`final_battle_session.gd` 未改（继承接口即可）；未改输入映射、存档字段、死亡/结束/超时规则。

## 要求逐条核对

| 要求 | 结果 |
| --- | --- |
| 1 无会话启动请求主界面 | 成立。`_ready()` 末尾由 `show_slots` 改为 `show_title`；`checkpoint_reload` 读档/死亡重载分支仍在其前返回，不受影响 |
| 2 `return_to_title()` | 成立。无会话只请求标题；有会话先走虚方法 `save_current()`（各子类的结算、结局、超时规则不变），失败返回 false 不离开；成功后延迟 `reload_current_scene()`，新实例为 slot=0/data 空，旧玩家、房间、敌人、计时随场景释放。`_reloading` 防重入；保存目录用一次性 `checkpoint_title` 元数据带过重载，隔离目录不会落回正式存档；重载失败恢复暂停状态并提示 |
| 3 `slot_summaries()` / `has_any_save()` | 成立。独立 `SlotStore` 只调 `load_slot`，不写盘、不修复，活动 store 的 `last_error/used_backup` 不变；四种状态、`day_progress` 用 `DayClock.remaining()`（第三日读 `day3_remaining`），珍珠按 ExplorationSession 的四个永久事件计数，检查点显示名来自资源。字段与值域写在 `title_flow_implementation.md` |
| 4 选槽入口不变 | 成立。`start_slot(slot, new_game)` 未改，A-013 拒绝与覆盖规则沿用 |

## 非阻断建议

1. `SlotSummaries.CHECKPOINT_CONFIGS` 手写了 10 个检查点资源，与 `data/checkpoints/` 目录目前一一对应；以后新增检查点若忘记登记，摘要只会显示空名字而不报错。建议后续加一条测试：目录下每个 `.tres` 都在该列表中（可并入下一个触及存档的任务，不必返工）。
2. `has_any_save()` 对“只有损坏槽”也返回 true（交付记录已说明）。UI-004 据此显示“继续游戏”时，选槽页需把损坏槽画成不可继续——由 UI-004 处理，记在此处备查。

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

通过。可按 `3041960` 合入 master。
