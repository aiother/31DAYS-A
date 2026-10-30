# 06 晶弦（玩家初始武器）设定图（GPT Image 2）

> **已废弃，永不采用（用户 2026-10-29）**：本文件属于原玩家方案（匠首连帽长斗篷、黑纱两点眼、2.5 头身、萤环与晶弦），只作历史记录，不作为任何形象的参考、基础或标准。见 `game/docs/art_style.md` 第 6.3 节。

用途：定“萤环与晶弦”的样子（art_style.md 第 6.2 节）：待机时十三枚萤石碎片绕腕；每次出手碎片散开再聚合——前摇流进手中扣成一把刀剑，生效时是笔直的硬刃，后摇散回手腕；光缝平时暗、命中与弹反时闪亮。这张是**武器设定图**，给部件拆分与特效任务作参考；游戏里碎片单独成图，缝中的光、刀光、拖尾与散合由代码特效实现。放进 `assets_src/inbox/art/weapon_starter/`。

**定稿依据**（用户 2026-10-26）：刃形比例照 `weapon_player_03`（细长、碎片清楚分开、细缝透光）；聚合与散开照 `weapon_player_04`（06b 探索稿）。06b 里画成表面闪电裂纹的“金缮光缝”不采用——光只沿碎片边界走。

**附参考图**：
- 风格参考：`assets_src/inbox/art/boss_overlook/BOSS_01.png`（只借线条与平涂）。
- 角色参考：`assets_src/inbox/art/player/player_01_3.png`。
- 刃形参考：`assets_src/inbox/art/weapon_starter/weapon_player_03.png`。
- 散合参考：`assets_src/inbox/art/weapon_starter/weapon_player_04.png`（只借聚合与散开两格的动态，不借它的表面裂纹与短宽刃形）。

尺寸建议：横图 1792×1024 或更宽（六格）。

## 提示词（整段复制）

```
Hand-drawn ink illustration for a 2D side-scrolling game, a weapon design sheet. Dark sepia ink outlines (#2b2420) with slight hand-drawn wobble and varying line weight. Flat colour fills with at most one light and one shadow tone, subtle ink bleed and paper texture, no gradients, no painterly rendering, no realistic lighting. Muted, low-saturation palette: ink #2b2420, paper #efe4cc, pearl #fbf6ec.

Style reference: match the attached reference images in line and flat colouring only; do not copy their shape.

Subject: the "Crystal String", the starting weapon of a small hooded hero. It is made of exactly THIRTEEN fluorite fragments in blue-violet (#7b84c9): NOT whole crystals with complete crystal shapes, but small broken shards with jagged, irregular edges, all different in size and shape, like pieces of one shattered stone. When assembled they form ONE sword with a short grip, a long slender straight blade and a sharp tip, the basic silhouette of a real sword; the broken edges of neighbouring fragments match each other like pieces of a puzzle, yet keep thin even gaps between them. Light lives ONLY in those gaps along the fragment borders: three or four main seams are slightly wider, the rest are thin lines; NO cracks drawn across the surface of the fragments, NO branching lightning patterns. Show a design sheet of six separate panels side by side, each showing only the hero's gloved hand (very dark navy sleeve #1f2740, dark glove) and the weapon, side view facing RIGHT:
1. IDLE: the thirteen fragments float in a loose ring around the WRIST (not the palm or fingers), faint soft bluish light between them. Not beads, not a chain.
2. FORMING: the fragments stream out of the wrist ring along a curved path into the closed fist and lock together into the sword, starting at the grip; the last few fragments are still flying in.
3. SLASH: the complete sword, perfectly STRAIGHT and rigid, long and slender, swung level with one clean arc of bluish light behind it; the seams are dim thin lines of soft bluish light (#b9c0ff).
4. HIT FLASH: the same straight sword at the instant it strikes: every seam between the fragments flares bright bluish-white at once, a few tiny sparks of light at the tip; the fragments themselves stay unchanged.
5. SCATTER: right after the swing, the sword bursts apart at its seams into the thirteen fragments, each leaving a short thin streak of light, spiralling back toward the wrist.
6. DOWNWARD STAB: the fragments gather from above into a shorter dagger-like blade in a reverse grip, pointing straight down, dim seams along the fragment borders.
While assembled the blade never bends, never curls, never droops; it is NOT a soft silk whip, rope, chain or string of beads, and NOT an electric or lightning weapon. Elegant, iconic, instantly readable at a small in-game size; bluish-white light (#b9c0ff), not purple, not teal, no gold.

Six panels on one sheet, evenly spaced, no labels, no text, no frame; transparent background (or plain flat pure white #ffffff background if transparency is unavailable); no dark background, no vignette, no glow or halo around the whole image. No red anywhere. No teal or cyan anywhere.
```

## 验收要点

- **碎片**：恰好十三枚，破碎、边缘参差、大小形状各不相同；**不是**完整的晶体。
- **萤环（待机）**：碎片绕在**手腕**上（不是手掌），淡光相连；不是珠串、不是链子。
- **刃形**：细长笔直的刀剑轮廓（握柄、刃身、刃尖），比例照 `weapon_player_03`，不是短宽的短剑。
- **光缝**：光**只沿碎片边界**，三四条主缝略宽；刃面上**没有**裂纹、没有分叉的闪电纹，不读成雷电。
- **明暗两态**：挥砍格里光缝是暗的细线；命中格里所有光缝一起闪亮，碎片本身不变。
- **散合**：聚合格碎片沿弧线流进手中扣合；散开格刃从缝处炸成碎片、短光痕螺旋飞回手腕；不乱。
- **刃是硬的**：组装后的刃始终笔直，弧线只在刀光里。
- **下刺**：反握短刃，笔直向下。
- **颜色**：碎片蓝紫、光偏蓝白；不紫、不青、不金；没有红色。
- 缩小到游戏里的大小仍一眼认得出；六格分开、无文字；背景透明或纯白，没有深色背景、暗角或光晕。
