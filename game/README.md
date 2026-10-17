# 《末日前31天》V0.1 首个工程交付

首次交付：2026-10-14；本次更新：2026-10-17。基础玩家/战斗/AI、生命/可能性、闪避/恢复、检查点/分槽存档已接入；可游玩深谷起始区及瓦砾塔入口、Room2、Room3、连结处、渴望俯视Boss灰盒、黄金麦湖、麦秆镇救助/首次注视成长、沟壑入口、沟壑第二间救助、第三间清敌救助/珍珠、逃兵营帐外围、第二间多波次、寄生同伴者Boss飞行支援、战场外围路线及堑壕第一间（含单色实体与天人战士）、第二间落石通道与中心战场首段混战及10救场/协同测试，尚无正式美术。

**修订标记（2026-10-15，同日追加）**：下攻击弹起高度改为长按跳跃最大高度的50%，覆盖此前“原来的2倍”规则；取消攻击移动减速、跑攻前后摇各翻倍及连击按键间隔上限0.5秒（含边界）保留。同步修订仓库 `Words/` 中T1、T2及T3关联条目。

**修订标记（2026-10-16）**：敌人重/强力攻击、闪避、防御及格挡反击链不被普通命中打断；正常扣血与致死结算保留，原有闪避无敌不变。预留独立失衡打断接口，当前没有实装失衡值。详见 `docs/enemy_interrupt_revision.md`。

**本轮追加（2026-10-16，用户确认）**：中心战场首段混战及真实友军AI已交付；详见 `docs/battlefield_implementation.md`。友军击杀敌人正常奖励可能性，友军倒下无奖励。首段进度不写最终胜利，重试会重置。

**最新追加（2026-10-16，用户确认）**：中心战场10一次性救场与协同测试已交付。致命伤、两名友军均倒下、第二波兜底任一触发，冻结演出后清场、补满可能性但不回血；已保存救场在死亡/读档后不重播、不重复补满。详见 `docs/ten_rescue_implementation.md`。最终波次、时限及结局继续待下一轮。

**本轮缺陷修订（2026-10-16）**：修复救场清场与新波次衔接过快的问题。斩击后保留1.2秒空场并显示秒杀数量，再预警1秒，随后才生成新的协同敌人并显示入场卡片。真实按键流程已新增回归，详见 `docs/ten_rescue_implementation.md`。

**最新交付（2026-10-17，用户确认）**：10更快接敌、短突进、后摇追击、前后摇缩短。救场后接三波最终战、末波4名额外幸存者和3平台、持久计时、超时明确重试、胜利对话及临时结局。详见 `docs/final_battle_implementation.md`。

## 打开与运行

