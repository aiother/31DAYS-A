# 03 无色实体（GPT Image 2）

用途：验证“逐级去人化”与“人的遗存”（art_style.md 第 6.1 节）：无色实体是否已是非人的小生物——人与生前物件被压成一体，只剩**一处**生前最重要的部分，让玩家认出“这曾经是人”；并与玩家一眼分开。生成 3～4 张，挑一张；放进 `assets_src/inbox/art/colorless/<区域>/`。

**按区域填三处**：`[OBJECT]` 换成该区域一件生前熟悉的物品，`[FORM]` 换成它和人一起被压成的形态，`[REMNANT]` 换成留下的那一处人的部分（一段躯体、一件衣服或饰物，甚至一撮头发，因个体而异）。例：

| 区域 | [OBJECT] | [FORM] | [REMNANT] 示例 |
| --- | --- | --- | --- |
| 荒地 | a shovel | a little shelled crawler on spindly legs; the shovel blade juts out under its face-plate as a jaw and the shaft is set into its back | a rough human hand that became one foreleg |
| 田野 | a hoe | a bird-like thing that keeps pecking the ground, its beak the hoe blade | a straw hat stuck to its back |
| 逆时战场 | a rifle butt | a flat thing that scuttles sideways under the rifle butt like a shell | a tuft of human hair |

尺寸建议：横图 1536×1024 或更大（形态低矮）。

## 提示词（整段复制，替换方括号）

```
Hand-drawn ink illustration for a 2D side-scrolling game. Dark sepia ink (#2b2420) with slight hand-drawn wobble and varying line weight, thicker outer contour, subtle ink bleed and paper texture, no gradients, no painterly rendering, no realistic lighting. A compressed, colourless remnant of a person: no colour of its own and no rim light, darker ink in the shadows instead.

Creature: a "colourless entity" — a person and [OBJECT], the thing they used every day, compressed together into one small creature that is no longer human in shape: [FORM]. The object has grown into its body as a working part, not held. The object stays intact and true to life: correct proportions and construction, crisp believable details (screws, hinges, keys, stitching), never melted, bent, stretched or broken into unrecognisable pieces; keep only three to five bold key features of the object so it still reads at a small in-game size, simplify rows of repeated parts (keys, gears) into a few large shapes; it sits where its function suggests (a blade becomes the jaw, a handle sits on the back like a grip, a flat base becomes the belly plate, a row of keys becomes teeth). Drawn in the style of Silksong's creatures: a smooth, rounded carapace of solid ink with one or two pale sheen arcs, a blank pale paper face-plate: no face, no eyes, no features at all, thin spindly legs tapering to sharp points, a clean readable silhouette with dark body and pale details, cute rounded proportions. Very little detail on the body. The only human thing left is [REMNANT], drawn a little more carefully than the rest so it reads at once as having belonged to a person. The object and the remnant are greyed out (muted grey, desaturated). It moves mechanically, repeating the motion of its old work; empty, no expression, no gore.

Full body, strict side view facing LEFT (toward the player), whole creature visible with margin, legs kept apart where possible, transparent background (or plain flat pure white #ffffff background if transparency is unavailable); no dark background, no vignette, no glow or halo around the creature. Single creature, no text, no frame. No colours other than ink, paper and the greyed object and remnant; no teal or cyan.
```

## 验收要点

- **非人**：一眼看去是一只小生物，不是人形；剪影低矮、简洁、好读。
- **丝之歌式造型**：圆润光滑的墨色硬壳、空白的纸色面甲（没有眼）、细长尖腿；深色身体、浅色细节；圆润可爱。
- **物件长进身体**：生前物件成为它的颚、喙、壳或肢，看得出原来是什么物件。
- **物件考究**：物件完整、比例真实、结构准确；按原功能安放；不熔化、不弯折、不拉伸。
- **细节密度**：物件只留三五处关键特征，缩到游戏里约 90 px 仍认得出；成排的重复细节要简化。范例：WSST_04 剪刀、WSST_05 熨斗。
- **人的遗存**：只有一处，画得比其余部分具体，让人心里一沉——“这曾经是个人”。
- **配色**：只有墨、纸色与灰；**没有边光**，没有其他颜色。
- **心智**：机械地重复劳作的动作，没有脸、没有表情，不血腥。
- 与 01 的玩家并排时，剪影、配色、光完全不同。
- 朝左（面向玩家）、全身完整；背景为透明或纯白，**没有深色背景、暗角或光晕**。
