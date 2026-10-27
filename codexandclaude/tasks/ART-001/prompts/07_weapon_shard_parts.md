# 07 晶弦碎片部件图（GPT Image 2）

用途：出晶弦的**游戏用部件**（art_style.md 第 6.2 节“萤环与晶弦”，asset_spec.md 第 3 节）：十三枚碎片各自的单独图，加一张拼好的整刃作拼合位置参考。**只画碎片本身**——光缝、光的明暗、命中闪亮、绕腕、聚合、散开、刀光与拖尾全部由代码与特效实现，不在图里画。

概念到此收尾（用户 2026-10-26）：刃形比例照 `weapon_player_03`，散合动态照 `weapon_player_04`、`weapon_player_06`；那几张只作概念参考，不拆部件。

放进 `assets_src/inbox/art/weapon_starter/`，文件名建议 `shard_parts_01.png` 起。Claude 取件后把每枚碎片切成 `weapon_starter_part_shard_01.png`～`_13.png`，整刃图存作拼合参考。

**附参考图**：
- 风格参考：`assets_src/inbox/art/boss_overlook/BOSS_01.png`（只借线条与平涂）。
- 刃形参考：`assets_src/inbox/art/weapon_starter/weapon_player_03.png`（只借刃的细长比例与碎片拼法；**不要**借它缝里的光）。
- **不要**附 `weapon_player_04` / `weapon_player_06`：它们会把刃面裂纹和短宽的刃形带回来。

尺寸建议：横图 2048×1024 或更大（部件要留足间距，方便切图）。

## 提示词（整段复制）

```
Hand-drawn ink illustration for a 2D side-scrolling game, a clean game-asset parts sheet. Dark sepia ink outlines (#2b2420) with slight hand-drawn wobble and varying line weight. Flat colour fills with at most one light and one shadow tone, subtle paper texture, no gradients, no painterly rendering, no realistic lighting. Muted, low-saturation palette.

Style reference: match the attached reference images in line and flat colouring only; take the slender sword proportions from the blade reference, but do NOT copy any glowing light from it.

Subject: the thirteen parts of the "Crystal String", a sword made of broken fluorite fragments in muted blue-violet (#7b84c9). Each fragment is a small broken shard with jagged, irregular edges, all different in size and shape, like pieces of one shattered stone, NOT whole crystals; each has a simple flat fill with one lighter facet and one darker facet and a dark ink outline. NO glow, NO light inside or around the fragments, NO cracks drawn across their surfaces, NO lightning patterns, NO effects.

TOP ROW: the assembled sword, side view, pointing RIGHT, with no hand: a short grip made of two small fragments, then a long slender perfectly straight blade made of ten fragments, and one long fragment forming the sharp tip — thirteen fragments in total. The broken edges of neighbouring fragments match each other like puzzle pieces, with thin even empty gaps between them (the gaps are plain background, not lit). Proportions: the blade is long and slender, about eight times as long as it is wide, like a rapier-length straight sword, not a short wide dagger.

BOTTOM ROWS: the same thirteen fragments shown again separately, each one isolated, in the same order as in the sword from grip to tip, laid out in a neat grid with generous empty space between them so each can be cut out cleanly; each fragment keeps exactly the same shape, size and orientation as in the assembled sword.

Transparent background (or plain flat pure white #ffffff background if transparency is unavailable); no dark background, no vignette, no glow or halo. No labels, no numbers, no text, no frame, no hand, no character. No red anywhere. No teal or cyan anywhere.
```

## 验收要点

- **数量**：整刃恰好由十三枚碎片组成（握柄两枚、刃身十枚、刃尖一枚），下面单独排出的也恰好十三枚，顺序和整刃一致。
- **形状**：每枚都是破碎、边缘参差、大小各异的碎片，不是完整晶体；单独排出的每枚与整刃里对应的那枚**形状、大小、朝向一致**（能直接拼回去）。
- **拼合**：整刃里碎片缺口互相契合，留着均匀的**空缝**（缝是背景，不发光）。
- **比例**：刃细长笔直，长约宽的八倍，照 `weapon_player_03`；不是短宽的短剑。
- **干净**：没有光、没有光晕、没有表面裂纹、没有闪电纹、没有特效；平涂，一层亮面一层暗面，深墨轮廓。
- **好切**：部件之间留足间距；没有手、没有文字和编号；背景透明或纯白。
- 颜色只有低饱和的萤石蓝紫与墨线；没有红色、没有青色。

## 代码负责的部分（不在图里）

光缝（只沿碎片边界、三四条主缝略宽）、平时暗与命中 / 弹反时闪亮、萤环绕腕、前摇聚合、后摇散开、连段空中重扣、刀光与拖尾——见 art_style.md 第 6.2 节动作表，由后续特效任务实现。
