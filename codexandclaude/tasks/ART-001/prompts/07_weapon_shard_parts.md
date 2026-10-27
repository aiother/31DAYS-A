# 07 晶弦整刃（部件原图，GPT Image 2）

用途：出晶弦的**部件原图**——**一把完整的刃**（art_style.md 第 6.2 节“萤环与晶弦”，asset_spec.md 第 3 节）。ART-002 用切割工具把它沿参差的折线切成十三片（握柄两片、刃身十片、刃尖一片）并补切口墨线，所以图里**不要画缝、不要画碎片分界**，也**不要画任何光**——光缝、明暗两态、命中闪亮、绕腕、聚合、散开、刀光与拖尾全部由代码与特效实现。

为什么改成整刃（用户 2026-10-26）：上一版要求一张图里同时画“拼好的整刃 + 十三枚单独碎片”，试做图 `shard_parts_01` 的整刃只分得出 8 块、单独排开的有 15 块，形状也对不上，切不出能拼回去的碎片。由工具切，片数与契合都有保证。

第一把整刃（`blade_whole_01`）连成一体、干净，菱形柄头与菱形护手很好（呼应玩家领口的菱形扣），**保留**；但刃太细（长约为宽的 20 倍），游戏里约 60 px 长时只剩 3 px 宽，切成碎片后看不出形状，本版把刃宽写死。

放进 `assets_src/inbox/art/weapon_starter/`，文件名接着 `blade_whole_02.png`。

**附参考图**：
- 风格参考：`assets_src/inbox/art/boss_overlook/BOSS_01.png`（只借线条与平涂）。
- 造型参考：`assets_src/inbox/art/weapon_starter/blade_whole_01.png`（只借菱形柄头、菱形护手与燧石切面；**不要**借它的细刃比例）。
- 不再附 `weapon_player_03`：它的刃也偏细，会把比例拉回去。
- **不要**附 `weapon_player_04` / `weapon_player_06`：它们会把刃面裂纹和短宽的刃形带回来。

尺寸建议：横图 2048×512 或更宽（刃横放，左右留白）。

## 提示词（整段复制）

```
Hand-drawn ink illustration for a 2D side-scrolling game, a clean single game asset. Dark sepia ink outlines (#2b2420) with slight hand-drawn wobble and varying line weight, thicker outer contour. Flat colour fills with at most one light and one shadow tone, subtle paper texture, no gradients, no painterly rendering, no realistic lighting. Muted, low-saturation palette.

Style reference: match the attached reference images in line and flat colouring only; take the diamond pommel, diamond crossguard and flint-like facets from the sword reference, but NOT its thin blade proportions; follow the proportions written below.

Subject: ONE complete, unbroken sword blade made of fluorite stone in muted blue-violet (#7b84c9), side view, lying horizontally and pointing RIGHT, with no hand and no character: on the left a small diamond-shaped faceted pommel, a short grip, and a small diamond-shaped faceted crossguard; then a perfectly straight, BROAD blade ending in a sharp tip. Blade proportions are strict: the blade (from crossguard to tip) is only about EIGHT times as long as it is wide; its width stays almost constant along its length and then narrows only in the last fifth into the tip; it is a broad longsword blade, NOT a thin rapier, NOT a needle, NOT a skewer. The blade is clearly wider than the grip. Its surface looks like rough broken stone: a few large flat facets in one lighter and one darker tone of the same blue-violet, like a chipped flint blade, with slightly irregular, faintly jagged edges along the outline. It is ONE solid piece: NO gaps, NO separate fragments, NO seams, NO cracks drawn across the surface, NO lines dividing it into segments, NO lightning patterns. NO glow, NO light inside or around it, NO effects, NO trails.

Centered with generous empty space around it. Transparent background (or plain flat pure white #ffffff background if transparency is unavailable); no dark background, no vignette, no glow or halo. No labels, no numbers, no text, no frame. No red anywhere. No teal or cyan anywhere.
```

## 验收要点

- **一整把**：柄头、握柄、护手、宽而笔直的刃身、刃尖连成一体；**没有**缝、没有碎片分界、没有分节线（切割交给工具）。
- **比例（硬性）**：从护手到刃尖，刃长只有刃宽的**约八倍**；刃宽沿全长基本不变，只在最后五分之一收成刃尖；是宽刃长剑，**不是**细剑、不是针；刃明显比握柄宽。
- **柄头与护手**：保留 `blade_whole_01` 的菱形柄头与菱形护手（呼应玩家领口的菱形扣）。
- **质感**：像打制过的燧石刃——几块大的平切面，一亮一暗两层蓝紫；轮廓边缘略带参差；深墨外轮廓。
- **干净**：没有光、没有光晕、没有表面裂纹、没有闪电纹、没有特效与拖尾。
- 横放朝右、四周留白；背景透明或纯白；没有文字；没有红色、没有青色。

## 工具与代码负责的部分（不在图里）

切成十三片与切口墨线（ART-002 切割工具）；光缝（只沿碎片边界、三四条主缝略宽）、平时暗与命中 / 弹反时闪亮、萤环绕腕、前摇聚合、后摇散开、连段空中重扣、刀光与拖尾（后续特效任务）——见 art_style.md 第 6.2 节动作表与 asset_spec.md 第 3 节。
