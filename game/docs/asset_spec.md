# 素材规格（V0.1 M3）

ART-001。规定素材交付的尺寸、目录、命名、骨骼、导入与登记，按它生产的素材可以直接接入。风格见 [art_style.md](art_style.md)；来源与分工见 `Words/T6_素材来源与规格决定.md`（本文件把其中第 4、5 节的“起点”定为正式数值，调整处已回写该记录的变更记录）。

## 1. 尺寸与比例

- 游戏基准分辨率 1920×1080；地形瓦片 64×64 px。
- 玩家有两个胶囊（`game/player/player.tscn`）：**受击胶囊高 96 px**（`Body`，决定被打中的范围），**物理胶囊高 88 px**（`PhysicsBody`，决定站立与碰撞）。美术不改两者。
- **游戏镜头 ×1.875**（`game/world/gameplay_camera.gd`，用户 2026-10-30 按参考实机画面决定，依据 `codexandclaude/proposals/ART-003/player_scale_v1/`）：玩家站立时脚底在画面 88% 高度（1080p 下 y≈950），一屏显示 1024×576 世界单位。只放大画面，世界坐标、碰撞、跳跃与 Room 几何不变。
- 显示高度（世界单位，头顶到脚底）与 1080p 画面中的实际高度：

| 对象 | 比例（T6-E） | 显示高度 | 1080p 画面高度（×1.875） | 交付高度（2 倍） |
| --- | --- | --- | --- | --- |
| 玩家 | 100% | 112 px | 210 px（约 19.5% 屏高） | 224 px |
| 普通 NPC、普通敌人（无色、单色、天人、幸存者） | 80% | 90 px | 169 px | 180 px |
| 关键 NPC（7、10）、精英敌人 | 200% | 224 px | 420 px | 448 px |
| Boss | 250% | 280 px | 525 px | 560 px |

- 玩家显示高度 112 px 比受击胶囊高出 16 px，脚底与胶囊底对齐；多出的是白色蓬松短发与翻起的呆毛（art_style.md 第 6.2 节「初页」）。
- 交付图（2 倍）在镜头 ×1.875 下以约 0.94 倍显示，仍不放大；若以后再拉近镜头，交付倍数须同步提高。
- 人形角色比例：玩家约 5 头身，头（发顶到下巴）约为显示高度的 20%，约 22 px（交付图约 45 px）；其他人形角色暂无方案（2.5 头身不再是统一要求，art_style.md 第 6.0 节）。其他角色的碰撞与显示高度的对应在各自接入任务中核对（BL-063），本规格不改碰撞。
- **交付 2 倍，显示 0.5**：素材按上表“交付高度”制作，接入时 `Art` 节点缩放 0.5。AI 原图可以更大，由 Claude 缩到交付尺寸。
- 格式：PNG，RGBA 透明背景，sRGB；背景图例外见第 4 节。

## 2. 目录与命名

对象编号：`player`、`weapon_starter`、`seven`、`ten`、`survivor`、`survivor_warrior`、`colorless`、`monochrome`、`tian`、`boss_overlook`、`boss_parasite`。区域编号：`hd`（荒地）、`ty`（田野）、`nszc`（逆时战场）。全部小写英文、下划线分隔。

| 内容 | 路径 | 文件名 |
| --- | --- | --- |
| 角色部件 | `game/assets/characters/<对象>/parts/` | `<对象>_part_<骨骼名>.png` |
| 关键逐帧 | `game/assets/characters/<对象>/keys/` | `<对象>_key_<状态>_<两位序号>.png` |
| 骨骼场景 | `game/assets/characters/<对象>/` | `<对象>_rig.tscn` |
| 动画资源 | `game/assets/characters/<对象>/anims/` | 沿用 SYS-010：`<对象>_<状态>_<变体>_<连段>_<阶段>.tres` |
| 设定图（定稿后的参考） | `game/assets/characters/<对象>/ref/` | `<对象>_ref_<视角>.png`（只作参考，不进游戏场景） |
| 背景 | `game/assets/environments/<区域>/bg/` | `<区域>_bg_<far\|mid\|near>_<两位序号>.png` |
| 瓦片、装饰 | `game/assets/environments/<区域>/tiles/`、`deco/` | `<区域>_tiles_<outdoor\|indoor>.png`、`<区域>_deco_<名称>.png` |
| 音效、环境音、音乐 | `game/assets/audio/<sfx\|amb\|bgm>/` | 见第 5 节 |

