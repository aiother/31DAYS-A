# 玩家奔跑六帧 v2：斗篷遮臂与换腿修正

> **已废弃，永不采用（用户 2026-10-29）**：本文件属于原玩家方案（匠首连帽长斗篷、黑纱两点眼、2.5 头身、萤环与晶弦），只作历史记录，不作为任何形象的参考、基础或标准。见 `game/docs/art_style.md` 第 6.3 节。

- 文件：`player_run_sheet_v2.png`；日期：2026-10-27；2172 × 724 px，RGBA 透明 PNG。
- 来源：内置 image_gen；AI 生成；套餐信息未提供。角色原参考为 `assets_src/inbox/art/player/player_01_3.png`。先重新生成，再用内置工具调整六帧排版；最终文件直接复制，无额外裁切或改色。
- 修正：双肩、上臂、肘、前臂和双手均藏在斗篷下面，取消袖子、外摆拳头和斗篷背面的手；摆臂只通过布料变化暗示。
- 近远侧约定：朝右时近侧为角色右侧，远侧为角色左侧；近腿深蓝，远腿更暗偏紫。第 1 帧近腿向前，第 4 帧远腿向前；第 3、6 帧分别为远腿和近腿前摆。
- 顺序：近腿接触→近腿承重压低→远腿前摆腾空→远腿接触→远腿承重压低→近腿前摆腾空。保留披风波动与兜帽回弹，手臂不穿出布料。
- 切图：6 列 × 1 行，每格 362 × 724 px，保留统一画布；12 fps 可作为试播起点，循环 1→2→3→4→5→6→1。
- 状态：修正版待动作验收，尚未接入运行时；v1 留作对照，不再作为当前奔跑候选。
- 验证：图像解码、透明通道、六个独立可见轮廓、等宽切图边界、两次压低/上升，以及接触帧和腾空帧中前摆靴的蓝/紫区分。目视检查斗篷遮臂。使用带 Pillow 的项目依赖执行 `python -m unittest discover -s tests`。
- 限制：颜色与结构检查不能证明骨骼运动或循环流畅；脚底基线、精确头身比、支撑脚滑动和 6→1 衔接仍需播放验收。图中仍有低透明度边缘噪点，运行时导入前需清理。

## 最终重新生成提示词

```text
Create a clean transparent PNG SPRITE SHEET: one row, exactly SIX equally spaced small full-body sprites, the SAME hooded chibi character from the attached reference RUNNING RIGHT in strict side profile. Match reference silver hooded cape, floppy hood tip, black mesh veil and two tiny bluish eyes, rose-gold hem band, navy suit and dark boots, 2.5-head proportions. Dark sepia #2b2420 hand-drawn ink outlines, flat silver #b4bac4/navy #1f2740, violet #7d4a8c shadows, thin warm #f4b860 left rim, subtle paper texture. No gradients.

CORRECTION 1 — HIDE BOTH ARMS AND HANDS completely under the cape in all six sprites. The cape covers shoulders, elbows, forearms and gloves. NO exposed sleeve or fist, NO hand on the back of cape. Only the TWO boots and lower shins emerge from below the cape. Keep cape long, moving behind.

CORRECTION 2 — ANATOMICAL RUN CYCLE. Near/right leg and boot are LIGHTER NAVY; far/left leg and boot are VERY DARK VIOLET. Keep this identity through the entire cycle. Six consecutive poses left-to-right:
1 near LIGHT boot reaches forward RIGHT, far DARK boot trails LEFT.
2 near LIGHT foot planted under hip, knee bends, far DARK heel tucked behind; body LOWER.
3 far DARK knee drives forward RIGHT, near LIGHT foot pushing backward LEFT; body HIGHER and airborne.
4 far DARK boot reaches forward RIGHT, near LIGHT boot trails LEFT. The forward leg is DARK, visibly the opposite of frame 1.
5 far DARK foot planted under hip, knee bends, near LIGHT heel tucked behind; body LOWER.
6 near LIGHT knee drives forward RIGHT, far DARK foot pushing backward LEFT; body HIGHER and airborne.
Never repeat frames 1–3 as 4–6. No backwards knees, no extra legs, no foot disconnected from shin. Slight forward lean of torso and head in every frame, coordinated running, never stiff upright walking.

Cape conceals contralateral arm swing. Hood tip trails left; cape ripples with two waves per cycle. Equal character scale, fixed ground alignment, full silhouettes with ample transparent gaps, each sprite fits comfortably within one sixth of the canvas, NO clipping. No wrist ring or crystals, weapon, ground, shadow, glow outside the eyes, text, numbers, borders, red, teal or cyan. Genuine transparent alpha background.
```

## 后续排版编辑提示词

```text
LAYOUT EDIT ONLY of the attached six-sprite running sheet. Preserve ALL SIX exact poses and their order, exact character drawing, the hidden arms and hidden hands, lighter near leg and violet far leg, costume and colours. Do NOT redesign or change the gait. SHRINK EACH OF THE SIX CHARACTERS by 25 percent about its center, then center each in its own equal-width cell in one row. This creates clear transparent gutters between all six figures and generous outer margins. Retain full complete cape and boots in every cell. Six equal invisible cells across same wide canvas. Every character has same scale; all contact foot bottoms align to same baseline, airborne frames 3 and 6 are slightly above it. Actual transparent alpha background; NO dark fill, no shadow, no added objects or lines, no text. Keep upper arms, elbows, forearms, gloves entirely concealed by cape in every frame. Keep near lighter leg forward in frame1 and far violet leg forward in frame4.
```
