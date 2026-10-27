# 08 天人战士设定图（GPT Image 2）

用途：定天人战士的形象（art_style.md 第 6.0 节阶层、第 6.2 节天人战士）：世界最上层的人，被逼疯后戴上了总指挥下发的微笑面具；正在被同化，黑袍下摆已化成墨。生成 3～4 张，挑一张；放进 `assets_src/inbox/art/tian/`。

**附参考图**：
- 风格参考：`assets_src/inbox/art/boss_overlook/BOSS_01.png`（只借线条与平涂）。
- 人形参考：已认可的玩家设定图 `assets_src/inbox/art/player/player_01_3.png`（只借 2.5 头身的比例与画法，**不要**借斗篷、面纱与颜色）。

**两张面具**：先生成完好面具版；挑定后用它作参考图，把提示词里 `[MASK]` 换成“裂开”那句，再生成一张只改面具的低血量版。

尺寸建议：竖图 1024×1536 或更大。

## 提示词（整段复制，替换方括号）

```
Hand-drawn ink illustration for a 2D side-scrolling game. Dark sepia ink outlines (#2b2420) with slight hand-drawn wobble and varying line weight, thicker outer contour. Flat colour fills with at most one light and one shadow tone, subtle ink bleed and paper texture, no gradients, no painterly rendering, no realistic lighting. Low warm dusk sunlight from the LEFT: a thin warm rim light (#f4b860) on the left edges, shadows tinted cool violet (#7d4a8c). Muted, low-saturation palette: ink #2b2420, paper #efe4cc, dusk paper #f0cfb6, pearl #fbf6ec.

Style reference: match the attached reference images in line, flat colouring and the cute 2.5-heads proportions only; do not copy the player's cape, veil or colours, and do NOT give this character a pale face-plate.

Character: a "Tian warrior", one of the hereditary ruling elite of this world, driven mad and now forced to smile, in cute chibi proportions: exactly 2.5 heads tall, a big round head, short body and limbs, yet made to look tall and noble by a tall pointed gold crown, a high stiff collar and a floor-length black robe (#221c22). The robe has thin gold trim (#d9a03a) laid out as clean right-angled geometric lines like a circuit pattern — regal and high-tech at once, NOT lightning, NOT zigzags. Polished obsidian plates (#1a1620, one pale sheen line each) on the shoulders and the collar. The robe's hem and the ends of the sleeves have already dissolved into dripping ink, so it is impossible to tell where the robe ends and the ink begins; the hands and feet are ink-black and turning into small claws. [MASK] It holds a standard-issue polearm in the near hand: a long straight segmented shaft with thin gold bands, a long slender straight blade with one gold line of light along it. Stiff, upright, perfectly composed posture; uniform, identical to every other Tian warrior. No blood, no gore.

Full body, strict side view facing LEFT (toward the player), standing pose, the polearm held upright beside the body, whole figure visible with margin, transparent background (or plain flat pure white #ffffff background if transparency is unavailable); no dark background, no vignette, no glow or halo around the character. Single character, no text, no frame. No teal or cyan anywhere.
```

`[MASK]` 两种填法（一次只用一种）：

- 完好（先生成这个）：`Its face is completely covered by the issued smile mask: a smooth round gold mask (#d9a03a) with two obsidian eye slits curved upward like closed happy eyes and a fixed, calm, slightly too wide smile carved in obsidian; a small deep red ruby (#8e1c2e) set in the middle of the forehead, NOT glowing.`
- 裂开（低血量版，用完好版作参考图）：`Its face is covered by the same issued smile mask, but a jagged crack now runs through the mask from the brow down past the smile, and through the crack there is only black ink and darkness, no face behind it; the small deep red ruby (#8e1c2e) still sits on the forehead, NOT glowing. Match the reference image exactly in silhouette, colours and proportions; change only the mask.`

## 验收要点

- **2.5 头身**，但靠高冠、高立领、及地黑袍显得高大、高贵；不是修长的成人比例。
- **黑袍**：近黑色，金色滚边是干净的直角几何纹（像电路），**不是**闪电或锯齿；肩甲与领甲是带一道光泽的黑曜石。
- **化墨**：袍子下摆与袖口化成滴落的墨，分不清袍与墨；手脚是墨色的小爪。
- **微笑面具**：金色、弯月眼缝、过于平静的固定微笑；额心一颗**不发光**的深红红宝石（发光由特效实现）；**没有**纸色面甲。
- **裂开版**：只有面具多了一道裂缝，缝里只有墨、没有脸；其余与完好版完全一致。
- **武器**：分段长柄、细长直刃、刃上一道金色光线。
- 配色只有黑、金、黑曜石、深红红宝石与墨；红宝石只占很小面积；没有青色。
- 正侧面朝左（面向玩家）、全身完整；背景透明或纯白，没有深色背景、暗角或光晕。
