# SYS-009 审查记录

审查者：Claude｜日期：2026-10-22｜结论：**通过**（无阻断项；2 条非阻断建议）

## 固定对象

- 基线：`2f79b8311155826301509c0cb6c26691f4a1e2c9`
- 实现：`ba6fae3ed1f129e6c89e2a70739b94901c57f755`（含 `ef560f0`）
- 交付／被审 SHA：`2ef06d02cc20b465d350d68fa808c2798a841a91`；审查分支 `claude/SYS-009-review` 只新增本记录。

## 范围

`game/debug/checkpoint_lab.gd`、`game/world/` 下 17 个会话脚本与 `items/room_pickup.gd`、新套件 `test_quest_interactions.gd`（含 `.uid`）、`game/docs/ui_data_interface.md`、任务卡首部与交付记录，均在任务卡允许范围内。未改正式 UI、LifeUI、输入映射、`project.godot`、存档字段 / 格式、数值或救助与计时规则；旧测试与断言未改。

## 偏离任务卡的两处（用户在实施中批准）

1. **范围类型**：任务卡写 `radius`（与现有判定一致的范围）。Boss 成长补领没有距离限制、天人介绍重试是 Area2D 重叠，无法用一个半径准确表达。用户选“采用原始范围类型”：圆形保留 `radius`，另两种 `radius=null` 并增加 `range_kind`（circle / unlimited / area）、`in_range`，区域另给世界 `bounds`。对 UI-007 更好用：提示可按 `in_range` 判断，不必自己算距离。
2. **对话门禁**：任务卡要求“不改交互规则”。现有 E / RB 路径并未统一阻止普通对话期间的场景动作，用户选“允许补齐对话门禁”：普通场景动作与查询在普通对话中都不可用；对话推进、剧情结算失败后的保存重试仍走原路径（单列 `retry_available`）。这是用户批准的规则补齐，已写入 `ui_data_interface.md` 并有回归（下方变异 2）。

## 要求逐条核对

| 要求 | 结果 |
| --- | --- |
| 1 `quest_state()` | 成立。`id / title / objective / state`；`objective` 与 `quest_status_text()` 同源；四个救助状态取自原永久事件与 WorldDayRules，优先级与原规则一致 |
| 2 `quest_changed(kind, state)` | 成立。按任务 ID 保存内存快照，状态与目标不变不发；读档期间与读档结束时只建基准、不补发；同枚举仅目标变化发“进展” |
| 3 `item_obtained(kind, display_name)` | 成立。以上次**成功写盘**快照与本次写入比较，写盘失败不发也不推进基准；deferred 发出，外层成长同步后才通知；读档已有物不重播，换会话的旧通知按 epoch 丢弃 |
| 4 `interaction_targets()` | 成立。各会话沿继承链追加对象；拾取、NPC、开关、检查点、补领等与实际动作共用抽出的谓词（如 `_can_pickup`、`_can_seven`），范围、坐标基点、分支优先级沿用原判定；`available` 在暂停、普通对话、剧情控制锁中为假 |
| 5 无新存档字段、不改规则 | 成立（除上面经用户批准的对话门禁） |

## 独立检查（与 ENV-007 一起）

- **合并预演**：detached 于 `2ef06d0`，`git merge --no-ff b9b6d13`（ENV-007 交付）得临时提交 `14982a5`，无冲突；不推送、不作合入目标。
- **完整门禁**：在 `14982a5`、起点 dirty=false 执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：G2 **89/89**、G3 **108/108 + 67/67**，passed=true，**content_stable=True**（ENV-007 生效）；`engine.txt` 中 ObjectDB 泄漏 0 处。摘要 `codexandclaude/runs/20261022T072826.385996Z/`（不入库）。
- **变异**（临时改源文件跑 `test_quest_interactions.gd --fixed-fps 60`，按原字节恢复）：

| 变异 | 结果 |
| --- | --- |
| 任务状态未变也发 `quest_changed` | 316 项中 12 项失败，退出 1 |
| 去掉麦秆镇会话的对话门禁 | 282 项中 6 项失败，退出 1 |
| 获得信号被丢弃（epoch 不匹配） | 316 项中 13 项失败，退出 1 |

恢复后 316/0。

工具：Godot 4.7.2 stable（控制台版）、Codex 自带 Python 3.12.14 / openpyxl 3.1.5、Git 2.56.0.windows.2。

## 非阻断建议

1. `_publish_quest_changes()` 每帧调用一次 `_quest_records()`（四个救助的字典比较）。目前开销很小；以后任务变多时可改为只在事件写入、换房与换日时检查。
2. 给 UI-007 的说明（Claude 侧自用）：`position` 是世界坐标，需经相机换成屏幕坐标；`unlimited` 的 `position` 是玩家位置，只作显示锚点；补领等 `retry_available` 条目不应显示普通交互提示。

## 结论

通过。可按 `2ef06d0` 合入 master；与 ENV-007 合入顺序不限，无冲突。合入后两项的 full 证据可复用（ENV-007 已使内容稳定）。
