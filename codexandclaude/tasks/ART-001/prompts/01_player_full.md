# 01 玩家全身设定图（GPT Image 2）

用途：定玩家形象（V0.1 唯一 A 级角色），之后所有玩家部件与关键帧都以它为参考。玩家是**匠首**（art_style.md 第 6.0 节阶层、第 6.2 节玩家）。生成 3～4 张，挑一张最接近验收要点的；不满意把意见告诉 Claude 改提示词。生成后放进 `assets_src/inbox/art/player/`。

**附风格参考图**：把已认可的 `assets_src/inbox/art/boss_overlook/BOSS_01.png` 一起上传，只借它的线条与平涂画法，不借形状——玩家是人，**不要**它的面甲。

尺寸建议：竖图 1024×1536 或更大。

## 提示词（整段复制）

```
Hand-drawn ink illustration for a 2D side-scrolling game. Dark sepia ink outlines (#2b2420) with slight hand-drawn wobble and varying line weight, thicker outer contour. Flat colour fills with at most one light and one shadow tone, subtle ink bleed and paper texture, no gradients, no painterly rendering, no realistic lighting. Low warm dusk sunlight from the LEFT: a thin warm rim light (#f4b860) on the left edges, shadows tinted cool violet (#7d4a8c). Muted, low-saturation palette: ink #2b2420, paper #efe4cc, dusk paper #f0cfb6, pearl #fbf6ec.

Style reference: match the attached reference image in line and flat colouring only; do not copy its shape, and do NOT give the character its pale face-plate.

Character: a young "Artisan Chief" (a front-line industrial technician of this world), the player character, in cute chibi proportions: exactly 2.5 heads tall, a big round head about 40% of the total height, a short body and short rounded limbs, soft rounded shapes with few sharp corners. Wears a practical deep navy-blue work coverall (#2f3a56) with rolled-up sleeves, a small tool pouch on the belt, sturdy dark boots and work gloves. Over the shoulders a short silver-white cloak (#e2e5e9) that falls to mid-back and flutters behind, fastened at the collar by a small rose-gold clasp (#c08a78) set with an amethyst (#8a5fa8); a few tiny blue-violet fluorite stones (#7b84c9) on the clasp edge and the pouch. A black fine-mesh gauze veil hangs from a simple cap brim and covers the whole face; through the veil only two small, softly glowing pale eyes show, calm and determined; no other facial features visible, a little dark hair at the sides. Holds a short single-edged workshop cutting blade in the near hand, blade pointing forward and down. No scarf, no red anywhere.

Full body, strict side view facing RIGHT, standing pose, arms slightly away from the body, cloak clear of the legs, whole figure visible with margin, transparent background (or plain flat pure white #ffffff background if transparency is unavailable); no dark background, no vignette, no glow or halo around the character. Single character, no text, no frame. No teal or cyan anywhere.
```

## 验收要点

- **匠首**：深蓝连体工装（袖口卷起、腰间小工具包）、银白短斗篷、黑色纱网覆面；一看就是实干的一线技术人员。
- **面纱**：黑纱遮住整张脸，只透出两点微弱的眼光；**不是**实体那样的纸色面甲。
- **饰物**：领口玫瑰金扣镶紫水晶，萤石是蓝紫色的小点缀；都只占很小面积。
- **没有红色、没有青色**（红围巾已去掉；萤石不能画成绿青色）。
- **2.5 头身**：头约占身高 40%，身体短、四肢短而圆，形体圆润可爱；仍能想象跑、跳、闪避的动作。
- 深墨轮廓带手绘抖动，平涂，无渐变高光与写实光影；左侧暖色边光，暗部偏紫。
- 短刀为单刃、较短的工业割刀，不是大剑。
- 正侧面朝右、全身完整、斗篷与四肢和身体之间留空（便于拆层）；背景透明或纯白，没有深色背景、暗角或光晕。
