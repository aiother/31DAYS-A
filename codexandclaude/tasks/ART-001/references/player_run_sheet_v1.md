# 玩家朝右奔跑六帧 v1

- 文件：`player_run_sheet_v1.png`；生成日期：2026-10-27；2172 × 724 px，RGBA 透明底。
- 来源：内置 image_gen；AI 生成；套餐信息未提供。生成结果直接复制，无裁切、缩放或改色。
- 角色参考：`assets_src/inbox/art/player/player_01_3.png`（已认可完整主角）。
- 内容：单行六帧、朝右奔跑；披风、兜帽、黑网面纱与蓝紫眼点、工装、手套、靴和玫瑰金下摆。无武器或手腕碎片环。
- 切图：6 列 × 1 行，每格 362 × 724 px；从左到右为 1–6。所有帧使用相同画布与原点，不能单独紧裁后直接播放。
- 试播建议：12 fps，每帧约 83.3 ms，整轮 0.5 s，循环顺序 1→2→3→4→5→6→1；这是建议播放参数，不是已验收时序。
- 用途：逐帧奔跑动画初稿，尚未接入游戏；不是独立分层图或骨骼动画。
- 验证：PNG 解码、透明通道、六个可见角色区、等宽格边界分离与两次起伏；使用带 Pillow 的项目依赖运行 `python -m unittest discover -s tests`。
- 局限：低透明度边缘噪点仍需清理。严格侧视、精确 2.5 头身、近远腿交替、固定脚底基线、手套大小与第 6→1 帧衔接仍需逐帧播放和校准；静态结构测试不能证明动作流畅。切图格内空隙仍偏紧，不应按未经检查的紧裁边缘制作碰撞区域。

## 最终生成提示词

```text
Hand-drawn ink illustration for a 2D side-scrolling game. Dark sepia ink outlines (#2b2420) with slight hand-drawn wobble and varying line weight, thicker outer contour. Flat colour fills with at most one light and one shadow tone, subtle ink bleed and paper texture, no gradients, no painterly rendering, no realistic lighting. Low warm dusk sunlight from the LEFT: a thin warm rim light (#f4b860) on the left edges, shadows tinted cool violet (#7d4a8c).

Match the reference image exactly in silhouette, colours, costume and proportions: the same small chibi character, exactly 2.5 heads tall, in the deep muted silver floor-length hooded cape with the soft floppy hood tip, the black mesh veil with two small glowing bluish eyes, the dark navy coverall, dark gloves and boots, the rose-gold hem band.

A SPRITE SHEET for frame-by-frame animation: ONE horizontal row of exactly SIX frames of the SAME character running to the RIGHT, one complete looping run cycle (frame 6 flows back into frame 1), strict side view facing RIGHT. Every frame the same size and scale, evenly spaced, the feet of every frame on the same baseline, plenty of empty space between frames so they do not touch or overlap. Hand-animated like the frame-by-frame sprites of Hollow Knight and Silksong: the body leans forward and bobs up and down twice per cycle; the boots step out from under the hem in turn; the near hand with its empty glove swings; the long cape trails behind and ripples in a wave that travels from the shoulders to the hem, its lower edge flicking up and back; the floppy hood tip bounces and trails behind. Smooth, consistent spacing between poses, nothing changes except the motion.

Transparent background (or plain flat pure white #ffffff background if transparency is unavailable); no dark background, no vignette, no glow, no motion lines, no ground, no shadows on the ground. No text, no numbers, no frame borders. No ring of fragments around the wrist (it is added in the game). No weapon. No red anywhere. No teal or cyan anywhere.

Input image role: approved character identity and costume reference. Composition: wide landscape single strip, six equal invisible cells, one complete character per cell, all six fully inside image with generous margins. Exactly six distinct consecutive poses in order: near-foot contact, compression, passing/rise, far-foot contact, compression, passing/rise. Common ground baseline is an alignment guide only, do not draw it. Keep character scale fixed while allowing intentional vertical body bob and airborne foot lift. Genuine transparent background preferred; never add atmospheric background.
Layout is the top priority: exactly SIX SMALL sprites occupying the middle horizontal band of a very wide canvas. Six invisible equal-width cells. Draw each sprite only HALF as wide as its cell, so each large blank gutter is approximately as wide as a whole sprite. All sprites must be clearly separated by large empty gaps. Do not enlarge the figures to fill the canvas. The trailing cape fits entirely inside the central HALF of its own cell. The six character centers are exactly equally spaced at 1/12,3/12,5/12,7/12,9/12,11/12 of image width. Blank transparent padding on all four sides, no faint pixels or marks outside characters. Keep sprites identical in scale and costume. Make a readable alternating run, opposite leg forward in frame 4 compared with frame 1.
```
