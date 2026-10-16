# T8 技术开发基线（工程实施）

2026-10-14：按用户已确认冻结方案实施。Godot **4.7.2 Stable**；Typed GDScript；Windows PC x64；1920×1080 / 16:9；Compatibility；目标60 FPS、物理60 Hz；Git与Git LFS。

角色物理由CharacterBody2D控制，战斗由Godot Hitbox/Hurtbox控制；Spine仅管Visual。未来采用Spine Professional与官方spine-godot GDExtension，并成对锁定Godot/Runtime及Spine导出数据版本。本次无Spine依赖，使用Sprite2D占位。

地图技术采用TileMapLayer + 模块化PackedScene；本次只交付debug测试场地。Room动态加载/相邻预加载、Resource数据驱动的其他模块、本地分槽版本化存档、关键逐帧AnimatedSprite2D、2D粒子/Shader在后续冻结开发序列接入。不得将空目录计为已实现系统。

开发顺序：工程初始化 → 玩家灰盒 → 基础战斗 → 无色实体 → 生命/死亡 → 可能性/地面滑步/恢复 → 检查点 → 第一个灰盒Room。

本次范围仅前两项与后续结构预留，不新增系统、角色、正式地图。T0–T7原有规则保持；参数未冻结的部分在Resource中标为灰盒调校值。首轮代码与文档、测试逐次提交Git。

实施进度追加（2026-10-15）：基础攻击及无色实体AI/攻击已接入开发场景，具体见`colorless_implementation.md`；未新增敌人种类或正式地图。下一阶段为玩家生命/死亡。上段“仅前两项”记录首次交付范围。

同日实施进度追加：玩家生命/受击/死亡闭环已接入，详见`player_life_implementation.md`。重新挑战暂用灰盒出生点，不代表正式检查点/存档已实现。下一阶段为可能性/地面滑步/恢复。

同日实施进度追加：可能性收益/透支、地面左右滑步、长按恢复已接入，详见`possibility_implementation.md`。下一阶段为检查点；正式死亡资源结算尚未接入。

同日操作追加修订：按制作人指示开放攻击中跳跃与空中左右闪避。跳跃不打断攻击或重置连击；空中闪避与地面共用资源/连闪规则，保留重力，不重置跳跃。此条覆盖此前仅地面闪避限制；未增加地图或其他系统。

同日检查点阶段追加：主场景更新为`debug/checkpoint_lab.tscn`，在同一灰盒场地放置两面开发检查点旗，通过Resource配置；提供三个本地版本化JSON槽、自动保存、正常载入和死亡结算。用户确认死亡可能性50%向下取整；正常退出保留资源，死亡复活满血及3秒保护。真实地图、NPC/时间/成长持久化未实现，细则见`checkpoint_implementation.md`。下一阶段为第一个灰盒Room。

同日首Room阶段追加：主场景为`world/start_room_session.tscn`，实例化HD_10001_1 PackedScene，接入T5的出生/引导/检查点三个Node。平地无敌人，出口仅验证目标HD_10002_1；相邻Room与分块加载尚未实现。正式Room使用独立room_saves目录，保留此前测试存档，详见`start_room_implementation.md`。

同日双Room阶段追加：主场景`world/two_room_session.tscn`接入HD_10002_1、普通双向连接、相邻资源预加载与当前实例卸载/替换，首次介绍及入口检查点接入同一存档命名空间。用户允许重置敌人后重复获取可能性，覆盖原T4有限刷取限制。移动引导正式美术需位于画面中上部；本次仍是占位。详见`two_room_implementation.md`。

同日Room2追加：主场景`world/tower_session.tscn`以注册表扩展HD_10002_2，垂直平台路线、既有近战/远程压力、上下连接与相机范围接入。用户确认Room2沿用入口检查点；未新增Node编号、奖励系统或敌种。六段普通跳跃零资源可达性及跨Room死亡恢复纳入验证，详见`tower_room_implementation.md`。

同日Room3追加：主场景`world/exploration_session.tscn`扩展HD_10002_3探索与战斗路线，加入下攻击可选支路、E/RB拾取珍珠占位及现有槽events持久化。用户明确本轮无强化属性、无未定机关、沿用入口检查点；未制作完整背包/成长系统。连接请求只允许当前邻接关系，详见`exploration_room_implementation.md`。


