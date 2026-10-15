# 《末日前31天》V0.1 首个工程交付

首次交付：2026-10-14；本次更新：2026-10-15。阶段：工程初始化 → 玩家灰盒 → 基础攻击 → 无色实体AI与攻击 → 玩家生命/死亡。运行场景为开发测试场地，不占用正式 Region / Scene / Room / Node 编号，不新增正式地图。

**修订标记（2026-10-15，同日追加）**：下攻击弹起高度改为长按跳跃最大高度的50%，覆盖此前“原来的2倍”规则；取消攻击移动减速、跑攻前后摇各翻倍及连击按键间隔上限0.5秒（含边界）保留。同步修订仓库 `Words/` 中T1、T2及T3关联条目。

## 打开与运行

1. 使用 **Godot 4.7.2 Stable 标准版 Windows x64**。官方下载：https://godotengine.org/download/archive/4.7.2-stable/ 。无需 .NET、Spine 或其他插件。
2. 在 Godot 项目管理器选择“导入”，选择本文件同目录的 `project.godot`。等待初次导入完成。
3. 按 **F6** 可运行当前场景；按 **F5** 运行项目，主场景已设置为 `debug/enemy_lab.tscn`。移动/攻击测试场景 `debug/movement_lab.tscn`、`debug/combat_lab.tscn` 保留。
4. 向右接近灰色无色实体，单击J或鼠标左键攻击；连续单击循环两段，按住W/↑攻击上方，跳起后按S/↓向下攻击。敌人13生命，3次普通命中可击败；左右/上攻击可以反弹橙色投掷物。R重置敌人与场地。
5. 仍可测试行走/跑步、短按/长按跳跃、空中反向，逐级跳上平台并从高处落下。R不代表存档或复活。
6. 玩家开场生命3/5，敌人有效攻击扣1；受击期间有短暂保护与硬直。生命归零后倒地1秒、转黑，再选择“重新挑战（灰盒出生点）”：敌人重置，生命5/5、保护3秒，主动攻击不解除保护。Esc可暂停/设置，死亡后不能用R跳过流程。

工程以1920×1080为基准、保持16:9，开发窗口1280×720，Compatibility渲染，目标60 FPS、物理60 Hz。实际帧率仍取决于机器性能。

## 操作

| 行为 | 键鼠 | 手柄（Godot标准布局） | 状态 |
| --- | --- | --- | --- |
| 左右移动 | A/D、左右方向键 | 左摇杆、十字键 | 已实现 |
| 跑步 | 按住Shift | 按住LB | 已实现 |
| 跳跃 | 空格，长按跳得更高 | A/底部面键 | 已实现 |
| 重置测试场地 | R | 未映射 | 已实现，仅开发使用 |
| 全屏切换 | F11 | 未映射 | 已实现 |
| 上/下攻击方向 | W/S、上下方向键 | 左摇杆、十字键 | 已实现，下攻击仅空中 |
| 攻击 | J、鼠标左键 | X/左侧面键 | 已实现，连续单击两段循环 |
| 地面滑步 | K | B/右侧面键 | 仅InputMap |
| 恢复 | L | Y/上方面键 | 仅InputMap |
| 互动 | E | RB | 仅InputMap |
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
- 基础攻击：两段循环，各5伤害；第二段击退更强、后摇更长；【2026-10-15修订】相邻按键间隔不超过0.5秒才能衔接第二段，按键时刻计算，输入缓冲不延长窗口；超时或起跳重置。
- 左右/向上/空中向下攻击；单次方向锁定，转身不改变已出手攻击。【2026-10-15修订】攻击保持正常行走/跑步速度，仍不能跳跃取消。发动时按住跑步且有水平输入，前摇0.08→0.16秒；第一段后摇0.14→0.28秒、第二段0.28→0.56秒，活跃判定时间不变。倍率按出招锁定，松开跑步不缩短本次后摇。
- 活跃判定阶段查询Hitbox形状；前摇/后摇不伤害，每次动作对每个目标仅结算一次，可同时命中多个目标。
- 下攻击落空不改变下落；【2026-10-15追加修订】命中后弹起高度为长按跳跃最大高度的50%，一次动作最多弹起一次；按住/松开跳跃不改变弹起高度。根据当前跳跃参数计算最大跳高，再按目标高度和物理步长反推弹起速度；后续调整跳跃参数会同步调整弹起，顶部碰撞仍可阻挡。
- 占位攻击范围颜色、受击闪白/击退反馈与短促命中音；CombatHurtbox已连接无色实体生命与受击状态。
- 无色实体13生命、慢速感知/追击、近战/投掷、攻击前摇提示、受击打断/击退、死亡碎块及一次+2收益事件。地面/空中均使用同种实体；本次未发放实际可能性。
- 左右/向上攻击反弹非子弹投掷物，反弹伤害5；投掷物不穿墙、单次反弹，反弹后不再伤玩家。
- 敌方攻击名额与尸体上限，灰盒暂为1与6。参数和阶段边界详见 `docs/colorless_implementation.md`。
- 玩家生命/受击/死亡：上限5、初始3；受击硬直与保护、轻微击退、被动打断攻击、零生命停止操作、倒地/转黑/死亡菜单、满血重新挑战与3秒保护。独立Life Resource提供数据，反馈与物理分离。
- 攻击以物理查询进行判定；敌人场景启用玩家Hurtbox实际扣血。生命数字、低血色、受击/保护闪烁及死亡界面已接入；互动未接入。
- Windows x64导出预设、Git/LFS规则、工程目录与可重复验证脚本。

