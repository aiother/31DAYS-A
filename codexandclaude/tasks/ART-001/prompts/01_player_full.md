# 01 玩家全身设定图（GPT Image 2）

用途：定玩家形象（V0.1 唯一 A 级角色），之后所有玩家部件与关键帧都以它为参考。玩家是**匠首**（art_style.md 第 6.0 节阶层、第 6.2 节玩家与“萤环与晶弦”）。本张是**待机设定图**：萤环绕腕，晶弦收着；晶弦展开的样子见 `06_weapon_crystal_string.md`。生成 3～4 张，挑一张最接近验收要点的；不满意把意见告诉 Claude 改提示词。生成后放进 `assets_src/inbox/art/player/`。

**附参考图**：
- 风格参考：已认可的 `assets_src/inbox/art/boss_overlook/BOSS_01.png`，只借线条与平涂画法，不借形状——玩家是人，**不要**它的面甲。
- 形象参考（可选）：上一轮的 `assets_src/inbox/art/player/player_01_2.png`，让斗篷、面纱、比例保持一致，只按本提示词改兜帽、光与手腕。

尺寸建议：竖图 1024×1536 或更大。

## 提示词（整段复制）

```
Hand-drawn ink illustration for a 2D side-scrolling game. Dark sepia ink outlines (#2b2420) with slight hand-drawn wobble and varying line weight, thicker outer contour. Flat colour fills with at most one light and one shadow tone, subtle ink bleed and paper texture, no gradients, no painterly rendering, no realistic lighting. Low warm dusk sunlight from the LEFT: a thin warm rim light (#f4b860) on the left edges, shadows tinted cool violet (#7d4a8c). Muted, low-saturation palette: ink #2b2420, paper #efe4cc, dusk paper #f0cfb6, pearl #fbf6ec.

Style reference: match the attached reference image in line and flat colouring only; do not copy its shape, and do NOT give the character its pale face-plate.

Character: the player, a small hooded wanderer in cute chibi proportions: exactly 2.5 heads tall, a big round head about 40% of the total height, a short body and short rounded limbs, soft rounded shapes with few sharp corners. The whole figure is wrapped in a floor-length hooded cape in a deeper muted silver (#b4bac4), like Little Red Riding Hood's long cape: the hood is up and fits snugly around the big round head, its top ending in a soft, floppy pointed tip that droops to one side like a little elf hood; the cape falls almost to the ankles and wraps the body into a soft, rounded teardrop silhouette, very cute; the cape is lined inside with very dark navy (#1f2740), which shows where the cape opens and flips, so the outside is deep silver and the inside dark; a thin rose-gold geometric band runs along the hem. It opens at the front, showing a plain, very dark navy work coverall (#1f2740) underneath; the hands come out through the front opening in dark gloves, the toes of sturdy dark boots peek out below the hem. Very few accessories: no bags, no pouches, no belts, no straps; the only ornament is a small rose-gold clasp (#c08a78) set with an amethyst (#8a5fa8) at the collar. A black fine-mesh gauze veil hangs from the edge of the hood and covers the whole face; through the veil only two small eyes show, glowing the same soft bluish fluorite light (#b9c0ff), calm and determined; no other facial features visible, a little dark hair at the sides.

Its signature, the "firefly ring": around the wrist of the near hand, NOT a bracelet of beads and NOT a chain, but five small elongated, faceted blue-violet fluorite crystal shards (#7b84c9) floating in a loose ring around the wrist without touching it, slowly orbiting, linked shard to shard by one faint thread of soft bluish light (#b9c0ff); each shard glows softly. The near hand is open and empty, held slightly forward, no weapon in hand.

Full body, strict side view facing RIGHT, standing pose, the near arm slightly out of the cape opening so the floating ring is clearly visible against the background, whole figure visible with margin, transparent background (or plain flat pure white #ffffff background if transparency is unavailable); no dark background, no vignette, no glow or halo around the character. Single character, no text, no frame. No scarf, no red anywhere. No teal or cyan anywhere.
```

## 验收要点

- **萤环（识别锚点）**：手腕外悬浮着五片棱形萤石碎晶，绕腕成一圈、不贴手腕，片与片之间一缕淡淡的光丝；**不是**珠串、不是链子；碎晶蓝紫、光偏蓝白，不是紫、不是青。手里不拿武器。
- **萤石光是身份色**：面纱后的两点眼光与萤环是同一种偏蓝的光。
- **兜帽**：贴着大圆头，帽顶一个软软垂下的尖角。
- **连帽长斗篷**：深银色，罩住全身，垂到脚踝，剪影像一颗圆圆的水滴，可爱；内衬近黑深蓝（掀开处露出），下摆一道细的玫瑰金几何边纹；前襟开口露出近黑的深蓝工装，靴尖露出下摆。
- **配饰从简**：没有包、腰带、带子；只有领口一枚玫瑰金扣（镶紫水晶）。
- **面纱**：黑纱从兜帽边垂下，遮住整张脸；**不是**实体那样的纸色面甲。
- **没有红色、没有青色**。
- **2.5 头身**：头约占身高 40%，身体短、四肢短而圆，形体圆润可爱；仍能想象跑、跳、闪避的动作。
- 深墨轮廓带手绘抖动，平涂，无渐变高光与写实光影；左侧暖色边光，暗部偏紫。
- 正侧面朝右、全身完整、戴萤环的手伸出斗篷开口（便于拆层）；背景透明或纯白，没有深色背景、暗角或光晕。
