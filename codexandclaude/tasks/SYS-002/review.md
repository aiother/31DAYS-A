# SYS-002 审查记录

审查者：Claude｜日期：2026-10-19
被审实现 SHA：`87b0dbeadb3cf768c7c1eae936c819cc24289b22`
被审交付 SHA：`511abbf0a82a73fdee536feb379c5a1928cd2b63`
工作区：`worktrees/claude`，以 `git switch --detach <交付SHA>` 固定后复跑，审查分支 `claude/SYS-002-review` 建在交付提交上。

## 结论：通过（待用户 G4 实机验收后方可合并）

完成标准 1～6 全部满足，T3 §11 的规则与任务卡批准的灰盒初值逐项落实，改动在任务卡允许的范围内；独立复跑的 G1、两项变异检查、G2 + G3 全部通过。没有阻断问题，也没有需要用户裁决的事项。下方列出两条非阻断观察，其中第 1 条建议用户在 G4 时留意。

## 范围核对

- 基线 `fdfc4c2` 已包含 SYS-001 合并与 DOC-003；`git merge-base` 与交付记录一致。
- `git diff <实现SHA> <交付SHA>`：仅新增 `delivery.md`、更新任务卡首部状态。
- 实现相对基线 15 个文件：新增配置脚本与 `.tres`、实体脚本与场景、生成器 `game/systems/combat/remnant_possibility_spawner.gd`、Godot 测试、实施说明；`game/world/boss_session.gd` 只加 1 行接入；`scripts/verify_game.py` 只加 1 行登记；`tests/test_verification_runner.py` 72→73；任务卡首部。全部在任务卡“允许修改的范围”内，未改 `colorless_entity.gd`、既有敌人参数、存档结构或策划文档。

## 接入与隔离的核对

- **接入覆盖**：会话是一条单线继承链，最终入口 `FinalBattleSession` 经 `RescueBattlefieldSession → … → ParasiteSession → CampWavesSession → … → BossSession`。`BossSession._bind_room()` 中的一行接入因此对其后所有房间生效，再由 `attach()` 的白名单筛选：`CampWavesRoom`、`BossRoom`、`ParasiteRoom`、`RescueBattlefieldRoom`（含子类 `FinalBattlefieldRoom`）。
- **排除**：堑壕为 `TrenchRoom`、`TrenchPassageRoom`，营帐外围为 `CampRoom`，旧首段预览为 `BattlefieldRoom`，均为 `WorldRoom` 的直接子类、不在白名单中；`BossSession` 之前的会话（起始、塔、连结处等）不调用接入。
- **奖励路径**：击杀走会话共用的 `_on_room_enemy_defeated`。该方法在连结处、沟壑深处、堑壕过道的重写只在各自 Room 类型下检查原有敌人容器；中心战场过场期间本就不发奖励。保底实体位于独立容器 `RemnantPossibility`，不会被计入清敌、波次或胜利。
- **数值与伤害**：日期强化不在 `ColorlessEntity._ready` 中应用，保底实体由生成器直接实例化，生命固定 13；无色实体的攻击判定区默认关闭，攻击与投射物只在已被重写的 `_physics_process` 中发起，配置伤害也置 0，故不造成伤害；`coordinator = null`，不占进攻名额。

## 规则逐条核对

| 规则（T3 §11 与任务卡） | 实现 | 结果 |
| --- | --- | --- |
| 适用五场强制战斗，不含堑壕 | 见上“接入与隔离” | 满足 |
| 余额低于当前上限的 50%（含负数） | `balance * 2 >= maximum` 时停止计时，即严格小于一半才计时 | 满足 |
| 每 10～15 秒生成 1～2 个 | 条件成立时采样 10～15 秒倒计时；到点生成 `min(随机1～2, 3−在场数)` 个，再重新采样 | 满足 |
| 同时最多 3 只 | 同上 | 满足 |
| 击杀 +2，与普通无色相同 | 配置 `reward = 2`，经原奖励路径受上限截断 | 满足 |
| 生成位置：玩家上方 160～240、水平 ±240、整个身体在边界内、不嵌入碰撞 | 32 次抽样，边界包含检查加胶囊碰撞查询，同批另做矩形重叠检查；全部失败则本轮不生成 | 满足 |
| 余额回升：停止新计时，已有实体保留 | 回升时 `remaining = -1`，不清除实体 | 满足 |
| 暂停、剧情、死亡菜单期间计时冻结 | `frozen()` 覆盖暂停、剧情锁、开场、对话与确认、加载与切房；冻结时实体停止漂移、不受击 | 满足 |
| 生命 13，不随日期变化；不攻击、不接触伤害、不占名额 | 见上 | 满足 |
| 不计入波次或胜利；结束、死亡、胜利、离开时无奖励清除 | 独立容器；`encounter_active()` 为假、玩家 `died`、`_exit_tree` 时清除且不发奖励 | 满足 |
| 与现有召唤物分开计数 | 不进入 `Enemies`、`OrdinaryEnemies`、Boss 支援容器 | 满足 |
| 不新增存档字段 | 实体与倒计时不保存 | 满足 |