1. 使用 **Godot 4.7.2 Stable 标准版 Windows x64**。官方下载：https://godotengine.org/download/archive/4.7.2-stable/ 。无需 .NET、Spine 或其他插件。
2. 在 Godot 项目管理器选择“导入”，选择本文件同目录的 `project.godot`。等待初次导入完成。
3. 按 **F5** 运行主场景 `world/final_battle_session.tscn`，选择存档槽的新游戏并确认，或继续已有槽；前阶段`room_saves`存档直接兼容。新游戏先坠落、落地起身，再显示移动/跳跃引导。
4. 深谷向右进入瓦砾塔入口，继续道路进入Room2，向上攀登后进入Room3。Room3主路沿平台转向上层横臂；下层可选凹槽有珍珠和下攻击练习。靠近珍珠按E / RB拾取并保存，目前不强化属性。未拾取、零可能性也能走通主路；凹槽靠近左边缘后可普通跳跃离开。Room3上方进入HD_10003_1连结处：清敌后永久解锁返回，清敌后靠近开关按E / RB永久开启前路；前进进入HD_10004_1渴望俯视Boss区。入口自动记录检查点，首次登场后开始战斗；留意落击提示，借3层召唤平台跳跃攻击。击败后天窗开启，向上进入黄金麦湖，首次演出后与7进行临时剧情对话（E / RB推进、长按加速），完成后一次补满可能性并显示恢复提示。向右进入麦秆镇，靠近幸存者E / RB完成临时对话后免费救助，一次+4可能性；返回7完成结算后上限10→12，余额不补满。未救助时主动返回荒地须确认永久放弃，死亡/读档返回检查点不算主动放弃；救助完成后可往返。麦秆镇向右进入荒地巢都·沟壑入口，自动保存HD_20001_1_N001检查点。未救助离开田野同样须确认；完成7首见剧情后，入口事件将日期至少推进到第2日，不重复加天、不倒退。沿高台和右侧平台跳跃到上方出口；下方可练习下攻击，右上进入沟壑第二间HD_20001_2，沿三段平台找到幸存者，E / RB免费救助，一次+4；已有注视上限12→13，未获注视先记录、之后首次注视时补发+1。见到NPC后未救助主动离开须确认永久放弃，死亡/读档豁免；沿用沟壑入口检查点。第三间HD_20001_3复用无色实体，看到幸存者后清敌自动救助，一次+4及注视后+1上限；两位沟壑NPC均完成时为14。清敌后两端通路永久开启，清敌前可确认永久放弃本NPC并撤回。上层E / RB拾取独立珍珠占位，不强化属性。前往HD_20002_1逃兵营帐外围，跨高地/平台寻找独立珍珠占位；既有无色实体可重复击杀+2。营帐两端无清敌限制，沿用沟壑入口检查点；进入HD_20002_2，入口自动记录HD_20002_2_N001检查点；越过安全区开始3波2/2/3只无色实体，波间1秒、生成前预警0.6秒。两端可随时通行，往返/死亡/读档整场重置，击杀仍各+2，无通关额外奖励。进入HD_20003_1寄生同伴者监牢，入口自动检查点；首次登场后，左右/向上攻击弹反三连投射物，被实际命中会让Boss吸血。胜利后木板落下、两端永久开启并推进到第3日；闪避强化仅待领取标记。沿平台到上方破洞，寄生同伴者战斗约2秒后开始尝试召唤飞行无色实体，预警0.6秒、后续间隔6秒、最多存活2只，击杀各+2。胜利后进入NSZC_10001_1战场外围，主路跨高地通向堑壕；上层封闭能力门仍为占位，尚无NPC或挑战。继续进入NSZC_10002_1堑壕第一间，入口自动保存NSZC_10002_1_N002；沿六段平台上行，底层支路E / RB拾取珍珠占位。两只既有无色实体可重复击杀+2，另有地面和空中单色实体（紫色占位、21生命、击杀+7）。单色实体移动/冲刺更快，会闪避近身起手，并交替使用轻/强力攻击；紫红环形提示代表较长前摇。下层另有两只天人战士（31生命、击杀+11）；进入指定范围首次显示介绍卡片，期间可自由操作。天人使用2/3段连击、长重击、短瞬移与格挡反击；上下/背后攻击及重击后摇是反击机会。上方进入NSZC_10002_2堑壕第二间，自动记录NSZC_10002_2_N001检查点。清除2只单色/2只天人后永久开启返回路；沿折返平台上行，通过3列固定轮换落石通道（预警0.6秒、间隔1.4秒、伤害1，不可弹反），保留安全等待点，零/负资源也能走跳通过。通过状态和清敌状态都保存后，攻击两次打碎10生命碎石堆，保存后永久开前路；保存失败E / RB重试。落石击杀敌人也有正常可能性奖励；继续进入NSZC_10003_1中心战场，向右越过入口安全区开战：2天人+1单色；首名天人阵亡后两批各1名绿色幸存者加入（10生命、每击5伤害），可被击败，无友伤。首段首次危机触发10救场；若未遇危机，首段清空后第二波兜底触发。10从天而降、临时对话后全屏清场并补满可能性，不回血；演出保存失败E/RB重试。之后与10完成三波2天人+1单色、3天人+1单色、4天人+2单色最终战；每波两批幸存者支援，末波额外4名与3平台。计时取15分钟与第三日剩余较小值，死亡/读档不回补，超时须明确确认重试。最终胜利保存后开返回路，靠近10按E/RB执行临时胜利对话与占位结局；结束屏可选槽或退出。死亡仍回堑壕第二间检查点，重入重置三波但不重复救场或补满。
5. 起始检查点使用HD_10001_1_N003，出生/引导完成后保存，不因读档或死亡重播。主场景R不重置存档；重新开始须在Esc的存档槽中确认新游戏。F6运行 `debug/checkpoint_lab.tscn` 或 `debug/enemy_lab.tscn` 仍可测试无色实体战斗。
6. 开场生命3/5，敌人攻击扣1。死亡倒地1秒、转黑，再选择“从检查点继续”：满生命5/5、可能性减半向下取整（负数清零）、敌人重置、保护3秒，主动攻击不解除保护。正常保存退出再继续则保留资源、从最近检查点进入、无保护。Esc可暂停/设置/选槽/确认保存退出，窗口关闭同样确认。

