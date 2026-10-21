# SYS-006：透支下限拒绝的闪避也发出不足信号

状态：草稿（待用户批准）｜级别：S｜实现：Codex｜审查：Claude
工作区：worktrees/codex｜基线：master@3650b726631b299663ddb09183d03bff65b05f32（或批准时 master 最新提交，实现者在交付记录中写明完整 SHA）｜依赖：SYS-005（已完成）；与 UI-002 互不依赖

## 目标

完成待办 BL-114：玩家按下闪避、但本次成本会让余额低于透支下限而被拒绝时，也发出 SYS-005 的可能性不足信号，让正式 HUD 的可能性环发红闪烁。

## 依据

- 用户 2026-10-21 决定（SYS-005 审查 N2）：“被透支下限拒绝的闪避也要闪红。”
- 裁决 A-018（可能性不足以完整执行恢复或闪避时容器发红闪烁）；SYS-005 任务卡与审查记录 N2；`game/docs/ui_data_interface.md`。

## 现状（起草时核对 master@3650b72）

- `PlayerPossibility.try_dodge()` 在 `balance - cost < config.floor_balance` 时直接返回 false，不发任何信号；只有执行了的透支闪避（`poor_dodge`）发出 `shortfall(DODGE)`。
- `test_ui_data.gd` 现有断言 “floor-rejected dodge does not report an executed overdraft” 要求此时**不**发信号——这是 SYS-005 当时的口径，本任务按用户决定改为发出。
- UI-002 的 `FormalHud` 对任何 `shortfall` 都闪红，不区分原因；本任务不需要改 HUD。

## 要求

1. 闪避因透支下限被拒绝时，发出一次 `shortfall(ShortfallKind.DODGE)`；不新增信号种类，不改变拒绝本身（不扣费、不进入闪避、返回 false）。
2. 其他原因被拒绝时仍不发：不能控制、落地硬直、正处于闪避中、一串已闪满三次（`chain >= 3`）。
3. 按住闪避键不会每帧重复发出：只在真实按下的那一帧发一次（沿用现有 `is_action_just_pressed` 调用路径）。
4. 余额、透支下限、成本、存档格式全部不变。

## 允许修改的文件

- `game/player/player_possibility.gd`：下限拒绝分支的发出点。
- `game/tests/test_ui_data.gd`：把上述断言改为“下限拒绝发出一次 DODGE”，并补充 `chain >= 3` 不发、按住不重复发；必要时新增测试（首行登记）。
- `game/docs/ui_data_interface.md`：不足信号的口径。
- `codexandclaude/tasks/SYS-006/task.md`（只更新首部状态）、`delivery.md`（新增）。

## 完成标准

1. 真实输入：余额等于下限时按闪避，发出一次 DODGE，余额不变、不进入闪避；第四次连闪被拒不发；按住闪避键多帧只发一次。
2. 原有不足信号边界（余额等于成本不发、透支闪避发、恢复不足发、满血不发）不变。
3. 变异：去掉新发出点、或改成对 `chain >= 3` 也发出，相应断言失败。
4. G2 + G3 通过。

## 检查

- G1：`test_ui_data.gd`、`test_possibility.gd`；UI-002 合入后加 `test_formal_hud.gd`。
- G2 + G3：全量，交付记录贴自动摘要。
- G4：可选——UI-002 合入后，用户在透支到 -9 附近连续闪避，确认被拒的闪避也闪红。

## 回滚方案

`git revert` 本任务提交即可；不改存档、不改规则。

## 不在范围内

- HUD 绘制（UI-002 已对任何不足信号闪红）。
- 任何数值、透支下限或闪避规则的改变。