## 尚未实现

按冻结顺序继续：可能性/地面滑步/恢复 → 检查点 → 第一个正式灰盒Room。

当前尚未实现可能性及实际资源结算、恢复/地面滑步、正式检查点/存档、时间、剧情、NPC或正式地图。死亡重新挑战明确使用开发出生点，不等同从存档点加载；未计算死亡可能性损失。旧攻击场景的橙色目标仍是开发装置，不是新增敌人。闪避取消攻击待地面滑步及可能性阶段接入。高空落地仅反馈/硬直，环境伤害入口可用但未自动施加坠落伤害。菜单/生命UI为当前阶段表现；设置仅在当前进程保持，不写入存档。细则见`docs/player_life_implementation.md`。

Spine Professional与官方spine-godot尚未集成，不含商业授权或运行时二进制。后续只替换 `VisualRoot` 子树并锁定编辑器/导出数据/runtime/Godot的兼容组合。物理、位置、状态和Hitbox/Hurtbox继续由Godot控制。

## 调校与结构

`player/movement_config.gd`中的默认速度、重力、保持时长和硬直均为**首轮灰盒参数**，不声称已获最终手感验收。`data/player/graybox_movement.tres`可在Inspector中覆盖。`data/combat/graybox_attack.tres`配置攻击；5伤害来自T3冻结值；2026-10-15确认连击按键间隔0.5秒、跑攻时长倍率2，并追加确认弹起为最大跳高的50%，配置字段为 `down_bounce_jump_height_ratio = 0.5`。其他范围与击退仍为灰盒调校参数。正式冻结依据见仓库 `Words/` 的T0–T5.4与已填写T6/T7，以及本次T8技术基线。

```text
Player (CharacterBody2D)
├── BodyCollision
├── GameplayRoot
│   ├── Combat（Typed GDScript攻击状态与结算）
│   ├── Life（生命、受击保护、死亡时序）
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
```

导出独立exe需先安装同版本Godot Export Templates，再选择Windows x64预设。本次交付工程压缩包，不声称已验证exe导出。引擎下载供本地验证，未包含在压缩包中。

## Git / LFS

仓库本地LFS已启用；PNG/JPG、WAV/OGG、PSD、Spine源文件与skel进入LFS，脚本/场景/Resource/SVG为文本。当前占位资源均为文本SVG，因此LFS尚无二进制对象。未配置远程仓库或推送。

独立压缩包包含 `.gitignore`、`.gitattributes` 和 `31days-v0.1.bundle`（完整可追溯提交）。恢复完整仓库：`git clone 31days-v0.1.bundle 31days`，然后在新仓库执行 `git lfs install --local`，导入其 `game/project.godot`。压缩包的 `game/` 同样可以直接导入。
