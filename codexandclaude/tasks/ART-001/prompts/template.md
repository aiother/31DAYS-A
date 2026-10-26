# 提示词模板

每条提示词由下面五块拼成；英文写给 GPT Image 2，中文验收要点给用户挑图时对照。

## 1. 风格块（每条都带，原样复制）

```
Hand-drawn ink illustration for a 2D side-scrolling game. Dark sepia ink outlines (#2b2420) with slight hand-drawn wobble and varying line weight, thicker outer contour. Flat colour fills with at most one light and one shadow tone, subtle ink bleed and paper texture, no gradients, no painterly rendering, no realistic lighting. Low warm dusk sunlight from the LEFT: a thin warm rim light (#f4b860) on the left edges, shadows tinted cool violet (#7d4a8c). Muted, low-saturation palette: ink #2b2420, paper #efe4cc, dusk paper #f0cfb6, pearl #fbf6ec.
```

敌人把风格块里 `Low warm dusk sunlight` 起到 `cool violet (#7d4a8c).` 止的那句光换成下面这句（敌人不受暖光，art_style.md 第 4、6.1 节）：

```
Unsettling, uncanny liminal-horror mood, eerie rather than gory: no blood, no gore. It takes no warm light: no rim light at all, darker ink in the shadows instead.
```

## 2. 对象块

写清对象是谁、形象要点、识别标志与标志色（取自 `game/docs/art_style.md` 第 6 节），以及**不要**什么颜色。敌人还要写清：哪里像人、哪里扭曲（比例 / 方向 / 缺失 / 多余）、嵌入的异物“长进身体、边缘与墨线融合”、表情固定。

## 3. 构图块

- 角色：`Full body, strict side view facing RIGHT, standing pose, arms slightly away from the body, whole figure visible with margin, transparent background (or plain flat #ffffff background if transparency is unavailable). Single character, no text, no frame.`
- 部件：`Isolated body part on transparent background, same character and style as the reference image, side view facing RIGHT, extend the part about 15% past the joint so it can overlap.`
- 背景：`Wide horizontal game background layer, no characters, no text, side-scrolling parallax layer.`

## 4. 参考块

设定图定稿后，所有后续图都附上设定图作为参考图，并加一句：`Match the reference image exactly in silhouette, colours and proportions.`

## 5. 验收要点（中文，挑图用）

- 轮廓：深墨线、有手绘抖动、外轮廓比内部线粗。
- 上色：平涂，无渐变高光，无写实光影。
- 光：人有左侧暖色边光、暗部偏紫；敌人没有边光。
- 配色：只出现该对象应有的颜色；无可能性青、无大面积生命红（玩家围巾除外）。
- 构图：正侧面朝右（敌人朝左，面向玩家）、全身完整、背景干净可去除。
- 敌人另查：依稀人形、扭曲到位、嵌入物与识别标志清楚、无暖色边光、不血腥（art_style.md 第 6.1 节）。
- 一致性（第二张起）：轮廓、配色、比例与设定图一致。
