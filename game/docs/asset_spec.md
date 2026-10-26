# 素材规格（V0.1 M3）

ART-001。规定素材交付的尺寸、目录、命名、骨骼、导入与登记，按它生产的素材可以直接接入。风格见 [art_style.md](art_style.md)；来源与分工见 `Words/T6_素材来源与规格决定.md`（本文件把其中第 4、5 节的“起点”定为正式数值，调整处已回写该记录的变更记录）。

## 1. 尺寸与比例

- 游戏基准分辨率 1920×1080；地形瓦片 64×64 px。
- 玩家有两个胶囊（`game/player/player.tscn`）：**受击胶囊高 96 px**（`Body`，决定被打中的范围），**物理胶囊高 88 px**（`PhysicsBody`，决定站立与碰撞）。美术不改两者。
- 显示高度（1080p，头顶到脚底）：

| 对象 | 比例（T6-E） | 显示高度 | 交付高度（2 倍） |
| --- | --- | --- | --- |
| 玩家 | 100% | 112 px | 224 px |
| 普通 NPC、普通敌人（无色、单色、天人、幸存者） | 80% | 90 px | 180 px |
| 关键 NPC（7、10）、精英敌人 | 200% | 224 px | 448 px |
| Boss | 250% | 280 px | 560 px |

- 玩家显示高度 112 px 比受击胶囊高出 16 px，多出的是头发与头顶轮廓；脚底与胶囊底对齐。其他角色的碰撞与显示高度的对应在各自接入任务中核对（BL-063），本规格不改碰撞。
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
- 人形标准骨骼（玩家、7、10、幸存者、幸存者战士、无色、单色、天人）：

```
root
└ hip
  ├ spine ─ chest ─┬ neck ─ head
  │                ├ arm_upper_near ─ arm_lower_near ─ hand_near ─ weapon
  │                └ arm_upper_far  ─ arm_lower_far  ─ hand_far
  ├ leg_upper_near ─ leg_lower_near ─ foot_near
  └ leg_upper_far  ─ leg_lower_far  ─ foot_far
```

- 附加骨骼只在风格说明列出时使用（玩家 `cloth_1…3` 围巾尾，10 `cloth_1…2` 衣摆）。
- 无色、单色实体的手持物（生前物件，art_style.md 第 6.1 节）单独成图，命名 `<对象>_part_item_<名称>.png`（如 `colorless_part_item_shovel.png`），挂在 `weapon` 骨骼下；同类个体可按区域换图，怎样给个体配物件由接入任务定，只换图，不改玩法。
- 天人战士身上的“墨从末端侵蚀”画在手、脚、小臂、小腿的部件图里，不另设骨骼。
- 两场 Boss 按造型自定骨骼，命名仍用小写英文与 `_near` / `_far`（Boss 形象待按风格说明第 6.1 节重新设计后补充）。
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