工程以1920×1080为基准、保持16:9，开发窗口1280×720，Compatibility渲染，目标60 FPS、物理60 Hz。实际帧率仍取决于机器性能。

## 操作

| 行为 | 键鼠 | 手柄（Godot标准布局） | 状态 |
| --- | --- | --- | --- |
| 左右移动 | A/D、左右方向键 | 左摇杆、十字键 | 已实现 |
| 跑步 | 按住Shift | 按住LB | 已实现 |
| 跳跃 | 空格，长按跳得更高 | A/底部面键 | 已实现 |
| 重置测试场地 | R | 未映射 | 原独立开发场景使用；存档主场景提示通过选槽确认新游戏 |
| 全屏切换 | F11 | 未映射 | 已实现 |
| 上/下攻击方向 | W/S、上下方向键 | 左摇杆、十字键 | 已实现，下攻击仅空中 |
| 攻击 | J、鼠标左键 | X/左侧面键 | 已实现，连续单击两段循环 |
| 闪避 | K | B/右侧面键 | 地面/空中左右，共用最多三连，成本1/2/3 |
| 恢复 | L | Y/上方面键 | 长按2.8秒，消耗3可能性恢复2HP |
| 互动 | E | RB | Room3珍珠拾取、连结处开关、与7交谈/推进对话 |
| 使用道具 | Q | Back/View | 仅InputMap |
| 暂停 | Esc | Start/Menu | 已实现，冻结物理/计时；设置音量、窗口尺寸及全屏 |

手柄映射已配置，实际硬件未进行人工试玩验收。攻击必须单击，不因持续按住自动连续出手。

## 已实现

- Typed GDScript `CharacterBody2D`：行走/跑步、加速与减速、短暂转向前摇。
- 空中反向：保留惯性，先减速再向新方向加速。
- 一次基础跳跃；按键保持降低上升重力、松键截断上升速度；下落重力加速与终端速度限制。未实现二段跳。
- 平台边缘容错：距离不超过32px（96px占位角色视觉高度的1/3），并限制最长0.12秒，防止停留空中后再跳。
- 普通落地压缩/恢复与线条反馈；高空落地增加0.44秒操作硬直，视觉缩放不影响碰撞体。
- 物理胶囊高度88px、脚底仍为角色原点；为96px高的最低平台通道留出8px顶部余量，避免跑步撞住平台底角。占位视觉与未来受击框仍保持96px。
- `MovementConfig` Resource 与 `.tres` 数据，独立视觉层占位 `Sprite2D`。
- 有碰撞的 `TileMapLayer` 地面，模块化平台 `PackedScene`、场地边界、受限动态跟随镜头。
- 基础攻击：两段循环，各5伤害；第二段击退更强、后摇更长；【2026-10-15修订】相邻按键间隔不超过0.5秒才能衔接第二段，按键时刻计算，输入缓冲不延长窗口；超时或非攻击中起跳重置。攻击中起跳保留连击记录。
- 左右/向上/空中向下攻击；单次方向锁定，转身不改变已出手攻击。【2026-10-15追加修订】攻击保持正常行走/跑步速度，攻击前摇、判定和后摇中均可跳跃，跳跃不打断攻击或重置计时/命中记录。发动时按住跑步且有水平输入，前摇0.08→0.16秒；第一段后摇0.14→0.28秒、第二段0.28→0.56秒，活跃判定时间不变。倍率按出招锁定，松开跑步不缩短本次后摇。
- 活跃判定阶段查询Hitbox形状；前摇/后摇不伤害，每次动作对每个目标仅结算一次，可同时命中多个目标。
- 下攻击落空不改变下落；【2026-10-15追加修订】命中后弹起高度为长按跳跃最大高度的50%，一次动作最多弹起一次；按住/松开跳跃不改变弹起高度。根据当前跳跃参数计算最大跳高，再按目标高度和物理步长反推弹起速度；后续调整跳跃参数会同步调整弹起，顶部碰撞仍可阻挡。
- 占位攻击范围颜色、受击闪白/击退反馈与短促命中音；CombatHurtbox已连接无色实体生命与受击状态。
- 无色实体13生命、慢速感知/追击、近战/投掷、攻击前摇提示、受击打断/击退、死亡碎块及一次+2实际可能性。地面/空中均使用同种实体。
- 【2026-10-15前摇调校】敌人近战与远程前摇由0.65秒缩短1/3至约0.433秒，判定时长与后摇不变。
- 【2026-10-15 AI修复】地面混合型实体在投掷冷却期间主动接近，进入近战范围就出招，不再等待玩家攻击阶段结束。纯远程配置节奏保持；血量旁显示近战/投掷等当前行为，方便观察。补充实际默认参数下“400px外接近并近战”的回归。
- 左右/向上攻击反弹非子弹投掷物，反弹伤害5；投掷物不穿墙、单次反弹，反弹后不再伤玩家。
- 敌方攻击名额与尸体上限，灰盒暂为1与6。参数和阶段边界详见 `docs/colorless_implementation.md`。
- 玩家生命/受击/死亡：上限5、初始3；受击硬直与保护、轻微击退、被动打断攻击、零生命停止操作、倒地/转黑/死亡菜单、满血重新挑战与3秒保护。独立Life Resource提供数据，反馈与物理分离。
- 攻击以物理查询进行判定；敌人场景启用玩家Hurtbox实际扣血。生命数字、低血色、受击/保护闪烁及死亡界面已接入；互动包括珍珠占位拾取和连结处开关。
- Windows x64导出预设、Git/LFS规则、工程目录与可重复验证脚本。
- 自动检查点、三槽本地版本化JSON存档、资源自动保存、正常载入与死亡资源结算、临时敌人重载、保存退出确认、损坏备份回退与写入错误提示。详见 `docs/checkpoint_implementation.md`。
- 首个Room模块化PackedScene、TileMapLayer平地、正式出生/引导/检查点Node、一次性坠落起身演出、相邻目标裂缝检测与阶段结束反馈。详见 `docs/start_room_implementation.md`。
- 双Room资源预加载、双向普通连接、当前实例卸载/替换、瓦砾塔平台地形、无色实体首次介绍与入口检查点。重置敌人后再次击杀仍获得+2，允许往返补充可能性。详见 `docs/two_room_implementation.md`。
- 瓦砾塔Room2垂直平台路线、断壁、既有近战/远程敌人压力、入口返程和上方阶段边界；六段普通跳跃已验证。按用户确认沿用入口检查点。详见 `docs/tower_room_implementation.md`。
- Room3探索/战斗路线、下攻击支路、E/RB拾取并保存的珍珠占位，写盘失败回滚、往返/死亡/读档不重拾。无属性强化、无未定机关；沿用入口检查点。详见 `docs/exploration_room_implementation.md`。

