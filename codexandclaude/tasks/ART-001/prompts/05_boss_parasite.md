# 05 寄生同伴者（Boss，GPT Image 2）

用途：验证寄生同伴者的 Boss 设计（art_style.md 第 6.2 节）：人与虫的两个前半身在腰部拼接，两头都有主导意识；人的一端哀求、可怜，虫的一端只有口器；军用水壶成了胃囊。**画风必须与其他实体统一**（第 6.0 节“实体共用一套视觉语言”）。放进 `assets_src/inbox/art/boss_parasite/`。

**先附风格参考图**：生成前把已认可的 `assets_src/inbox/art/boss_overlook/BOSS_01.png`（渴望俯视）作为参考图一起上传，只借它的线条、上色、配色与面甲画法，不借它的形状。第一轮（BOSS_02）没附参考图，人的一端画成了写实的动漫小孩、虫身画得油亮饱和，和其他敌人差得太远；第二轮（BOSS_02_1）附了参考图，画风已统一，但虫身仍偏亮偏粉、肉管偏多，本版已写死。

尺寸建议：横图 1536×1024 或更大。

## 提示词（整段复制）

```
Hand-drawn ink illustration for a 2D side-scrolling game. Dark sepia ink outlines (#2b2420) with slight hand-drawn wobble and varying line weight, thicker outer contour. Flat colour fills with at most one light and one shadow tone, subtle ink bleed and paper texture, no gradients, no painterly rendering, no realistic lighting. Low warm dusk sunlight from the LEFT: a thin warm rim light (#f4b860) on the left edges, shadows tinted cool violet (#7d4a8c). Muted, low-saturation palette: ink #2b2420, paper #efe4cc, dusk paper #f0cfb6, pearl #fbf6ec.

Style reference: match the attached reference image exactly in line, flat colouring, muted palette and the way the pale face-plate is drawn; do not copy its shape. This creature belongs to the same family of Silksong-style creatures.

Creature: "Parasite Companion", a boss — two FRONT halves joined at the waist into one compact body (about twice as long as it is tall), with a head at each end, both heads awake and in control. LEFT END: the front half of a small human deserter, drawn in the same creature language, NOT as a realistic or anime child: instead of a face it has a smooth round pale paper face-plate (#efe4cc) like the reference, with two large hollow dark eyes set in a pitiful, pleading slant and one small tear line, no nose, no mouth, no skin tone; at most a simple solid-ink silhouette of messy hair behind the plate, no hair strands; a plain worn grey-brown army jacket in flat colour with very few folds; two thin dark ink arms reaching forward to crawl, simple hands on the ground, a broken iron shackle on each wrist; this human end keeps the warm rim light. RIGHT END: the front half of a parasite, three or four smooth rounded carapace segments in a deep, dark, desaturated wine red (#6e1f3a), close to the ink in value, never bright, pink or magenta; matte flat fill with at most one thin dull sheen line per segment, no shiny highlights, not glossy, not fleshy, curving up and away; thin dark spindly legs tapering to sharp points, like the reference; its head is a rounded shell with no eyes, only a small round mouth ringed with pale pointed teeth; this parasite end takes no warm light. At the waist, an old military field canteen has grown in as its stomach, intact and true to life, cap visible, a few bold key features only, greyed out. Exactly two thin dark red flesh tubes (no more than two) run from the joint, one onto each half; they do not wrap around the canteen. Cute rounded proportions, clean readable silhouette, dark body with pale details; the pitiful human end against the mouth end is the point; eerie, no blood, no gore.

Full body, strict side view, the human end on the LEFT facing left (toward the player), the parasite end on the RIGHT, whole creature visible with margin, transparent background (or plain flat pure white #ffffff background if transparency is unavailable); no dark background, no vignette, no glow or halo around the creature. Single creature, no text, no frame. No teal or cyan anywhere.
```

## 验收要点

- **与其他实体统一**：线条、平涂、低饱和配色与渴望俯视、无色实体一致；放在一起像同一个游戏里的同一类东西。
- **人的一端**：不是写实或动漫小孩；脸是纸色面甲，只有两只哀求的空洞大眼和一道泪痕，没有鼻子、嘴和肤色；头发最多是一块墨色剪影；军装平涂、褶皱很少；细细的墨色手臂撑地爬行；手腕有断开的镣铐；有暖色边光。
- **虫的一端**：三四节圆润的哑光暗红硬壳，颜色接近墨的深度，不亮、不粉、没有高光；细尖的墨色腿；虫头没有眼，只有一圈利齿小口器；没有边光。
- **物件**：接合处一只完整、真实的军用水壶，褪成灰色，细节只留几处关键特征。
- **肉管**：恰好两条细的暗红肉管，从接合处各伸向一半，不缠水壶。
- **比例**：身体紧凑，长约为高的两倍，不要拖成长虫。
- 人的一端朝左（面向玩家）、全身完整；背景透明或纯白，没有深色背景、暗角或光晕；没有青色。
