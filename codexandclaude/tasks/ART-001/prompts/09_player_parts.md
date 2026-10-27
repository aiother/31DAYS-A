# 09 玩家部件拆分清单（GPT Image 2 + Claude 切图）

用途：ART-002 据此为玩家生成、拆层与绑骨。参考图一律用已认可的设定图 `assets_src/inbox/art/player/player_01_3.png`（萤环绕在**手腕**上，光再偏蓝一点）。规格见 `game/docs/asset_spec.md` 第 1、3 节：交付高度 224 px（显示 112 px，`Art` 缩放 0.5），关节处多画约 **15% 重叠区**，近侧 `near` / 远侧 `far`，不分左右。部件放进 `assets_src/inbox/art/player/parts/`，处理后的成品为 `game/assets/characters/player/parts/<文件名>`。

## 来源分两种

- **切图**：设定图里完整可见的部件，由 Claude 从 `player_01_3` 直接切出、去背、补齐重叠区。
- **补画**：设定图里被斗篷或身体遮住、动起来又会露出的部件，由用户用下面的部件提示词以设定图为参考生成，Claude 再切图对齐。
- 远侧部件与近侧同形，整体压暗一档、暗部偏紫（`art_style.md` 第 4 节光从左来）；单独出图，不用近侧镜像代替。

## 清单

层序：数字越大越靠前（同一 `Art` 下的绘制顺序；斗篷前片盖住身体，远侧肢体在身体后）。挂接骨骼见 `asset_spec.md` 第 3 节标准骨骼树，附加骨骼 `hood`（挂 `head`）、`cloth_1` 挂 `hip`、`cloth_2` 挂 `cloth_1`、`cloth_3` 挂 `cloth_2`、`ring`（挂 `hand_near`）。

| 文件 | 画面内容 | 骨骼 | 层序 | 来源 | 遮挡 / 重叠 |
| --- | --- | --- | --- | --- | --- |
| `player_part_cape_back.png` | 斗篷后片外层：深银 `#b4bac4`，从肩背垂到脚踝的水滴形后半，下摆不含边纹（边纹在 `cloth_*`） | `chest` | 1 | 补画 | 被身体和前片挡住的中间部分要画满；上缘伸进兜帽下 15% |
| `player_part_cape_lining.png` | 斗篷内衬：近黑深蓝 `#1f2740`，斗篷前襟敞开处看到的内面 | `chest` | 2 | 补画 | 只在前襟开口与翻起处露出；四周比开口大 15% |
| `player_part_arm_upper_far.png` | 远侧上臂，深蓝工装袖 | `arm_upper_far` | 3 | 补画 | 设定图中被身体遮住；肩端、肘端各多 15% |
| `player_part_arm_lower_far.png` | 远侧前臂 | `arm_lower_far` | 4 | 补画 | 设定图中被身体遮住；肘端、腕端各多 15% |
| `player_part_hand_far.png` | 远侧手，深色手套，半握 | `hand_far` | 5 | 补画 | 腕端多 15% |
| `player_part_leg_upper_far.png` | 远侧大腿，深蓝工装裤 | `leg_upper_far` | 6 | 补画 | 被斗篷遮住，跑动时露出；髋端、膝端各多 15% |
| `player_part_leg_lower_far.png` | 远侧小腿 | `leg_lower_far` | 7 | 补画 | 被斗篷遮住，跑动时露出；膝端、踝端各多 15% |
| `player_part_foot_far.png` | 远侧靴 | `foot_far` | 8 | 补画 | 设定图只露靴尖，需画完整的靴；踝端多 15% |
| `player_part_hip.png` | 腰胯：深蓝工装下半 | `hip` | 9 | 补画 | 被斗篷大部分遮住；上接 `chest` 多 15% |
| `player_part_chest.png` | 躯干上部：深蓝工装上半，领口玫瑰金扣镶紫水晶（`#c08a78`、`#8a5fa8`） | `chest` | 10 | 切图 + 补画 | 斗篷开口内可见部分照设定图，其余补画；下接 `hip`、上接 `neck` 各多 15%（`spine` 不出图，被 `chest` 与斗篷覆盖） |
| `player_part_leg_upper_near.png` | 近侧大腿 | `leg_upper_near` | 11 | 补画 | 被斗篷遮住，跑动时露出；髋端、膝端各多 15% |
| `player_part_leg_lower_near.png` | 近侧小腿 | `leg_lower_near` | 12 | 补画 | 被斗篷遮住，跑动时露出；膝端、踝端各多 15% |
| `player_part_foot_near.png` | 近侧靴 | `foot_near` | 13 | 切图 + 补画 | 靴尖照设定图，靴筒补画；踝端多 15% |
| `player_part_hood.png` | 兜帽后半：深银，贴着大圆头，帽顶软软垂下的尖角 | `hood` | 14 | 切图 | 帽口内侧多 15% 伸到头后，戴上时看不到缝 |
| `player_part_head.png` | 大圆头：两侧少许深色头发、脸部为面纱后的暗色底（不画五官） | `head` | 15 | 补画 | 设定图被兜帽与面纱遮住；颈端多 15% |
| `player_part_veil.png` | 面纱：黑色细网纱，从兜帽边垂下盖住整张脸，纱后两点萤石光的小眼（`#b9c0ff`，只画两点，不画光晕；发光由特效做） | `head` | 16 | 切图 | 上缘塞进兜帽帽口下 15% |
| `player_part_hood_rim.png` | 兜帽前沿：围住脸的一圈帽口边 | `hood` | 17 | 切图 | 压住面纱上缘与头发；两端与兜帽后半各重叠 15% |
| `player_part_cloth_1.png` | 斗篷下摆上段：深银外层 + 掀起处露出的内衬 | `cloth_1` | 18 | 切图 + 补画 | 上接斗篷后片与前片 15% |
| `player_part_cloth_2.png` | 斗篷下摆中段 | `cloth_2` | 19 | 切图 + 补画 | 上下各多 15% |
| `player_part_cloth_3.png` | 斗篷下摆末段：带一道细的玫瑰金几何边纹 | `cloth_3` | 20 | 切图 | 上端多 15% |
| `player_part_cape_front.png` | 斗篷前片（近侧襟）：深银外层，前襟开口的边缘；近侧手臂从开口伸出 | `chest` | 21 | 切图 | 盖住近侧上臂根部；与后片在肩部重叠 15% |
| `player_part_arm_upper_near.png` | 近侧上臂，深蓝工装袖 | `arm_upper_near` | 22 | 补画 | 设定图只露前臂；肩端塞进斗篷前片下 15% |
| `player_part_arm_lower_near.png` | 近侧前臂，伸出斗篷开口 | `arm_lower_near` | 23 | 切图 | 肘端、腕端各多 15% |
| `player_part_hand_near.png` | 近侧手，深色手套，张开空手 | `hand_near` | 24 | 切图 | 腕端多 15%；萤环不画在手上 |