## 3. 骨骼与部件

- 正式资源放在 `VisualRoot/Facing/Art` 下（SYS-010），Facing 负责左右镜像，所以骨骼与部件分**近侧 `near` / 远侧 `far`**，不分左右。
- 人形标准骨骼（玩家、7、10、幸存者、幸存者战士、天人）：

```
root
└ hip
  ├ spine ─ chest ─┬ neck ─ head
  │                ├ arm_upper_near ─ arm_lower_near ─ hand_near ─ weapon
  │                └ arm_upper_far  ─ arm_lower_far  ─ hand_far
  ├ leg_upper_near ─ leg_lower_near ─ foot_near
  └ leg_upper_far  ─ leg_lower_far  ─ foot_far
```

- 附加骨骼只在风格说明列出时使用（玩家 `forelock`、`hair_front`、`hair_back`、`collar`、`clasp`、`cape_back`、`cape_front_near`、`cape_front_far`，部件命名 `player_part_<骨骼名>.png`，表见 `codexandclaude/proposals/ART-003/first_page_v1/README.md`；10 `cloth_1…2` 衣摆）。
- 无色、单色实体是非人形态（art_style.md 第 6.1 节），按造型自定骨骼，命名用小写英文与 `_near` / `_far`，同类部位加序号（如 `leg_1_near…`、`jaw`、`tail_1…n`）：
  - 长进身体的生前物件单独成图，命名 `<对象>_part_item_<名称>.png`（如 `colorless_part_item_shovel.png`），挂在它所成为的那个部位的骨骼下；
  - 人的遗存单独成图，命名 `<对象>_part_remnant_<名称>.png`（如 `colorless_part_remnant_hand.png`、`monochrome_part_remnant_coat.png`），挂在它所在部位的骨骼下；
  - 无色实体的形态随区域物件而变：每个区域的无色各有一套骨骼与部件，同一区域内个体可换物件与遗存图；怎样给个体配图由接入任务定，只换图，不改玩法。
- 玩家武器：暂无方案（原“萤环与晶弦”的部件命名、`ring` 骨骼与十三片切割做法随原玩家方案废弃，art_style.md 第 6.3 节）；`hand_near`、`hand_far` 下都可挂 `weapon` 骨骼作挂点。
- 玩家染色（art_style.md 第 6.2 节“初页的染色”）：颜色遮罩单独成图 `player_tint_<骨骼名>_<两位序号>.png`，与对应部件同尺寸、同锚点，叠在部件上，由代码按关系进度显示；部件图本身保持初态纯白。
- 天人战士（art_style.md 第 6.2 节）：“墨从末端侵蚀”与化墨的黑袍下摆、袖口画在对应部件图里，不另设骨骼；面具两张图——`tian_part_mask.png`（完好）与 `tian_part_mask_cracked.png`（崩掉一角、露出黑洞、裂口渗墨），挂在 `head` 骨骼下，按生命比例切换，由接入任务在视觉层实现；额心红宝石的朱红发光由特效实现（与 FX-002 重击前摇同步），图里只画不发光的红宝石；高冠为 `tian_part_crown.png`。
- 两场 Boss 同样按造型自定骨骼，命名仍用小写英文与 `_near` / `_far`：
  - 渴望俯视：皮鞋壳 `boss_overlook_part_item_shoe.png`；两张面甲 `boss_overlook_part_face_scorn.png`（高于玩家）与 `boss_overlook_part_face_fawn.png`（低于玩家），挂在 `head` 骨骼下，按与玩家的高度差切换可见，由接入任务在视觉层实现；工牌 `boss_overlook_part_remnant_badge.png`；翅 `wing_near` / `wing_far`。
  - 寄生同伴者：两端分别以 `human_root` 与 `parasite_root` 为根，头为 `head_human` 与 `head_parasite`；虫身按节 `parasite_1…n`；肉管 `tube_<两位序号>`；水壶 `boss_parasite_part_item_canteen.png` 挂在接合处的 `waist` 骨骼下。哪一端朝向玩家由接入任务按动作安排，只换朝向与图，不改玩法。
