# 02 荒地背景一角（GPT Image 2）

> **已过时（用户 2026-10-30 裁决 A-021）**：世界风格改为叠放的褪色老照片（`game/docs/art_style.md` 第 7 节），本提示词的纸色黄昏背景只作历史记录，不再用于生成背景。

用途：验证场景风格与角色是否分得开。生成 2～3 张横图，挑一张；放进 `assets_src/inbox/art/hd/`。只作风格定稿参考，正式背景分层由场景任务另出提示词。

尺寸建议：横图 1536×1024 或更宽。

## 提示词（整段复制）

```
Hand-drawn ink illustration for a 2D side-scrolling game. Dark sepia ink outlines (#2b2420) with slight hand-drawn wobble and varying line weight. Flat colour fills, subtle ink bleed and paper texture, no gradients except the sky, no painterly rendering, no realistic lighting. Muted, low-saturation palette.

Scene: a ruined wasteland at dusk. Sky fades from muted violet (#7d4a8c) at the top to warm orange (#f0a050) near the horizon, a low sun on the LEFT. Far layer: pale lilac silhouettes of broken towers and ruins with almost no outlines and very low contrast. Middle layer: grey-brown rubble hills (#8a7566) with thin ink lines on their top edges. Near layer: a flat walkable ground strip in dusk paper colour (#f0cfb6) with a clear ink line along its top edge, a few cracks and small stones. Along the very top edge of the sky, dark ink (#2b2420) seeps down into the picture as if the top of the paper had been dipped in ink: an uneven dark band with a few slow drips hanging down into the violet, unnatural, the only sign that this world is not real. Empty foreground space for characters. Lonely, quiet, desolate, a faint warm afterglow.

Wide horizontal game background, side view, no characters, no text, no frame. No teal or cyan anywhere.
```

## 验收要点

- 远景淡、几乎无线；中景细线；近景地面上沿有清楚的墨线——越近线越重。
- 天空紫到橙，太阳在左。
- **暗室的痕迹**：天空最上沿有一条往下渗的墨带，挂着几道墨滴（art_style.md 第 7 节）；只在顶边，不压到中景。
- 整体低饱和，留出一条干净的地面给角色站。
- 把 01 的玩家图放在地面上时，玩家明显比背景暗、轮廓清楚。
