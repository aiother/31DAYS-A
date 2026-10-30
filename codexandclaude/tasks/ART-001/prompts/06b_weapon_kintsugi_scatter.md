# 06b 晶弦探索稿：金缮光缝 + 散合（GPT Image 2）

> **已废弃，永不采用（用户 2026-10-29）**：本文件属于原玩家方案（匠首连帽长斗篷、黑纱两点眼、2.5 头身、萤环与晶弦），只作历史记录，不作为任何形象的参考、基础或标准。见 `game/docs/art_style.md` 第 6.3 节。

**探索稿，已收尾**：这是用户 2026-10-26 要求看的 B + D 合并方案（金缮式光缝 + 每次挥砍散开再聚合）。试做图为 `assets_src/inbox/art/weapon_starter/weapon_player_04.png`。**采纳**：散合（聚合、散开、连段空中重扣）；**不采纳**：刃面上的闪电状裂纹与短宽刃形。金缮改为“光只沿碎片边界、命中与弹反时闪亮”。定稿内容已并入 art_style.md 与 06，本文件只作记录，不再用于生成。

## 方案要点

- **B · 金缮式光缝**：缝里的光像金缮修补的痕迹——三四条**主缝**较宽、宽窄有变化、带一点分叉，其余是细缝；主缝交汇处是更亮的光点。读成“被光缀合起来的碎刃”。只在主缝上做变化，避免糊成一片。
- **D · 散合**：生效帧里刃是硬的、笔直的；出手前和收招后碎片会散开：
  - **聚合**（前摇）：十三枚碎片从手腕的萤环里飞出，沿一条弧线流进手中扣成剑，光缝从握柄到刃尖依次亮起；
  - **挥砍**（生效）：笔直的硬刃挥出，身后一道刀光；
  - **散开**（后摇）：刃从缝处炸开成十三枚碎片，每片拖着一道短光痕，沿螺旋飞回手腕——这些光痕就是拖尾；
  - **连段**：二段攻击时，碎片从散开的位置直接在空中重新扣成剑，不必先回手腕；
  - **下刺**：碎片从上方汇聚成反握短刃向下刺；
  - **弹反**：接触瞬间所有光缝一亮，碎片在缝处微微震开又扣回。
- 约束：聚合与散开只放在现有动作的前摇与后摇里，生效帧的刃形与攻击判定一致，**只改外观，不改玩法**；散开的光痕要短，混战里不能乱。

## 参考与差异

- 日本金缮：裂缝成为装饰——借“修补痕迹即美感”，不用金色（金色属于天人与成长），用萤石光。
- 《死神》千本樱：刀身散开再聚合——借散合的动作语言，但只有十三枚碎片、只在前后摇出现，不做漫天花瓣。
- 《最终幻想 XV》幻影武器：召唤与碎裂——借节奏，避开它“整把蓝晶一次性碎裂消失”的样子：我们的碎片有序飞回手腕、并且会重新扣合。

尺寸建议：横图 1792×1024 或更宽（五格）。

## 提示词（整段复制）

```
Hand-drawn ink illustration for a 2D side-scrolling game, a weapon design sheet. Dark sepia ink outlines (#2b2420) with slight hand-drawn wobble and varying line weight. Flat colour fills with at most one light and one shadow tone, subtle ink bleed and paper texture, no gradients, no painterly rendering, no realistic lighting. Muted, low-saturation palette: ink #2b2420, paper #efe4cc, pearl #fbf6ec.

Style reference: match the attached reference images in line and flat colouring only; do not copy their shape.

Subject: the "Crystal String", the starting weapon of a small hooded hero: exactly THIRTEEN broken fluorite fragments in blue-violet (#7b84c9), jagged irregular shards of different sizes, NOT whole crystals. When they fit together into a sword, the seams between them are lit like kintsugi repair: three or four main seams are wider, varying in width with small branching cracks, and glow bright bluish light (#b9c0ff) with brighter points where seams meet; the other seams are thin glowing lines. It reads as a broken blade held together by light. Show a design sheet of five separate panels side by side, each showing only the hero's gloved hand (very dark navy sleeve #1f2740, dark glove) and the weapon, side view facing RIGHT:
1. IDLE: the thirteen fragments float in a loose ring around the WRIST (not the palm), faint light between them.
2. FORMING: the fragments stream out of the wrist ring along a curved path into the closed fist and lock together into a sword; the seams light up one after another from the grip toward the tip, the last few fragments still flying in.
3. SLASH: the complete sword, perfectly STRAIGHT and rigid, a short grip, a straight blade and a sharp tip, the kintsugi seams glowing, swung level with one clean arc of bluish light behind it.
4. SCATTER: right after the swing, the sword bursts apart at its seams into the thirteen fragments, each leaving a short thin streak of light, spiralling back toward the wrist.
5. DOWNWARD STAB: the fragments gather from above into a short dagger-like blade in a reverse grip, pointing straight down, kintsugi seams glowing.
While assembled the blade never bends; it is NOT a soft silk whip, rope, chain or string of beads. Elegant, iconic, instantly readable at a small in-game size; bluish-white light (#b9c0ff), not purple, not teal, no gold.

Five panels on one sheet, evenly spaced, no labels, no text, no frame; transparent background (or plain flat pure white #ffffff background if transparency is unavailable); no dark background, no vignette, no glow or halo around the whole image. No red anywhere. No teal or cyan anywhere.
```

**附参考图**：`BOSS_01.png`（风格）、`player_01_3.png`（角色）、`weapon_player_03.png`（已对的刃形与拼合）。

## 验收要点

- **金缮光缝**：三四条主缝较宽、有宽窄与分叉、交汇处更亮；其余是细缝；整体读成“被光缀合的碎刃”，不糊。
- **聚合**：碎片沿弧线从手腕流进手中扣合，光缝由柄到尖依次亮起。
- **挥砍**：刃笔直、硬，弧线只在刀光里。
- **散开**：刃从缝处炸成十三枚碎片，短光痕螺旋飞回手腕；不乱。
- **下刺**：反握短刃笔直向下。
- 碎片恰好十三枚、破碎不完整；光偏蓝白，不紫、不青、不金；五格分开、无文字；背景透明或纯白。
