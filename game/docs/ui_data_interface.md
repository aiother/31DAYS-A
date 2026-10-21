# UI 数据接口（SYS-005）

本接口只发布既有玩法与计时数据，不驱动 HUD，也不改变资源、计时、保存或输入规则。正式接入已由 UI-002 完成，见 [正式 HUD](formal_hud_implementation.md)。

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