同日连结处追加：主场景world/connection_session.tscn接入HD_10003_1。用户确认清敌永久解锁返回，清敌后靠近开关E / RB永久开启前路；继续沿用入口检查点。旧槽兼容，状态保存，写盘失败回滚、敌人重置仍重复奖励。HD_10004_1只作为阶段边界，未制作Boss，详见connection_room_implementation.md。


同日渴望俯视追加：主场景world/boss_session.tscn接入HD_10004_1，60生命/伤害1/0.6秒落击提示、飞行/纵跳/3层召唤平台为用户确认的可调灰盒。正式入口检查点、一次性镜头演出、无Boss血条、永久胜利与金光天窗接入；同帧死亡保留胜利，成长只记待领取。田野仍为阶段边界，详见overlook_boss_implementation.md。


同日黄金麦湖追加：主场景world/field_session.tscn扩展Region_TY与TY_10001_1。用户确认首见演出、7临时逐句对话、一次性补满可能性与恢复教程、沿用Boss检查点；死亡/读档豁免主动放弃，手动回荒地须确认并保存永久失败。麦秆镇/救助/成长未交付，详见field_room_implementation.md。


同日麦秆镇追加：主场景world/town_session.tscn接入TY_10002_1。用户确认免费救助、一次+4、返回7后首次上限10→12且不补余额。运行时maximum与共享基础Resource分离，旧10上限槽兼容，新12上限绑定注视和救助来源；后续成长未交付。详见town_rescue_implementation.md。

同日沟壑入口追加：主场景world/ravine_session.tscn接入HD_20001_1与正式检查点HD_20001_1_N001。用户确认本轮仅平台/下攻击路线及既有无色实体，完成7首见剧情后在入口将日期至少推进到第2日；日期、检查点同次保存，失败回滚，重复不加天、第3日不倒退，旧槽默认第1日。麦秆镇离开田野须保留未救助确认。自然计时/超时、单色实体及陷阱机关仍延期，详见ravine_day_implementation.md。

2026-10-16沟壑救助追加：主场景world/ravine_rescue_session.tscn扩展HD_20001_2；按原表无普通敌人，沿用入口检查点。用户确认E/RB免费救助、一次+4、已有注视后12→13，提前救助在首次注视时补发+1。见到NPC后实际离开须确认永久放弃，死亡/读档豁免；HD_20001_3仍为边界。陷阱机关/隐藏收集延期，详见ravine_rescue_implementation.md。

2026-10-16沟壑第三间追加：主场景world/ravine_depth_session.tscn接入HD_20001_3，用户确认清敌自动救助、一次+4及注视后独立+1、两端通路永久开启、清敌前允许确认永久放弃并撤回。两位沟壑NPC完成后上限14，提前救助在首次注视一起结算。珍珠只保存占位，沿用入口检查点；HD_20002_1仍为边界。详见ravine_depth_implementation.md。

2026-10-16营帐外围追加：主场景world/camp_session.tscn扩展HD_20002_1，按冻结设计提供高低差、平台、既有无色实体、独立珍珠占位与两端无条件道路。沿用已确认的占位/延期口径，无NPC或新检查点；继续使用沟壑入口检查点，HD_20002_2仍为阶段边界，单色实体/陷阱机关/秘密路线/珍珠强化待后续落实。详见camp_room_implementation.md。

2026-10-16营帐第二间追加：主场景world/camp_waves_session.tscn接入HD_20002_2与HD_20002_2_N001检查点。用户确认3波2/2/3只既有无色实体、波间1秒/预警0.6秒、安全区后开战，两端无条件，往返/死亡/读档重置整场、击杀各+2、不另发通关奖。波次参数Resource化，暂停冻结计时，写盘失败可重试。HD_20003_1仍为边界，详见camp_waves_implementation.md。

2026-10-16寄生同伴者追加：主场景world/parasite_session.tscn接入HD_20003_1。用户确认80生命/伤害1/0.45秒前摇三连可弹反投射物，实际伤到玩家才回3生命，反弹伤害5；移动换位与受限首见、正式入口检查点、永久胜利/两端通路/第3日事件同次保存接入。闪避强化只记待领取；单色实体及逆时战场延期，详见parasite_boss_implementation.md。
