# SYS-003 交付记录

实现者：Codex｜日期：2026-10-20｜状态：待 Claude 审查。

- 分支：`codex/SYS-003`，工作区：`D:/31days/codexandclaude/worktrees/codex`。
- 基线：`2013c34117d37cbb66ce62ef29b9dfbc850abd48`，即 DOC-006 合并收尾、固定 SYS-003 规划合并及规划 G3 证据提交后的 master。
- 实现 SHA：`0dd710735cb8420f3f107b1754e72859eefe5dfc`。
- 用户在会话中批准 SYS-003 任务卡并要求从合并后的 master 开工；沿用卡中 G4 不需要的批准依据。

## 修改与规则边界

实现只修改任务卡允许的四个文件：

| 文件 | 改动 |
| --- | --- |
| `game/world/final_battle_session.gd` | 归零及清波统一排入本物理帧末结算；仅最后一波、两批既有增援到齐且真实敌人清空时优先胜利；其余零余量仍超时。恢复存档时取消旧队列，回调以房间实例标识防止跨房间结算。 |
| `game/tests/test_final_retry.gd` | 替换旧的同帧超时断言；增加三波、两种处理顺序、两种归零来源的12组边界，以及房间扫描后击杀、前一帧已超时后再击杀、零余量胜利保存失败和 E 重试。保留普通死亡、读档不回补、已保存超时读档、零预算、开战保存失败等检查。 |
| `game/docs/final_battle_implementation.md` | 把实施说明的同帧规则改为最终清场胜利优先，说明中间波、既有超时与保存失败边界。 |
| `codexandclaude/tasks/SYS-003/task.md` | 只更新首部状态。 |

`_clock_tick()` 不在归零瞬间暂停世界，而是等待本帧角色结算；`_on_stage_completed()` 也不立即推进波次，从而确保中间波“先清场、后归零”不会先进入下一波。帧末检查敌人生命还覆盖房间物理优先级 -10 先扫描、角色优先级0随后完成击杀的情况。

选择胜利前清除待写超时标记，沿用原有胜利事务；写盘失败仍保留 `_win_pending`，停表、不开返回门，由 E / RB 重试。已显示超时或已保存 TIMEOUT 的会话不能被后续清波改判。探索超时、预算、暂停、重试、波次配置、救场、奖励、存档格式均未修改。

## 测试方法与先失败证据

边界测试使用真实 FinalBattleSession、Room、敌人受击/死亡/奖励及 Room 完成信号。测试先通过正常存档加载与开战，再手动定位波次、令增援到齐、将指定余量设为0.01秒，并停用自动推进；在同一个 `physics_frame` 回调中按两种顺序调用真实会话时钟与受击路径，以稳定复现竞态。三波实际阵容、增援等待及完整通关流程继续由原 `test_final_battle.gd` 覆盖。

“房间扫描后击杀”用例只造成真实敌人死亡，不再次调用 Room 扫描，确认帧末结算能识别尚未发出清波信号的最后一击。保存失败用例将 store.directory 临时指向已有存档文件下的不可用目录，确认事务回滚后再恢复并按 E 重试。全部测试使用独立 `user://tests/final_retry_<时间戳>` 存档并清理。

新边界检查先加入旧实现：`FINAL_RETRY_TESTS checks=57 failures=8`，失败集中于归零先处理的最终波胜利、清场先处理的中间波推进及零余量胜利保存重试。日志：`codexandclaude/runs/20261020T073647.215771Z/summary.json`。修复并补齐全部波次后为72/72通过。更早的默认沙盒首跑在导入阶段因系统证书与 Godot 编辑器设置访问限制失败，未执行专项；正常本机权限复跑后才取得上述红测证据，没有把环境失败计作代码回归。

## 检查与证据

| 检查 | 实际命令 | 完整性与结果 |
| --- | --- | --- |
| G1 | `python codexandclaude/tools/run_checks.py focused --godot-script res://tests/test_final_retry.gd --godot-script res://tests/test_final_battle.gd` | 导入通过；重试/边界72/72，完整最终战29/29，入口及子命令退出0 |
| G2+G3 | `python codexandclaude/tools/run_checks.py full --jobs 4` | 引擎预期75项、实际75/75通过（导入＋主场景＋73个专项）；Python tests/ 完整92/92、协作测试完整42/42，summary.passed=true，所有命令退出0 |
| 实现提交后 G3 | `python codexandclaude/tools/run_checks.py focused --python-all` | 实现 SHA 上 dirty=false、status=[]；92/92＋42/42，两组 complete=true、passed=true，summary.passed=true |

原始日志（均在本工作区，不入库）：

- G1：`codexandclaude/runs/20261020T073916.514027Z/summary.json` 及对应日志。
- 完整 G2+G3：`codexandclaude/runs/20261020T073957.775564Z/summary.json`、`engine.txt` 及对应日志；引擎报告 SHA256 为 `e18517f2f7ab33cf9038f46f918e4d8c16899a296decc4a9f38f6692a172e233`。
- 实现提交后 G3：`codexandclaude/runs/20261020T075130.450812Z/summary.json` 及对应日志。

G1 与完整检查发生在实现提交前，被测 SHA 为上述基线、dirty=true；被测四个实现文件与实现提交内容一致。Godot 导入产生的两份 `.svg.import` 仅换行变化，确认 `git diff --ignore-cr-at-eol` 为空后已恢复，没有纳入实现。未新增测试套件，验证入口及登记计数保持原样。

工具：Godot `4.7.2.stable.official.ed1daf0bf`；Python3.12.14、openpyxl3.1.5、Git2.56.0.windows.2、Node v24.19.0。最终正常检查无原有或新增失败、解析错误、泄漏或超时。G4 按获批任务卡不需要：同帧顺序由自动测试覆盖，没有新增界面或手感设计。

本交付提交仅新增本记录、将任务卡首部改为待审查，提交前再次执行 G3 与差异检查；不重新触发 G2。

## 请 Claude 审查

固定交付 SHA，核对实现到交付只有本记录与任务卡状态；按任务卡独立跑 G1、完整 G2+G3。重点看只有最后一波同帧清场可胜利，第一、二波两种顺序均超时；已显示/保存超时不能被后续击杀改判；帧末扫描与保存失败重试不改变其他规则。按卡做变异检查（将超时判断移回胜利之前，新边界断言应失败）。本次实现尚未合并 master。