## 独立复跑

环境：Godot 4.7.2.stable.official.ed1daf0bf；Python 3.12.14 + openpyxl 3.1.5；Git 2.56.0.windows.2；Node v24.19.0。

| 检查 | 命令 | 结果 |
| --- | --- | --- |
| G1 | `run_checks.py focused --godot-script res://tests/test_remnant_possibility.gd` | `REMNANT_POSSIBILITY_TESTS checks=269 failures=0`，退出码 0 |
| 变异 1：阈值改为“低于或等于 50%” | 临时把 `balance * 2 >= maximum` 改为 `>`，再跑 G1 | 269 项中 5 项失败，退出码 1 |
| 变异 2：误把堑壕加入白名单 | 临时在 `attach()` 白名单加入 `TrenchRoom`、`TrenchPassageRoom`，再跑 G1 | 269 项中 2 项失败，退出码 1 |
| G2 + G3 全量 | `run_checks.py full --jobs 4` | G2 预期 75、实际 75（导入、主场景、73 套件），引擎报告 73 行 `failures=0`、0 行非零失败、0 个错误/解析失败/泄漏/超时标记，含 `REMNANT_POSSIBILITY_TESTS checks=269 failures=0`、`INPUT_BINDINGS_TESTS checks=89 failures=0`；G3 81/81 + 37/37；退出码 0；sha=交付 SHA，dirty=false；UTC 18:23:07 至 18:33:56；engine.txt SHA256 `8dc3853ee08624ed33464b3fbb1464b565929b1f33ad50faa3f49c342eadcb26` |

两项变异检查后均以 `git restore` 还原，工作区干净。全量运行后两份 `.svg.import` 出现仅换行符变化，已还原，未提交。原始日志在审查工作区 `codexandclaude/runs/`，不入库。

交付记录中的预提交全量运行是在 sha=基线、dirty=true 的工作树上执行的，并给出 blob 对应；本次审查在干净的交付 SHA 上重新全量通过，结论一致。

## 非阻断观察

1. **玩家站在高处时可能长时间不生成。** 生成位置只取玩家上方 160～240 像素。测试在五场战斗中都把玩家放在地面（x=960、地板行），验证了生成成功并能填满 3 个名额；但没有覆盖玩家站在高处平台、头顶空间不足的情况。那时 32 次抽样可能全部越界或撞到顶板，本轮不生成，要等玩家换位置后的下一周期。这符合批准的规则（失败则下一周期重试，不穿墙），但可能让保底在某些站位下迟迟不出现。建议用户在 G4 时有意站到高处平台观察；如果体感明显，可以另起任务调整候选范围（例如上方空间不足时改为侧方或下方）。
2. **结束同一帧的击杀不发奖励。** `_on_defeated` 只在战斗仍进行且未冻结时发奖。如果玩家恰好在最后一个敌人倒下、战斗结束的同一帧击杀保底实体，这次 +2 不发放。影响极小，记录在此供参考。

## G4 与合并

用户在本分支（或审查 SHA）上，用新游戏的空存档槽（避免覆盖现有进度）进入至少一场批准的强制战斗：

1. 把可能性耗到当前上限一半以下，等待 10～15 秒，看到空中保底实体生成；击杀后可能性 +2。
2. 持续低资源时，同时最多 3 只；可能性回升到一半或以上后等待超过 15 秒，不再新生成，已有的仍保留。
3. 暂停后恢复，没有一次性补发；战斗结束或死亡时，保底实体消失且不额外加可能性。
4. （观察 1）站到高处平台上等待一段时间，留意是否长时间不生成。

G4 通过后，待用户授权，由集成者合并**本审查记录所在提交（审查 SHA）**；按 L 级要求，合并后在 master 跑 G2 + G3，并把用户验收结果记入任务目录。
