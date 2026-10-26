# 03 无色实体（GPT Image 2）

用途：验证“同化 = 压缩”是否成立（art_style.md 第 6.1 节）：无色实体是否被压到只剩一团无脸的墨色人形剪影、只靠姿态与手里的生前物件说明它是谁，并与玩家一眼分开。生成 3～4 张，挑一张；放进 `assets_src/inbox/art/colorless/`。

**物件按区域取**：把 `[OBJECT]` 换成该区域一件生前熟悉的物品，`[POSE]` 换成使用它的劳作姿态。荒地 = 日常与劳作用品（铁锹、锅、扳手、扫帚……），田野 = 农具（锄头、镰刀、草叉……），逆时战场 = 军用与战场物资（工兵铲、枪托、担架杆……）。同类个体可以拿不同的东西。

尺寸建议：竖图 1024×1536 或更大。

## 提示词（整段复制，替换方括号）

```
Hand-drawn ink illustration for a 2D side-scrolling game. Dark sepia ink (#2b2420) with slight hand-drawn wobble and varying line weight, thicker outer contour, subtle ink bleed and paper texture, no gradients, no painterly rendering, no realistic lighting. A compressed, colourless remnant of a person: no colour of its own and no rim light, darker ink in the shadows instead.

Creature: a "colourless entity" — a person compressed by assimilation until almost nothing is left. One smooth, simplified silhouette of solid ink: no face, no eyes, no features, the head a smooth bowed shape; clothes, folds and hair flattened away; the edges of the silhouette softly bleeding into the paper. Hunched and slow, head down, [POSE]. It holds [OBJECT], something it used every day before it was assimilated, drawn plainly and greyed out (muted grey, desaturated). Calm and empty, no expression, no gore.

Full body, strict side view facing LEFT (toward the player), whole figure visible with margin, arms and the object kept clear of the body where possible, transparent background (or plain flat #ffffff background if transparency is unavailable). Single figure, no text, no frame. No colours other than ink, paper and the greyed object; no teal or cyan.
```

## 验收要点

- **压缩**：一团简洁的墨色人形剪影，没有五官、衣褶、头发等细节，轮廓边缘略微晕开；剪影本身清楚好读。
- **生前身份**：一眼看得出它生前在做什么（姿态 + 物件）；物件是该区域的日常或劳作用品，**褪成灰色**。
- **配色**：只有墨、纸色与灰；**没有边光**，没有其他颜色。
- **心智**：低头、迟缓、麻木，没有表情，不张牙舞爪，不血腥。
- 与 01 的玩家并排时，剪影、配色、光完全不同。
- 朝左（面向玩家）、全身完整、背景干净。
