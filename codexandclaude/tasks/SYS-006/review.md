# SYS-006 审查记录

审查者：Claude｜日期：2026-10-21｜结论：**通过**（无阻断项，无问题）

## 固定对象

- 基线：`9fa942db75158dfb9f65d9822871b0d7743f3be5`（任务卡合入后的 master）
- 实现：`19526a40816e30d0ca585e61aa7fcb679d35ac89`
- 交付／被审 SHA：`62c787e5e2d266c06b61dd2b99afba13cfa29895`，在 Claude 工作区 `git switch --detach 62c787e` 后审查；审查分支 `claude/SYS-006-review` 只新增本记录。
- 实现到交付：只有 `delivery.md` 与任务卡首部。

## 范围

`player_possibility.gd`（`try_dodge()` 拒绝分支）、`test_ui_data.gd`、`ui_data_interface.md`，均在任务卡允许范围内。未改 HUD、数值、透支下限或存档格式。

## 要求逐条核对

| 要求 | 结果 |
| --- | --- |
| 1 下限拒绝发一次 DODGE | 成立。`balance - cost < floor_balance` 时 `shortfall.emit(DODGE)` 后返回 false；不扣费、不发 `balance_changed`、`dodge_serial` 不变、不进入闪避 |
| 2 其他拒绝不发 | 成立。控制、落地硬直与动作状态检查在函数开头先返回；`chain >= 3` 拆成独立分支排在下限之前，满三次时即使同时触及下限也不发 |
| 3 按住不重复 | 成立。仍经 `is_action_just_pressed` 调用；测试按住 90 帧（超过连闪重置时间）只发一次，松开再按算新的一次 |
| 4 规则不变 | 成立。恰好到达下限仍可执行（判断仍为严格小于） |

旧断言 “floor-rejected dodge does not report an executed overdraft” 改为发出一次 DODGE，与用户 2026-10-21 决定一致；其余 SYS-005 不足信号边界的断言未改。

## 独立检查

- **完整门禁**：在交付 SHA、起止 dirty=false 执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：G2 **79/79**，G3 `tests` **102/102**、`codexandclaude/tests` **67/67**，passed=true，**content_stable=True**。摘要 `codexandclaude/runs/20261021T082740.429037Z/`（不入库）。
- **G1**（`--fixed-fps 60`）：`UI_DATA_TESTS 54/0`、`POSSIBILITY_TESTS 41/0`。
- **变异**（临时改 `player_possibility.gd`，跑 `test_ui_data.gd`，按原字节恢复后复跑 54/0）：

| 变异 | 结果 |
| --- | --- |
| 去掉下限拒绝的发出点 | 54 项中 5 项失败（与交付记录一致） |
| 连闪满三次也发出 | 2 项失败（与交付记录一致） |

- **与 UI-002 的合入关系**：`git merge-tree` 试算 UI-002 交付 `e240c6c` 合入本交付及合入 master `9fa942d` 均无冲突（两边都改了 `ui_data_interface.md`，位置不同）。UI-002 的 `FormalHud` 对任何 `shortfall` 都闪红，无需改动；可选 G4 留待两者都合入后进行。

工具：Godot 4.7.2 stable（控制台版）、Codex 自带 Python 3.12.14 / openpyxl 3.1.5、Git 2.56.0.windows.2。

## 结论

通过。可按 `62c787e` 合入 master。