- 连结处HD_10003_1狭窄平台与既有无色实体、清敌解锁返回、E/RB开启前路、两条通路永久持久化；写盘失败回滚，敌人重置仍重复奖励+2。沿用入口检查点。详见 `docs/connection_room_implementation.md`。

- 渴望俯视60生命灰盒、首次高空镜头/登场名片、入口检查点、纵跳落击/高空悬停、3层召唤平台、永久胜利/天窗/通路和成长待领取标记。Boss无血条；死亡重试不重复演出，同时死亡优先保留Boss胜利。详见 `docs/overlook_boss_implementation.md`。
- 【2026-10-15节奏修订】Boss后摇0.45秒、悬停4秒、升空速度900；悬停时预警0.6秒召唤无色实体，同时存活上限2只，击杀仍+2。玩家死亡/Boss击败清理召唤物和投掷物，不额外发奖。

- 黄金麦湖平地、麦田/7视觉占位、一次性首见剧情及补满可能性、自由恢复教程、逐字对话/长按加速/暂停接续、主动返回荒地的永久放弃确认，死亡与读档豁免。详见 `docs/field_room_implementation.md`。

- 麦秆镇免费救助、一次性+4可能性、返回7的金色微光结算与首次上限10→12、运行时/存档上限隔离和一致性验证。详见 `docs/town_rescue_implementation.md`。

- 沟壑入口HD_20001_1平台/下攻击灰盒路线、既有无色实体、正式入口检查点、HUD日期与剧情完成后至少第2日的持久事件。旧槽默认第1日，写盘失败回滚、往返/死亡/读档不重复推进。详见 `docs/ravine_day_implementation.md`。

- 沟壑第二间HD_20001_2上层幸存者救助，一次+4及后续上限+1；未获注视时延迟成长，实际离开永久失败确认与任务隔离。详见 `docs/ravine_rescue_implementation.md`。

- 沟壑第三间HD_20001_3清敌永久开启两端通路、自动救助独立NPC和第二次后续上限成长、珍珠占位保存及确认放弃撤回。详见 `docs/ravine_depth_implementation.md`。

