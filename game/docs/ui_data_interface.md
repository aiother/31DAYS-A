# UI 数据接口（SYS-005、SYS-009）

本接口发布既有玩法与计时数据，不驱动 HUD，也不改变资源、计时或保存规则。SYS-009 按用户批准补齐普通对话的场景交互门禁，范围见后文。正式接入已由 UI-002 完成，见 [正式 HUD](formal_hud_implementation.md)。

## 玩家可能性

`player.possibility` 保留 `balance_changed(current, maximum)`，新增：

- `shortfall(kind: ShortfallKind)`：`HEAL=0`、`DODGE=1`。通过其他恢复资格检查且未满血，余额严格小于恢复成本时发一次 HEAL；成功执行的透支闪避发一次 DODGE。SYS-006 按用户决定补充：通过控制、落地硬直、动作状态和连闪次数检查后，若本次闪避会使 `balance - cost < floor_balance`，拒绝时也发一次 DODGE，但仍返回 false，不扣费、不进入闪避、不发 balance_changed。刚好到达下限仍可执行；余额等于成本不发不足信号。空中、硬直、控制锁、满血、动作忙碌等拒绝恢复的路径不发；不能控制、落地硬直、正处于闪避中或一串已闪满三次而拒绝的闪避也不发，连闪上限优先于余额不足。闪避沿用 `is_action_just_pressed` 调用路径，长按只在按下帧尝试一次，松开再按才是新的尝试。
- `gained(amount, source_world_position)`：每次实际入账的正数量，不是未经上限裁剪的请求量。满额、非正请求、死亡后不发。负余额还债也算获得。
- `gain(amount, source_world_position = Vector2.INF)`：旧单参数调用兼容。调用方知道来源时可提供世界坐标；未知（包括现有只传奖励数量的敌人转发链）默认玩家的 `global_position`。`Vector2.ZERO` 是有效显式坐标，`Vector2.INF` 仅作省略参数标记。

信号不替代原来的返回值或 balance_changed，不额外收费、退款或发奖励。读取现有 balance、maximum、life.health 等状态的方式不变。

## 正式会话计时

`FinalBattleSession.day_changed(day)` 在新会话恢复有效快照时发布一次当前日期，之后日期实际变化时发布一次。自然换日与剧情推进沿用现有播报入口；同日期不会因后续 process 帧重复发布。读档、换槽和死亡重载会创建新会话，因此新实例发布一次恢复的当前日期，旧实例不重放过期日期。订阅者在会话加入树、ready 前连接；晚连接时可先读取下面的快照。不把数据恢复信号当作必须播放换日动画的指令。

`FinalBattleSession.ui_time_state()` 每次返回独立字典，只读取 DayClock、FinalClock 的现有 data 与会话内的演出历史，不 normalize、tick、保存或发信号。

| 键 | 含义 |
| --- | --- |
| has_session | 已选择有效槽 |
| day | 当前日期；未选择槽时为0 |
| day_remaining | DayClock.remaining 的当前日剩余秒数；未选槽为0 |
| day_progress | `clamp(1 - day_remaining / DayClock.CONFIG.day_seconds, 0, 1)`；未选槽为0 |
| day_warning | 第1或第2日剩余严格大于0且不超过180秒；第3日不虚构第4日预告 |
| day_warning_remaining | 预告有效时的真实剩余，否则0 |
| final_started | 已保存最终战启动事件 |
| final_active | 已启动且未胜利、未最终战超时、未结局完成；暂停时仍表示处于该战斗，不表示时钟正在走 |
| final_remaining | 已启动时的真实 final_remaining，未启动为0；无加速演出数值 |
| final_start_known | 本会话是否成功捕获了开战瞬间的第3日余额 |
| final_start_day3_remaining | 成功保存开战后捕获的精确余额；不可知时为-1，不用当前余额猜测历史 |
| final_acceleration | 最终战有效且已知开战余额严格大于900秒，允许 UI 选择加速演出；不是演出进度或新的计时器 |

用户在 SYS-005 实施会话中明确选择：开战时精确提供历史余额；读档后标记未知，不重播加速演出。历史只在内存，未新增存档字段。读档、死亡重载、换槽或重试恢复会清除该历史，但现有真实 final_remaining 照常提供。UI 可以自行一次性消费演出条件，演出不得影响时钟；预算不足900或恰好900均不加速。

暂停、剧情等是否扣时仍由现有 `_clock_tick()` 决定；接口本身不推进时间。无 UI、输入映射、数值、资源配置或存档版本变化。

## 回归

新增 `game/tests/test_ui_data.gd` 首行按 ENV-004 登记。用真实输入、生产敌人击杀转发、自然物理帧换日、真实槽读档/死亡场景重载、最终战 Room 自动开战覆盖接口；既有玩家、LifeUI、日期、存档与最终战套件保持原样。

## 任务与获得（SYS-009）