- 关键逐帧只覆盖对应肢体或阶段；切换时显式设置可见性，避免双重轮廓（SYS-010 约定）。

## 4. 场景素材

- 背景：每区域远、中、近景各至少 1 张；宽 ≥ 3840 px、高 1080～1620 px（可横向无缝平铺则不限宽）；近景层透明背景，远景、中景可不透明。
- 瓦片与装饰由代码绘制（与 FX-001 同法），网格 64 px；检查点外观共用一套、按区域换色。

## 5. 音频

| 类别 | 格式 | 声道 | 长度 / 循环 | 文件名 |
| --- | --- | --- | --- | --- |
| 普通音效（C）、可能性音效（A） | WAV，44.1 kHz，16 bit | 单声道 | 0.05～1.5 秒，首尾不留空白 | `sfx_<事件名，点换下划线>.wav`，如 `sfx_combat_hit.wav` |
| 区域环境音（A） | OGG Vorbis，44.1 kHz | 立体声 | 60～120 秒无缝循环 | `amb_<区域>.ogg` |
| 音乐（B；剧情 C） | OGG Vorbis，44.1 kHz | 立体声 | 90～180 秒，带循环点 | `bgm_<exploration\|combat\|large_battle\|story>.ogg` |

- 峰值不超过 −1 dBFS；音乐约 −16～−18 LUFS；环境音比音乐低约 6 dB；音效与现有占位音对齐听感后统一微调。
- 接入只改 `game/systems/audio/default_audio_map.tres` 对应槽位（SYS-011），不改玩法代码。

## 6. 生成与一致性

- 每个角色**先定设定图**（正侧面全身），用户确认后放进 `ref/`；之后的部件与关键帧一律以它作参考图生成。
- 验收要点每次都查三项一致性：**轮廓**（与设定图叠放外形一致）、**配色**（只用风格说明给该角色的颜色）、**比例**（头身比与第 1 节显示高度一致）。
- 提示词模板见 `codexandclaude/tasks/ART-001/prompts/template.md`；各对象的提示词放在对应任务目录的 `prompts/`，登记时在 `CREDITS.md` 备注里写提示词文件路径。

## 7. 收件箱、入库与登记

- 收件箱：仓库根目录 `assets_src/inbox/<art|audio>/<对象或区域>/`。**整个 `assets_src/` 不入库**（原图体积大，且不进游戏）；用户把生成或下载的文件放进去，Claude 从中取件。
- 入库的只有处理后的游戏用素材（`game/assets/` 下）与提示词文本（任务目录）。
- 每个入库素材在 `game/assets/CREDITS.md` 登记一行，格式与规则见该文件；ENV-008 在 G3 中检查。

## 8. 导入

- PNG（`characters/`、`environments/`）：无损（`compress/mode=0`）、不生成 mipmap（`mipmaps/generate=false`）、修正透明边（`process/fix_alpha_border=true`）。纹理过滤用项目默认的线性过滤，不在节点上改成最近邻。
- 音频：环境音与音乐在导入中开启循环（OGG `loop=true`，音乐按交付的循环点设 `loop_offset`）；音效不循环。
- ENV-008 检查前两条 PNG 设置。

## 9. 变更记录