- 逃兵营帐外围HD_20002_1高低差与平台探索、三只既有无色实体、独立珍珠占位及无条件双向道路。详见 `docs/camp_room_implementation.md`。

- 逃兵营帐第二间HD_20002_2三波战斗、预警/波间暂停、正式入口检查点、自由撤退及往返/死亡/读档整场重置。详见 `docs/camp_waves_implementation.md`。

- 寄生同伴者HD_20003_1登场、80生命/三连可弹反投射物/实际命中吸血、入口检查点、持久胜利/通路及第3日事件、闪避强化待领取。详见 `docs/parasite_boss_implementation.md`。

- 寄生同伴者飞行支援、真实击杀+2、数量限制与无奖清理，详见 `docs/parasite_support_implementation.md`。
- 战场外围NSZC_10001_1主路/上层平台、既有无色实体与实体封闭能力门占位，详见 `docs/outskirts_implementation.md`。

- 堑壕第一间NSZC_10002_1纵向六段平台、无色实体、独立珍珠占位及正式检查点，详见 `docs/trench_implementation.md`。

- 单色实体地面/空中AI及堑壕第一间集成：快速移动/短冲刺、地面跳跃、轻/强力近战与投掷物、可见攻击闪避及低血量更高闪避频率，详见 `docs/monochrome_implementation.md`。

- 天人战士AI及堑壕第一间首见：2/3连击、长重击、投掷、冲刺/安全瞬移、格挡反击和共享名额夹击；首次介绍不锁操作且永久保存，详见 `docs/tian_implementation.md`。

- 堑壕第二间NSZC_10002_2：正式检查点、4只已实现敌人、清敌返路、真实落石挑战及可打碎永久前路，详见 `docs/trench_passage_implementation.md`。

## 尚未实现

已接入寄生同伴者飞行支援和战场外围路线，后续独立NPC成长仍至14；NSZC_10003_1中心战场已开放首段混战，完整战斗仍为阶段边界。两个Boss强化奖励仍仅记录待领取，不修改属性。

当前尚未实现外围特殊挑战/门内NPC、其他Room的单色/天人配置、沟壑陷阱/机关、正式Boss强化、第一、二日自然半小时计时/超时结算、其他救助NPC与15上限成长、完整背包或Room3珍珠强化/未定机关。日期由已确认事件推进；本轮新增第三日剩余及最终战计时，第一、二日自然倒计时尚未实现。已放置八个正式检查点，Room2/Room3/连结处沿用瓦砾塔入口检查点，渴望俯视使用HD_10004_1_N003，黄金麦湖/麦秆镇沿用此检查点，沟壑入口使用HD_20001_1_N001，营帐第二间使用HD_20002_2_N001，寄生同伴者使用HD_20003_1_N003，堑壕第一间使用NSZC_10002_1_N002，第二间使用NSZC_10002_2_N001。旧攻击场景橙色目标仍是开发装置。高空落地仅反馈/硬直，未自动施加坠落伤害。移动引导未来美术化并放画面中上部，文字仍是占位。设置仅当前进程保持，不写入存档。

正式Room存档在Godot用户数据目录的`room_saves/`；此前测试场地的`saves/`原样保留，可通过F6运行`debug/checkpoint_lab.tscn`继续。两类槽独立，不自动转换，不包含在工程包。

可能性初始3、基础上限10；首次救助后返回7结算提高至12，两位沟壑NPC各有效帮助提高1，均完成后至14；提前帮助会在首次注视结算时补发对应+1。透支下界仍为-9。地面/空中左右闪避共用连闪计数，从上次发动计时1.3秒后重置，跨越-9时拒绝发动。空中闪避保留竖直速度并继续重力、松键截断，不重置跳跃；落地仍正常反馈与硬直。资源不足滑步前摇更长、无敌更短。恢复开始扣费，松键、受击或滑步取消均不退款；完成前不回血，满血或资源不足3不能启动。具体灰盒调校值在PossibilityConfig中。死亡结算在HP归零时自动保存一次，避免退出重进规避损失；不是取回检查点的旧余额。

Spine Professional与官方spine-godot尚未集成，不含商业授权或运行时二进制。后续只替换 `VisualRoot` 子树并锁定编辑器/导出数据/runtime/Godot的兼容组合。物理、位置、状态和Hitbox/Hurtbox继续由Godot控制。

## 调校与结构