会话基类 `CheckpointLab` 提供 `quest_state()`、`quest_changed(kind, state)`、`item_obtained(kind, display_name)`。正式会话沿用四个已有救助的永久事件与 WorldDayRules，不增加存档字段。查询不写盘、不 normalize、不发信号，返回可由调用方修改的独立字典。

`quest_state()` 的字段为 `id`（救助所属 Room ID）、`title`（救助）、`objective`（与当前 `quest_status_text()` 完全相同的文字）、`state`（无、进行中、已完成、已放弃、已过期）。未选槽为空 id/title/objective、state=无。沟壑救助、沟壑深处、外围各在自己的 Room 展示对应任务；其余 Room 沿用原有 7 的救助/结算目标。尚未见到任务时可能已有提示文字，但 state=无；7 的救助由恢复指引开始，其余由原有 seen 事件开始。完成/放弃/过期的优先顺序与原有有效事件和期限一致。

变化比较按任务 ID 保存内存快照，包含目标文字，Room 切换不把另一个任务误当新开始。`kind` 为开始、进展、完成、放弃、过期；状态枚举不变但目标确实变化时发进展（例如救助完成后返回 7 结算），不重复完成。成功保存后与普通 process 帧检查变化：后者也涵盖原有只在内存标记 seen 的路径。相同快照不发。恢复全过程及其结束时建立基准，不补发历史变化；UI 初次连接或读档后应先读 `quest_state()`，之后监听信号。信号携带独立快照，不能反向修改会话。

`item_obtained` 从上次成功落盘快照与本次成功写入数据比较永久来源，kind 为珍珠、拾取、药包、成长；display_name 取实际拾取配置或对应成长名。覆盖四颗珍珠、当前 Room 中配置的普通拾取、四处自动药包、战斗/闪避强化及其旧档补领、7 的注视与延后结算的救助成长。资源击杀入账仍监听原来的 `gained`，不伪装成物品。失败写入不发、不推进基准；重试成功后只发一次。写盘成功后 deferred 发布，保证外层会话已同步成长；若期间恢复了另一份会话，旧 epoch 的通知丢弃。读档已拥有的东西不重播；旧档首次成功补领是本次实际获得，正常发布。

## 场景交互查询（SYS-009）

`interaction_targets() -> Array[Dictionary]` 返回当前 Room 的 E/RB 场景对象及现有保存重试。字段：

| 字段 | 含义 |
| --- | --- |
| id | 稳定的永久事件键、检查点 ID 或 Room/对象标识 |
| kind / action | 拾取、交谈、开关、检查点、补领、重试及其显示动作 |
| position | 世界坐标 Vector2；无距离限制的重试以玩家当前位置为显示锚点，不表示范围中心 |
| radius | 原有圆形距离阈值；unlimited / area 为 null，不以近似圆替代 |
| range_kind | circle / unlimited / area |
| in_range | 原始距离或区域判定；unlimited 为 true。外围 NPC 的原 near 判定还要求尖刺已关闭，保留此条件 |
| bounds | 仅 area：真实矩形碰撞形状变换到世界的 Rect2；in_range 仍直接调用 WorldRoom 的玩家矩形重叠判定 |
| available | 当前正常场景交互可用；沿用实际动作的控制、动作忙碌、清敌、永久事件及输入分支优先级，不承诺磁盘一定能写入 |
| key_item | keyitem 拾取、关键通路或成长重试的高亮标记 |
| retry_available | 仅特定剧情结算锁中的保存重试：与正常对象 available 分开，保留原始 E/RB 保存重试路径 |

用户在 SYS-009 会话中批准两项解释：“采用原始范围类型（推荐）”；“允许补齐对话门禁（推荐）”。普通物件保留原半径；Boss 补领等无距离限制，天人介绍重试沿用 Area2D 和玩家矩形重叠。普通场景 E/RB 与查询增加同一普通对话门禁；对话推进、剧情结算失败后的保存重试不受该门禁阻断，数值与剧情保存规则不变。暂停、普通对话、剧情控制锁中正常对象 available=false。最终战开战保存、结局保存、10 救场保存、尖刺挑战保存等原有结算重试单列 retry_available，避免把故意锁住玩家的保存重试删掉。

拾取及开关按身体中心（世界位置向上44），NPC/检查点沿用脚部坐标；没有统一到一种坐标。拾取沿用环境开关优先、随后第一个可拾取物；补领沿用外层闪避强化优先于战斗强化的返回顺序。已经取得的拾取不再返回；已操作开关、已记录检查点可保留条目但不可用。自动药包、自动检查点触发区、自动遭遇、普通出入口并非 E/RB 对象，不虚构一个按键提示；药包的实际获得仍有获得信号。

回归：首行登记的 `test_quest_interactions.gd` 使用真实 FinalBattleSession、独立临时槽及原有动作与持久化路径；无正式 UI 改动。旧断言未改。