不出图的骨骼：`root`、`spine`、`neck`（被兜帽与 `chest` 盖住）、`weapon`（挂晶弦碎片 `weapon_starter_part_shard_*`，见 `07_weapon_shard_parts.md`）、`ring`（萤环碎片位置，同一组碎片，绕转与光由代码与特效实现）。

## 部件提示词（补画用，替换方括号）

每个补画部件单独生成一张，附设定图 `player_01_3.png` 作为参考图。

```
Hand-drawn ink illustration for a 2D side-scrolling game. Dark sepia ink outlines (#2b2420) with slight hand-drawn wobble and varying line weight, thicker outer contour. Flat colour fills with at most one light and one shadow tone, subtle ink bleed and paper texture, no gradients, no painterly rendering, no realistic lighting. Low warm dusk sunlight from the LEFT: a thin warm rim light (#f4b860) on the left edges, shadows tinted cool violet (#7d4a8c).

Match the reference image exactly in silhouette, colours and proportions. Isolated body part on transparent background, same character and style as the reference image, side view facing RIGHT, extend the part about 15% past the joint so it can overlap: [PART]. Draw the whole part, including what the cape hides in the reference image. [SIDE] Nothing else in the picture: no other body parts, no cape unless the part is the cape, no text, no frame, no shadow on the ground. No red anywhere. No teal or cyan anywhere.
```

- `[PART]` 写清部件与颜色，例如 `the far-side thigh in the very dark navy work trousers (#1f2740), from hip to knee`；斗篷类写 `the back half of the floor-length hooded cape, deep muted silver (#b4bac4), seen from the side`。
- `[SIDE]`：远侧部件写 `This is the far-side limb: the same shape as the near one, one tone darker, shadows more violet.`；近侧部件删去这句。

## 验收要点

- 每张只有一个部件，背景透明或纯白，可干净去背。
- 与设定图叠放时颜色、线条粗细、比例一致（`asset_spec.md` 第 6 节三项一致性）。
- 关节两端都多出约 15%，弯曲时不露缝。
- 远侧部件同形、压暗一档、暗部偏紫。
- 面纱只画两点眼光，不画光晕；手上不画萤环；全图没有红色、没有青色。
