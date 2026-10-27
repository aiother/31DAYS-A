# 06 晶弦（玩家初始武器）设定图（GPT Image 2）

用途：定“萤环与晶弦”的样子（art_style.md 第 6.2 节）：待机时十三枚萤石碎片绕腕，攻击时碎片在手中拼成一把刀剑。这张是**武器设定图**，给部件拆分与特效任务作参考；游戏里碎片单独成图，缝中的光、刀光与拖尾由代码特效实现。放进 `assets_src/inbox/art/weapon_starter/`。

**附参考图**：
- 风格参考：已认可的 `assets_src/inbox/art/boss_overlook/BOSS_01.png`（只借线条与平涂）。
- 角色参考：已认可的玩家设定图 `assets_src/inbox/art/player/player_01_3.png`（让手、袖子、碎片的颜色与玩家一致）。
- 上一轮参考（可选）：`assets_src/inbox/art/weapon_starter/weapon_player_02.png`，它的碎片质感与拼合方式已经对了。

前两轮的问题：第一轮（`weapon_player_01`）碎晶太完整、间隔太大，读成了串珠；第二轮（`weapon_player_02`，用户在生成时补了碎片、契合、刀剑轮廓、十三枚、绕腕等要求）碎片与拼合都对了，但直刃与挥砍那两格的刃身弯了，碎片也多于十三枚。本版把用户补的要求写进来，并要求刃身始终笔直。

尺寸建议：横图 1536×1024 或更大。

## 提示词（整段复制）

```
Hand-drawn ink illustration for a 2D side-scrolling game, a weapon design sheet. Dark sepia ink outlines (#2b2420) with slight hand-drawn wobble and varying line weight. Flat colour fills with at most one light and one shadow tone, subtle ink bleed and paper texture, no gradients, no painterly rendering, no realistic lighting. Muted, low-saturation palette: ink #2b2420, paper #efe4cc, pearl #fbf6ec.

Style reference: match the attached reference images in line and flat colouring only; do not copy their shape.

Subject: the "Crystal String", the starting weapon of a small hooded hero. It is made of exactly THIRTEEN fluorite fragments in blue-violet (#7b84c9): NOT whole crystals with complete crystal shapes, but small broken shards with jagged, irregular edges, all different in size and shape, like pieces of one shattered stone. Show a design sheet of four separate panels side by side, each showing only the hero's gloved hand (very dark navy sleeve #1f2740, dark glove) and the weapon, side view facing RIGHT:
1. IDLE: the thirteen fragments float in a loose ring around the WRIST (not the palm or fingers), slowly orbiting, faint soft bluish light (#b9c0ff) between them. Not beads, not a chain.
2. SLASH: the thirteen fragments have flown into the hand and fitted together into ONE sword: a short grip in the fist, then a straight blade and a sharp tip, with the basic silhouette of a real sword. The broken edges of neighbouring fragments match each other like pieces of a puzzle, yet keep thin even gaps between them, and soft bluish light (#b9c0ff) shines through every gap. The blade is perfectly STRAIGHT and rigid, held level, a clean horizontal slash.
3. SWEEP: the same perfectly straight, rigid sword, now swung in a wide arc from high to low; the blade itself stays straight, and the curve exists only in the fading arc of bluish light it leaves behind, with a few tiny sparks of light.
4. DOWNWARD STAB: the fragments fitted into a shorter dagger-like blade held in a reverse grip, pointing straight down, as in a downward thrust; same matching broken edges with thin glowing gaps.
The weapon follows real sword motion: it never bends, never curls, never droops; it is NOT a soft silk whip, rope, chain or string of beads. Elegant, iconic, instantly readable at a small in-game size; bluish-white light (#b9c0ff), not purple, not teal.

Four panels on one sheet, evenly spaced, no labels, no text, no frame; transparent background (or plain flat pure white #ffffff background if transparency is unavailable); no dark background, no vignette, no glow or halo around the whole image. No red anywhere. No teal or cyan anywhere.
```

## 验收要点

- **碎片**：恰好十三枚，破碎、边缘参差、大小形状各不相同；**不是**完整的晶体。
- **萤环（待机）**：碎片绕在**手腕**上（不是手掌），淡光相连；不是珠串、不是链子。
- **拼成刀剑**：握柄、笔直的刃身、刃尖，一眼是一把剑；碎片缺口互相契合，又留着均匀的细缝，缝里透出偏蓝的光。
- **刃是硬的**：直刃与挥砍两格里刃身都**笔直**，弧线只出现在身后的刀光里；不弯、不卷、不垂。
- **下刺**：碎片拼成反握的短刃，笔直向下。
- **颜色**：碎片蓝紫、光偏蓝白；不是紫、不是青；没有红色。
- 缩小到游戏里的大小仍一眼认得出；四格分开、无文字；背景透明或纯白，没有深色背景、暗角或光晕。