`player/movement_config.gd`中的默认速度、重力、保持时长和硬直均为**首轮灰盒参数**，不声称已获最终手感验收。`data/player/graybox_movement.tres`可在Inspector中覆盖。`data/combat/graybox_attack.tres`配置攻击；5伤害来自T3冻结值；2026-10-15确认连击按键间隔0.5秒、跑攻时长倍率2，并追加确认弹起为最大跳高的50%，配置字段为 `down_bounce_jump_height_ratio = 0.5`。其他范围与击退仍为灰盒调校参数。正式冻结依据见仓库 `Words/` 的T0–T5.4与已填写T6/T7，以及本次T8技术基线。

```text
Player (CharacterBody2D)
├── BodyCollision
├── GameplayRoot
│   ├── Combat（Typed GDScript攻击状态与结算）
│   ├── Life（生命、受击保护、死亡时序）
│   ├── Possibility（资源、地面滑步、恢复）
│   ├── Hitbox（活跃阶段由物理查询读取形状）
│   ├── Hurtbox（敌人灰盒中启用，带保护判断）
│   └── InteractionArea（禁用）
└── VisualRoot
    └── PlaceholderSprite → 后续Spine视觉
```

角色视觉、物理体、战斗判定独立配置。不要把视觉缩放、骨骼位移用作物理移动，不要用Sprite朝向决定已经发动的攻击方向。

## 验证与导出

实际验证使用 `4.7.2.stable.official.ed1daf0bf`。验证脚本覆盖编辑器导入、主场景180帧、玩家物理、基础战斗及本次战斗修订：连击0.5秒边界、跑攻两段前后摇倍率、全速移动、松键不缩短后摇、弹起高度及跳跃键独立性；同时回归最低平台卡顿和0.44秒落地硬直。最终结果与检查数量见随包 `verification/engine_validation.txt`。手感与实际手柄仍需制作人试玩。

在仓库根目录执行：

```powershell
python scripts/verify_game.py --godot "完整路径/Godot_v4.7.2-stable_win64_console.exe"
python -X utf8 -m unittest discover -s tests -v
```

Python策划表回归测试需要openpyxl及现有工作簿生成器使用的artifact-tool环境；Godot项目运行与物理/战斗测试不需要Python依赖。独立工程可直接执行：

```powershell
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --editor --import --quit
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_player.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_combat.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_combat_revision.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_colorless.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_player_life.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_enemy_melee_approach.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_possibility.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_air_actions.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_slot_store.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_checkpoints.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_start_room.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_two_rooms.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_tower_room.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_exploration_room.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_connection_room.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_overlook_boss.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_boss_pressure.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_field_room.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_town_rescue.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_ravine_day.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_ravine_rescue.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_ravine_depth.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_camp_room.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_camp_waves.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_parasite_boss.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_parasite_support.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_outskirts.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_trench.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_monochrome.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_monochrome_room.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_tian.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_tian_room.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_rockfall.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_trench_passage.gd
& "完整路径/Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/test_enemy_interrupts.gd
```

导出独立exe需先安装同版本Godot Export Templates，再选择Windows x64预设。本次交付工程压缩包，不声称已验证exe导出。引擎下载供本地验证，未包含在压缩包中。

## Git / LFS

仓库本地LFS已启用；PNG/JPG、WAV/OGG、PSD、Spine源文件与skel进入LFS，脚本/场景/Resource/SVG为文本。当前占位资源均为文本SVG，因此LFS尚无二进制对象。未配置远程仓库或推送。

独立压缩包包含 `.gitignore`、`.gitattributes` 和 `31days-v0.1.bundle`（完整可追溯提交）。恢复完整仓库：`git clone 31days-v0.1.bundle 31days`，然后在新仓库执行 `git lfs install --local`，导入其 `game/project.godot`。压缩包的 `game/` 同样可以直接导入。

中心战场专项回归：`--script res://tests/test_battlefield.gd`，覆盖真实双向伤害、两批增援、索敌、无友伤、存档失败重试、检查点和死亡重置。

10救场专项：`--script res://tests/test_ten_rescue.gd`；旧首段 `world/battlefield_session.tscn` 保留作独立回归，F5以本轮主入口为准。

清场展示回归：`--script res://tests/test_ten_clear_presentation.gd`，通过真实交互按键确认旧敌全灭、空场停顿和新一波入场时序。

最终战最新流程：三波清空→10对话→临时结局→结束屏。旧独立救场场景仍保留，F5以final_battle_session为准。新增专项：test_ten_mobility.gd、test_final_clock.gd、test_final_battle.gd、test_final_retry.gd。
