# 03 无色实体（GPT Image 2）

用途：验证“逐级去人化”与“人的遗存”（art_style.md 第 6.1 节）：无色实体是否已是非人的小生物——人与生前物件被压成一体，只剩**一处**生前最重要的部分，让玩家认出“这曾经是人”；并与玩家一眼分开。生成 3～4 张，挑一张；放进 `assets_src/inbox/art/colorless/<区域>/`。

**按区域填三处**：`[OBJECT]` 换成该区域一件生前熟悉的物品，`[FORM]` 换成它和人一起被压成的形态，`[REMNANT]` 换成留下的那一处人的部分（一段躯体、一件衣服或饰物，甚至一撮头发，因个体而异）。例：

| 区域 | [OBJECT] | [FORM] | [REMNANT] 示例 |
| --- | --- | --- | --- |
| 荒地 | a shovel | a low four-legged crawler whose jaw is the shovel blade | a rough human hand that became one foreleg |
| 田野 | a hoe | a bird-like thing that keeps pecking the ground, its beak the hoe blade | a straw hat stuck to its back |
| 逆时战场 | a rifle butt | a flat thing that scuttles sideways under the rifle butt like a shell | a tuft of human hair |

尺寸建议：横图 1536×1024 或更大（形态低矮）。

## 提示词（整段复制，替换方括号）

```
Hand-drawn ink illustration for a 2D side-scrolling game. Dark sepia ink (#2b2420) with slight hand-drawn wobble and varying line weight, thicker outer contour, subtle ink bleed and paper texture, no gradients, no painterly rendering, no realistic lighting. A compressed, colourless remnant of a person: no colour of its own and no rim light, darker ink in the shadows instead.

Creature: a "colourless entity" — a person and [OBJECT], the thing they used every day, compressed together into one small creature that is no longer human in shape: [FORM]. The object has grown into its body as a working part, not held. Mostly one simple mass of solid ink with softly bleeding edges, no face, no eyes, very little detail. The only human thing left is [REMNANT], drawn a little more carefully than the rest so it reads at once as having belonged to a person. The object and the remnant are greyed out (muted grey, desaturated). It moves mechanically, repeating the motion of its old work; empty, no expression, no gore.

Full body, strict side view facing LEFT (toward the player), whole creature visible with margin, legs kept apart where possible, transparent background (or plain flat #ffffff background if transparency is unavailable). Single creature, no text, no frame. No colours other than ink, paper and the greyed object and remnant; no teal or cyan.
```

## 验收要点

- **非人**：一眼看去是一只小生物，不是人形；剪影低矮、简洁、好读。
- **物件长进身体**：生前物件成为它的颚、喙、壳或肢，看得出原来是什么物件。
- **人的遗存**：只有一处，画得比其余部分具体，让人心里一沉——“这曾经是个人”。
- **配色**：只有墨、纸色与灰；**没有边光**，没有其他颜色。
- **心智**：机械地重复劳作的动作，没有脸、没有表情，不血腥。
- 与 01 的玩家并排时，剪影、配色、光完全不同。
- 朝左（面向玩家）、全身完整、背景干净。
