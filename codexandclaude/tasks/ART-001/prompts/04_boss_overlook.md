# 04 渴望俯视（Boss，GPT Image 2）

用途：验证渴望俯视的 Boss 设计（art_style.md 第 6.2 节）：住在精致皮鞋壳里的飞虫，金色只在鞋带孔，胸前挂旧工牌，面甲随高低变脸。先生成“蔑视”版 3～4 张，挑一张；再用同一张作参考图，把提示词里的面甲那一句换成“谄媚”版生成。放进 `assets_src/inbox/art/boss_overlook/`。

尺寸建议：横图 1536×1024 或更大。

## 提示词（整段复制）

```
Hand-drawn ink illustration for a 2D side-scrolling game. Dark sepia ink outlines (#2b2420) with slight hand-drawn wobble and varying line weight, thicker outer contour. Flat colour fills with at most one light and one shadow tone, subtle ink bleed and paper texture, no gradients, no painterly rendering, no realistic lighting. Low warm dusk sunlight from the LEFT: a faint, half-width warm rim light (#f4b860) on the left edges, shadows tinted cool violet (#7d4a8c). Muted, low-saturation palette: ink #2b2420, paper #efe4cc, dusk paper #f0cfb6, pearl #fbf6ec.

Creature: "Overlook", a boss in the style of Silksong's creatures — a small flying creature that lives inside one polished leather dress shoe, the kind worn by the people who once stepped on it. The shoe is its shell: an elegant men's oxford, intact and true to life, glossy black leather with one or two pale sheen arcs, a paler sole facing DOWN, a low heel, neat stitching; keep only a few bold key features of the shoe so it reads at a small in-game size. A smooth pale paper face-plate (#efe4cc) rises out of the shoe's opening: no mouth, no nose, only two hollow dark eyes. [FACE] A pair of thin, pale, translucent insect wings rises from the opening behind the face-plate; four thin spindly legs tapering to sharp points hang below the sole. Its only colour is muted gold (#d9a03a) on the shoe's lace eyelets, nowhere else. The only human thing left is a small worn staff ID badge on a lanyard hanging from under the face-plate, drawn a little more carefully than the rest, with a tiny blank photo square and two printed lines. Cute rounded proportions, a clean readable silhouette, dark body with pale details; eerie, not gory.

Full body, strict side view, the shoe's toe pointing LEFT (toward the player), whole creature visible with margin, transparent background (or plain flat pure white #ffffff background if transparency is unavailable); no dark background, no vignette, no glow or halo around the creature. Single creature, no text, no frame. No teal or cyan anywhere.
```

`[FACE]` 两种填法（一次只用一种）：

- 蔑视（高于玩家，先生成这个）：`The face-plate is tilted up arrogantly and its hollow eyes are narrowed into two thin contemptuous slits, looking down.`
- 谄媚（低于玩家，用蔑视版作参考图再生成）：`The face-plate is bowed low and its hollow eyes are curved upward into two fawning crescents, a single bead of sweat on the plate. Match the reference image exactly in silhouette, colours and proportions; change only the face-plate.`

## 验收要点

- **皮鞋壳**：一只完整、真实的精致男士皮鞋（牛津鞋），鞋底朝下；物件考究，不畸形；细节只留几处关键特征。
- **丝之歌式造型**：浅色面甲（只有两只空洞眼）、薄翅、细尖的腿；深色身体浅色细节；圆润可爱。
- **唯一的颜色**：成长金只在鞋带孔上，别处没有。
- **人的遗存**：胸前一张小小的旧工牌，画得比其余部分具体，一眼认出。
- **表情**：蔑视版眼睛眯成两条缝、面甲上扬；谄媚版面甲低垂、眼睛弯成两道弧、冒汗；两版其余部分完全一致。
- **光**：左侧只有一条弱的暖色边光。
- 鞋尖朝左（面向玩家）、全身完整；背景透明或纯白，没有深色背景、暗角或光晕；没有青色。
