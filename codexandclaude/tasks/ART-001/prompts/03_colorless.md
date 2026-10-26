# 03 无色实体（GPT Image 2）

用途：验证敌人是否做到“由人的部件拼成、却不合人体常理”（art_style.md 第 6.1 节），能否与玩家一眼分开，识别标志（无脸、全身纯墨）是否成立。生成 4～6 张，挑 1～2 张；放进 `assets_src/inbox/art/colorless/`。

**不收束**：每次生成前把 `[OBJECT]` 换成任意一件日常生活或办公用品，`[EMBED]` 换成另一件（可以与 `[OBJECT]` 同类或不同类），不必像武器，不限品类。例如雨伞、衣架、台灯、电话听筒、订书机、键盘、马克杯、折叠椅、文件夹、闹钟、熨斗、门把手、拖把……想到什么都可以。姿态那句也可以改成别的“不合常理”的组合。

尺寸建议：竖图 1024×1536 或更大。

## 提示词（整段复制，替换方括号）

```
Hand-drawn ink illustration for a 2D side-scrolling game. Dark sepia ink (#2b2420) with slight hand-drawn wobble and varying line weight, thicker outer contour, subtle ink bleed and paper texture, no gradients, no painterly rendering, no realistic lighting. Unsettling, uncanny liminal-horror mood, eerie rather than gory: no blood, no gore.

Creature: a "colourless entity" — made of human body parts in pure ink, with no colour of its own, assembled in a way no human body works. You can still tell the hands, feet, head and torso apart, but the arrangement defies human posture: for example it stands upside down on its clawed hands, legs raised and bent into the air, the head hanging beneath the chest; or folded in half backwards; or with limbs in the wrong places and the wrong number. Abstract, hard to understand, unsettling. The head has no face at all: a completely blank, smooth patch of pale paper (#efe4cc), no eyes, no nose, no mouth, no expression. Ink drips from the body onto the ground. One of its hands (or feet) holds [OBJECT], an ordinary everyday or office object that is not meant to be a weapon. [EMBED] is grown into its body, the edges fused into the ink, not hanging on it. It takes no warm light: no rim light at all, darker ink in the shadows instead.

Full body, side view, facing LEFT (toward the player), whole figure visible with margin, limbs kept apart from the body where possible, transparent background (or plain flat #ffffff background if transparency is unavailable). Single creature, no text, no frame. No colours other than ink, the pale paper face and the object's own muted colours; no teal or cyan.
```

## 验收要点

- **人的部件**：看得出手、脚、头、躯干，但组合与姿态不合人体常理，越难理解越好；不要只是一个站着的人加几处扭曲。
- **恐怖谷**：脸是一块平整的纸色空白，完全没有五官，也没有表情。
- **物件**：手持物是普通的日常或办公用品，不像武器；嵌入物“长”进身体，边缘与墨线融合。
- **识别标志**：缩小成剪影时，靠“无脸 + 全身纯墨 + 颠倒的人体”认出它，而不是靠手里的物件。
- **配色**：身体只有墨与纸色的脸；物件用低饱和的本色；**没有暖色边光**、没有青色。
- **不血腥**：没有血和伤口。
- 与 01 的玩家并排时，剪影、配色、光完全不同。
- 朝左（面向玩家）、全身完整、背景干净。
