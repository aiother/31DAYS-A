# SYS-003 审查记录

审查者：Claude｜日期：2026-10-20
被审实现 SHA：`0dd710735cb8420f3f107b1754e72859eefe5dfc`
被审交付 SHA：`952ea0ea3e75821ad73d9d3166381004c83394ea`
工作区：`worktrees/claude`，以 `git switch --detach <交付SHA>` 固定后复跑，审查分支 `claude/SYS-003-review` 建在交付提交上。

## 结论：通过

完成标准 1～6 全部满足，改动在任务卡允许范围内；独立复跑的 G1、两项变异检查、G2 + G3 全部通过。任务卡写明不需要 G4。没有阻断问题，也没有需要用户裁决的事项。

## 范围核对

- 基线 `2013c34` 已包含 DOC-006 合并与 SYS-003 规划；`git merge-base` 与交付记录一致。
- `git diff <实现SHA> <交付SHA>`：仅新增 `delivery.md`、更新任务卡首部状态。
- 实现相对基线 4 个文件：`game/world/final_battle_session.gd`、`game/tests/test_final_retry.gd`、`game/docs/final_battle_implementation.md`、任务卡首部。未新增测试套件，`verify_game.py` 与计数未改，符合任务卡。

## 实现核对

- **结算方式**：倒计时归零（`_clock_tick`）与清场回调（`_on_stage_completed`）不再各自立即结算，而是统一经 `_queue_final_resolution()` 用 `call_deferred` 推迟到当前物理帧末，由 `_resolve_final_frame()` 一次裁决；同一 Room 实例内只排队一次。这使“先归零”与“先击杀”两种顺序结果一致（完成标准 1、2）。
- **胜利条件**：仅当协同阶段、非波间预警、当前是最后一波（`wave_index == tian_counts.size() - 1`）、两批增援已到齐、且敌人容器中没有存活敌人时，才清除待定超时并保存胜利；否则若余量归零则判超时；否则正常推进下一波（完成标准 3）。
- **敌人存活判断**：`_wave_is_clear()` 只检查 `ColorlessEntity`。已核对 `TianWarrior`、`MonochromeEntity` 均继承 `ColorlessEntity`，最终战三波全部敌人都被覆盖；残存可能性实体在独立容器 `RemnantPossibility` 中，不在 `Enemies` 内，不影响判断。
- **已提交的超时不可改判**：`_on_stage_completed()` 与帧末结算在 `_timeout_active` 或已保存超时时直接返回（完成标准 4）。
- **保存失败**：胜利保存失败时保持 `_win_pending`、不转为超时，沿用 E / RB 重试（完成标准 5）。
- **副作用**：非最后一波的“推进下一波”也随之推迟到帧末执行，时序晚一个帧尾空闲点。全量 G2 中最终战、救场、增援相关套件全部通过，未发现回归。

## 独立复跑

环境：Godot 4.7.2.stable.official.ed1daf0bf；Python 3.12.14 + openpyxl 3.1.5；Git 2.56.0.windows.2；Node v24.19.0。

| 检查 | 命令 | 结果 |
| --- | --- | --- |
| G1 | `run_checks.py focused --godot-script res://tests/test_final_retry.gd --godot-script res://tests/test_final_battle.gd` | `FINAL_RETRY_TESTS checks=72 failures=0`、`FINAL_BATTLE_TESTS checks=29 failures=0`，退出码 0 |
| 变异 1：改回超时优先 | 临时让胜利分支只在余量大于 0 时成立 | `FINAL_RETRY_TESTS` 72 项中 11 项失败，退出码 1 |
| 变异 2：任意一波都可同帧胜利 | 临时去掉“当前是最后一波”条件 | 72 项中 16 项失败，退出码 1 |
| G2 + G3 全量 | `run_checks.py full --jobs 4` | G2 预期 75、实际 75（导入、主场景、73 套件），引擎报告 73 行 `failures=0`、0 行非零失败、0 个错误/解析失败/泄漏/超时标记；G3 92/92 + 42/42；退出码 0；sha=交付 SHA，dirty=false；UTC 08:30:17 至 08:41:05；engine.txt SHA256 `3e62412b69750622d6ab3a59cb3fd7a50ab383b50e25de8920677ebec0196bed` |

两项变异检查后均已 `git restore` 还原；全量运行产生的两份 `.svg.import` 仅换行符变化，已还原，未提交。原始日志在审查工作区 `codexandclaude/runs/`，不入库。

## 优化建议（非阻断）

1. `_wave_is_clear()` 与 `RescueBattlefieldRoom` 中已有的存活敌人扫描逻辑重复，可以考虑在 Room 上提供一个公共方法，让会话直接调用，避免两处判断将来不同步。
2. 帧末结算用“Room 实例 ID”防止切房后的过期回调，做法正确；如果以后 Room 可能在同一帧被替换为同一实例（例如对象池），需要改用递增的结算序号。目前项目没有对象池，不需要改。

## 合并

不需要 G4。待用户授权后，由集成者合并**本审查记录所在提交（审查 SHA）**；合并后按矩阵（游戏代码）在 master 跑 G2 + G3。
