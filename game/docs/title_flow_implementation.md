# SYS-008 主界面流程与存档摘要

基于第五批规划合入后的 master。只新增流程和只读数据，正式主界面、存档选择及返回标题按钮分别由 UI-004、UI-005 接入。

## 会话接口

- `CheckpointLab` 及其子类在无会话启动时调用 `LifeUI.show_title()`。当前占位实现仅调用原有 `show_slots()`；现有 `checkpoint_reload` 读档与死亡重载路径不变。
- `return_to_title() -> bool`：正在重载时拒绝；没有会话时仅请求标题；有会话时先调用当前会话的虚方法 `save_current()`，失败返回 false，保留当前场景并显示原错误。成功返回 true，安排一次延迟场景重载；返回 true 表示已接受请求，不代表重载已完成。
- 重载使用现有主场景，释放旧玩家、房间、敌人、计时与剧情对象，以新实例进入 `slot=0`、`data={}` 的无会话状态。标题占位会暂停游戏。保存目录通过一次性的 `checkpoint_title` 元数据传递，进入新场景后立即移除，不会从临时目录落回正式存档。场景重载失败则恢复原暂停状态、清除重载标记并提示错误。
- 不改变死亡结算、最终战胜利/结束、最终战超时、探索超时或重试规则。它们调用同一接口；已通关仍不能继续（A-013）。`start_slot(slot, new_game)` 保持原样，重进从已保存检查点恢复。
- `slot_summaries() -> Array[Dictionary]`：按槽1～3返回独立数据；不以当前玩家状态替代磁盘内容。
- `has_any_save() -> bool`：任意槽不是 empty 即为 true，包括无法读取的已有存档；不会因此让损坏槽可继续。只剩 `.tmp` 不视为已提交存档，与现有读取规则一致。

## 摘要字段

| 字段 | 值域 / 含义 |
| --- | --- |
| slot | 1、2、3 |
| state | progress / completed / empty / unreadable |
| state_text | 进行中 / 已通关 / 空 / 无法读取 |
| day | 有效槽1～3；无可读数据为0 |
| day_progress | 0～1，按已保存当日余时与现有 DayClock 配置换算；旧档缺余时视为当日刚开始 |
| play_seconds | 已保存游玩秒数，未扣除剧情或菜单之外的额外时间 |
| health / max_health | 已保存生命 / 当前玩家生命配置的上限 |
| balance / maximum | 已保存可能性余额（可负）/ 上限 |
| pearls | 与 ExplorationSession 相同的四个永久珍珠事件计数 |
| checkpoint / checkpoint_name | 已保存ID / CheckpointConfig.display_name |
| used_backup | 主档不可读而使用可读备份时为 true |
| error | 槽无法读取时的现有错误文字；其他情况为空 |

空槽和无法读取槽的数值字段为0、检查点字段为空，max_health 仍来自当前配置；界面应按 state 绘制空/损坏样式，不把零值当角色数据。

`SlotSummaries` 用独立 `SlotStore` 调用原有只读加载，保留当前会话读取器的 last_error/used_backup。主档坏但备份可读时，状态与正常继续读取备份一致；两份都不可读才是 unreadable。不修复、轮换、删除或升级存档，也不读写 `.tmp`。检查点名字来自现有资源，珍珠只读现有事件；没有新增存档字段。

## 验证

`test_title_flow.gd` 使用系统缓存下本次独立目录及真实 FinalBattleSession：验证启动请求、五种返回状态、失败不离开、旧节点释放、目录传递、保存与重进，以及摘要四种状态/备份/版本错误、字节不变和诊断状态不变。所有夹具与文件清理仅作用于该隔离目录。G4由后续正式界面任务进行。
