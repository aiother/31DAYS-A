# 03 无色实体（GPT Image 2）

用途：验证敌人是否做到“像人但不是人”（art_style.md 第 6.1 节）、能否与玩家一眼分开、是否有自己的识别标志。生成 3～4 张，挑一张；放进 `assets_src/inbox/art/colorless/`。

尺寸建议：竖图 1024×1536 或更大。

## 提示词（整段复制）

```
Hand-drawn ink illustration for a 2D side-scrolling game. Dark sepia ink (#2b2420) with slight hand-drawn wobble and varying line weight, thicker outer contour, subtle ink bleed and paper texture, no gradients, no painterly rendering, no realistic lighting. Unsettling, uncanny liminal-horror mood, eerie rather than gory: no blood, no gore.

Creature: a "colourless entity" — a faceless human made of ink, with no colour of its own. Clearly human in overall shape (head, torso, two arms, two legs) but wrong: the head is tilted slightly forward and the face is a completely blank, smooth patch of pale paper (#efe4cc) with no eyes, no nose, no mouth. The arms are too long, hanging past the knees, the fingers end in thin ink claws. One knee bends the wrong way. Below the hips the body melts, dripping ink onto the ground. A small stopped clock with a pearl-white face (#fbf6ec) is grown into the middle of its chest, its rim fused into the ink of the body, not hanging on it. Standing still and quiet, no expression, no aggression. It takes no warm light: no rim light at all, darker ink in the shadows instead.

Full body, strict side view facing LEFT (toward the player), arms slightly away from the body, whole figure visible with margin, transparent background (or plain flat #ffffff background if transparency is unavailable). Single creature, no text, no frame. No colours other than ink, the pale paper face and the pearl-white clock face.
```

## 验收要点

- **依稀人形**：一眼看出是人的大关系（头、躯干、两臂、两腿），但手臂过长、指尖成爪、一侧膝盖反折、下半身化开滴墨。
- **恐怖谷**：脸是一块平整的纸色空白，完全没有五官；没有表情，不张牙舞爪。
- **嵌入物**：胸口嵌着一只停摆的钟，钟边与身体墨线融在一起，像长进去的；缩小到剪影时仍能看出“无脸 + 胸口一点白”。
- **配色**：只有墨、纸色的脸、珍珠白钟面；**没有暖色边光**，没有其他颜色。
- **不血腥**：没有血和伤口。
- 与 01 的玩家并排时，剪影、配色、光完全不同。
- 朝左（面向玩家）、全身完整、四肢与身体之间留空、背景干净。