| 日期 | 变更 | 依据 |
| --- | --- | --- |
| 2026-10-25 | 首版：在素材决定记录第 4、5 节基础上定正式数值；补受击 / 物理胶囊区分、设定图 `ref/` 目录、骨骼场景命名、收件箱不入库、导入设置 | ART-001；PLN-003 审查非阻断建议 |
| 2026-10-25 | 无色、单色实体按造型自定骨骼（部位加序号）；嵌入物、手持物部件命名，可按个体换图；敌人动画离散插值抽帧；渴望俯视两张脸、寄生同伴者双头与肉管的部件命名 | art_style.md 第 6.1 节（用户 2026-10-25 定敌人诡异化） |
| 2026-10-25 | 随风格说明推翻上述敌人设计：无色、单色回到人形标准骨骼；去掉嵌入物、按造型自定骨骼、Boss 部件命名与敌人抽帧；手持物改挂 `weapon` 骨骼、按区域换图；天人末端侵蚀画在部件图里 | art_style.md 第 6.1 节（用户 2026-10-25 推翻并重建敌人框架） |
| 2026-10-25 | 无色、单色改为非人形态、按造型自定骨骼；长进身体的物件与人的遗存（`_part_remnant_`）部件命名；无色每区域一套骨骼 | art_style.md 第 6.1 节“逐级去人化”“人的遗存”（用户 2026-10-25） |
| 2026-10-25 | 补 2.5 头身对应的头高 | art_style.md 第 6.0 节（用户 2026-10-25） |
| 2026-10-25 | 两场 Boss 的部件与骨骼命名（渴望俯视的皮鞋、两张面甲、工牌、翅；寄生同伴者的两端根骨、两头、虫身、肉管、水壶） | art_style.md 第 6.2 节（用户 2026-10-25 定 Boss 方向） |
| 2026-10-26 | 玩家附加骨骼由围巾尾改为斗篷下摆 | art_style.md 第 6.2 节（玩家改为匠首） |
| 2026-10-26 | 玩家附加骨骼加 `hood`（连帽长斗篷） | art_style.md 第 6.2 节 |
| 2026-10-26 | 玩家萤环与晶弦的部件命名与做法（碎晶成图、`ring` 骨骼、光丝与光刃由代码特效实现） | art_style.md 第 6.2 节（用户 2026-10-26 定初始武器） |
| 2026-10-26 | 晶弦碎片改为十三枚、各不相同、缺口契合；另交拼合参考整图 | art_style.md 第 6.2 节（用户 2026-10-26 细化晶弦） |
| 2026-10-26 | 晶弦部件来源定为 07 部件图（不画光，光由代码实现） | art_style.md 第 6.2 节（用户 2026-10-26） |
| 2026-10-26 | 晶弦碎片改为“AI 整刃 + 工具切十三片”，补切口墨线与位置表 | art_style.md 第 6.2 节（用户 2026-10-26） |
| 2026-10-26 | 晶弦切割原图定为 `blade_whole_02` | 用户：“blade_whole_02 通过，记为晶弦的切割原图。” |
| 2026-10-26 | 天人战士部件：完好 / 裂开两张面具、高冠，红宝石发光与面具切换由代码实现 | art_style.md 第 6.2 节（用户 2026-10-26 定天人） |
| 2026-10-27 | 天人低血量面具改为崩角露洞渗墨 | art_style.md 第 6.2 节（用户 2026-10-27） |
| 2026-10-29 | 玩家头顶造型、人形比例、玩家附加骨骼与玩家武器部件改为暂无方案（原方案废弃，永不采用） | art_style.md 第 6.3 节（用户 2026-10-29） |
| 2026-10-30 | 加游戏镜头 ×1.875 与 1080p 画面高度列；显示高度改称世界单位，数值不变；补交付倍数与镜头倍率的关系 | 用户 2026-10-30 按参考实机画面定玩家比例与镜头（ART-003 player_scale_v1） |
| 2026-10-30 | 玩家「初页」：头顶为白发与呆毛，约 5 头身（头约 22 px），附加骨骼与部件表、手腕武器挂点、染色遮罩命名 | art_style.md 第 6.2 节（用户 2026-10-30） |
