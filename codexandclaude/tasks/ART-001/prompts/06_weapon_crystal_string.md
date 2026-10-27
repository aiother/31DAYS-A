# 06 晶弦（玩家初始武器）设定图（GPT Image 2）

用途：定“萤环与晶弦”的样子（art_style.md 第 6.2 节）：待机时碎晶绕腕，攻击时碎晶射出、光丝绷直成分节光刃。这张是**武器设定图**，用来给特效任务和部件拆分作参考；游戏里的光丝、光刃与拖尾由代码特效实现，碎晶单独成图。放进 `assets_src/inbox/art/weapon_starter/`。

**附参考图**：
- 风格参考：已认可的 `assets_src/inbox/art/boss_overlook/BOSS_01.png`（只借线条与平涂）。
- 角色参考：01 定稿后的玩家设定图（让手、斗篷、碎晶的颜色与玩家一致）。01 还没定稿时可以先不附。

尺寸建议：横图 1536×1024 或更大。

## 提示词（整段复制）

```
Hand-drawn ink illustration for a 2D side-scrolling game, a weapon design sheet. Dark sepia ink outlines (#2b2420) with slight hand-drawn wobble and varying line weight. Flat colour fills with at most one light and one shadow tone, subtle ink bleed and paper texture, no gradients, no painterly rendering, no realistic lighting. Muted, low-saturation palette: ink #2b2420, paper #efe4cc, pearl #fbf6ec.

Style reference: match the attached reference image in line and flat colouring only; do not copy its shape.

Subject: the "Crystal String", the starting weapon of a small hooded hero, shown as a design sheet of four separate panels side by side, each showing only the hero's gloved hand (very dark navy sleeve #1f2740, dark glove) and the weapon, side view facing RIGHT:
1. IDLE: five small elongated, faceted blue-violet fluorite crystal shards (#7b84c9) floating in a loose ring around the wrist without touching it, linked shard to shard by one faint thread of soft bluish light (#b9c0ff). Not beads, not a chain.
2. STRAIGHT SLASH: the five shards have shot out from the wrist in a straight line, about four times the length of the forearm, and the thread of light has snapped taut between them, forming one rigid, segmented blade of crystal and light; crisp, clean edges, the shards evenly spaced, a thin bright bluish light filling the gaps.
3. CURVED SLASH: the same blade bent into a gentle arc, as in a second sweeping strike, a fading ribbon of bluish light trailing behind it.
4. DOWNWARD SPIKE: the shards gathered below the hand into one sharp downward spike of crystal and light, as in a downward thrust.
The blade is a rigid line of crystal segments, NOT a soft silk whip or rope. Elegant, iconic, instantly readable at a small in-game size; bluish-white light, not purple, not teal.

Four panels on one sheet, evenly spaced, no labels, no text, no frame; transparent background (or plain flat pure white #ffffff background if transparency is unavailable); no dark background, no vignette, no glow or halo around the whole image. No red anywhere. No teal or cyan anywhere.
```

## 验收要点

- **萤环（待机）**：五片棱形萤石碎晶悬浮绕腕，不贴手腕，一缕淡光丝相连；不是珠串、不是链子。
- **直刃**：碎晶射出排成一直线，光丝绷直，成为一把**硬的**分节晶刃，边缘干净，长约前臂的四倍。
- **弧刃**：同一把刃弯成弧，身后一条渐隐的光带。
- **下刺**：碎晶在手下聚成一根尖刺。
- **不是丝鞭**：看上去是一节一节的晶体硬刃，不是软绳、软丝。
- **颜色**：碎晶蓝紫、光偏蓝白；不是紫、不是青；没有红色。
- 缩小到游戏里的大小仍一眼认得出；四格分开、无文字；背景透明或纯白，没有深色背景、暗角或光晕。
