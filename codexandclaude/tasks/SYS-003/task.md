# SYS-003：最终战同帧胜利优先

状态：已完成（2026-10-20：用户授权合并，master 完整 G2+G3 通过；按获批任务卡不需要 G4）｜级别：M｜实现：Codex｜审查：Claude
工作区：worktrees/codex｜基线：DOC-006 合并、本任务卡合入后的 master 最新提交（实现者在交付记录中写明完整 SHA）｜依赖：DOC-006（A-012 写入规格）

## 目标

按用户裁决 A-012，把最终战“最后一波清场”与“倒计时归零”发生在同一帧时的结算，从现行的超时优先改为胜利优先，并用测试锁定两种处理顺序下的结果。

## 依据

- 待决事项总表 A-012（2026-10-19 用户裁决：选② 胜利优先）；B-009 已同步。
- T2、T4、T5.3、T5.4“2026-10-17实施修订：10强化与最终战灰盒闭环”中的同帧优先级（DOC-006 已改为“同帧归零与击杀时胜利优先”）。
- 待办清单 BL-090。

## 现状（起草时核对 master@63ba950 的代码）

- `game/world/final_battle_session.gd` 的 `_on_stage_completed()`：救场后协同阶段每一波清场时，先判断 `final_remaining` 或 `day3_remaining` 是否已归零，归零即设 `_timeout_pending` 并显示超时；之后才判断是否是最后一波、进入胜利。
- `game/tests/test_final_retry.gd:85` 断言“same-frame zero time and final clear resolves as timeout”，即测试把旧规则当作正确行为。
- 倒计时在会话的计时处理中递减并可能先触发超时，因此同一帧内“归零”与“最后一击”的处理先后并不固定。

## 允许修改的文件

- `game/world/final_battle_session.gd`（如需要，`game/world/rooms/final_battlefield_room.gd`）：同帧结算顺序
- `game/tests/test_final_retry.gd`：把第85行的旧断言改为胜利优先，并补充用例
- 如需新增专项测试文件，同步 `scripts/verify_game.py`（只登记）与 `tests/test_verification_runner.py`（只同步计数）
- `game/docs/final_battle_implementation.md`：更新同帧优先级说明
- `codexandclaude/tasks/SYS-003/task.md`（只更新首部状态）、`delivery.md`（新增）

## 完成标准

1. **最后一波清场**与倒计时归零在同一帧发生时，结算为胜利：保存胜利标记、清除超时标记、进入与10对话，不显示超时界面。
2. 两种处理顺序都成立：先处理归零再处理最后一击，与先处理最后一击再处理归零，结果都是胜利。
3. **非最后一波**清场时倒计时已归零，仍按超时处理（只有最终胜利享有优先）。
4. 倒计时在清场前一帧或更早已经归零并显示超时后，再击杀敌人不改判为胜利；已保存的超时读档后仍是超时（现有断言保留）。
5. 胜利保存失败时保持现有的重试行为；不改变预算、重试、救场、波次、奖励等其他规则。
6. 现有最终战相关测试全部通过。

## 检查

- G1：`game/tests/test_final_retry.gd`、`game/tests/test_final_battle.gd`。
- G2 + G3：`python codexandclaude/tools/run_checks.py full --jobs 4`。
- 审查时做变异检查：把优先级临时改回超时优先，相关新断言应失败。
- G4：不需要。同帧结算无法在实机中稳定复现，且没有界面或手感变化；由自动测试覆盖两种顺序。

## 回滚方案

`git revert` 本任务的实现提交即可；不涉及存档字段，旧存档中已保存的胜利或超时标记含义不变。

## 不在范围内

- 超时界面改为“未来已失”加重试（A-011，属于 UI 任务 BL-051）。
- 已通关存档不能再进入（A-013，BL-091）。
- 倒计时显示规则（A-016）与其他最终战规则。
