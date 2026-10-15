# 《末日前31天》V0.1 首个工程交付

首次交付：2026-10-14；本次更新：2026-10-15。基础玩家/战斗/AI、生命/可能性、闪避/恢复、检查点/分槽存档已接入；可游玩深谷起始区及瓦砾塔入口、Room2、Room3、连结处、渴望俯视Boss灰盒、黄金麦湖及麦秆镇救助/首次注视成长，尚无正式美术。

**修订标记（2026-10-15，同日追加）**：下攻击弹起高度改为长按跳跃最大高度的50%，覆盖此前“原来的2倍”规则；取消攻击移动减速、跑攻前后摇各翻倍及连击按键间隔上限0.5秒（含边界）保留。同步修订仓库 `Words/` 中T1、T2及T3关联条目。

## 打开与运行

1. 使用 **Godot 4.7.2 Stable 标准版 Windows x64**。官方下载：https://godotengine.org/download/archive/4.7.2-stable/ 。无需 .NET、Spine 或其他插件。
2. 在 Godot 项目管理器选择“导入”，选择本文件同目录的 `project.godot`。等待初次导入完成。
3. 按 **F5** 运行主场景 `world/town_session.tscn`，选择存档槽的新游戏并确认，或继续已有槽；前阶段`room_saves`存档直接兼容。新游戏先坠落、落地起身，再显示移动/跳跃引导。
4. 深谷向右进入瓦砾塔入口，继续道路进入Room2，向上攀登后进入Room3。Room3主路沿平台转向上层横臂；下层可选凹槽有珍珠和下攻击练习。靠近珍珠按E / RB拾取并保存，目前不强化属性。未拾取、零可能性也能走通主路；凹槽靠近左边缘后可普通跳跃离开。Room3上方进入HD_10003_1连结处：清敌后永久解锁返回，清敌后靠近开关按E / RB永久开启前路；前进进入HD_10004_1渴望俯视Boss区。入口自动记录检查点，首次登场后开始战斗；留意落击提示，借3层召唤平台跳跃攻击。击败后天窗开启，向上进入黄金麦湖，首次演出后与7进行临时剧情对话（E / RB推进、长按加速），完成后一次补满可能性并显示恢复提示。向右进入麦秆镇，靠近幸存者E / RB完成临时对话后免费救助，一次+4可能性；返回7完成结算后上限10→12，余额不补满。未救助时主动返回荒地须确认永久放弃，死亡/读档返回检查点不算主动放弃；救助完成后可往返。麦秆镇右侧为下一阶段边界。
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

## 尚未实现

本日已接入TY_10002_1麦秆镇救助与首次7的注视成长（上限10→12）。下一连接HD_20001_1为阶段边界。Boss成长奖励仍仅记录待领取，不修改属性。

当前尚未实现HD_20001_1及后续Room、寄生同伴者Boss、日期/倒计时、其他救助NPC与后续上限成长、完整背包或Room3珍珠强化/未定机关。已放置三个正式检查点，Room2/Room3/连结处沿用瓦砾塔入口检查点，渴望俯视使用HD_10004_1_N003，黄金麦湖/麦秆镇沿用此检查点。旧攻击场景橙色目标仍是开发装置。高空落地仅反馈/硬直，未自动施加坠落伤害。移动引导未来美术化并放画面中上部，文字仍是占位。设置仅当前进程保持，不写入存档。

正式Room存档在Godot用户数据目录的`room_saves/`；此前测试场地的`saves/`原样保留，可通过F6运行`debug/checkpoint_lab.tscn`继续。两类槽独立，不自动转换，不包含在工程包。

可能性初始3、基础上限10；首次救助后返回7结算提高至12，透支下界仍为-9。地面/空中左右闪避共用连闪计数，从上次发动计时1.3秒后重置，跨越-9时拒绝发动。空中闪避保留竖直速度并继续重力、松键截断，不重置跳跃；落地仍正常反馈与硬直。资源不足滑步前摇更长、无敌更短。恢复开始扣费，松键、受击或滑步取消均不退款；完成前不回血，满血或资源不足3不能启动。具体灰盒调校值在PossibilityConfig中。死亡结算在HP归零时自动保存一次，避免退出重进规避损失；不是取回检查点的旧余额。

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
```

导出独立exe需先安装同版本Godot Export Templates，再选择Windows x64预设。本次交付工程压缩包，不声称已验证exe导出。引擎下载供本地验证，未包含在压缩包中。

## Git / LFS

仓库本地LFS已启用；PNG/JPG、WAV/OGG、PSD、Spine源文件与skel进入LFS，脚本/场景/Resource/SVG为文本。当前占位资源均为文本SVG，因此LFS尚无二进制对象。未配置远程仓库或推送。

独立压缩包包含 `.gitignore`、`.gitattributes` 和 `31days-v0.1.bundle`（完整可追溯提交）。恢复完整仓库：`git clone 31days-v0.1.bundle 31days`，然后在新仓库执行 `git lfs install --local`，导入其 `game/project.godot`。压缩包的 `game/` 同样可以直接导入。
