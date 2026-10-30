# 玩家披风双视图 v1

> **已废弃，永不采用（用户 2026-10-29）**：本文件属于原玩家方案（匠首连帽长斗篷、黑纱两点眼、2.5 头身、萤环与晶弦），只作历史记录，不作为任何形象的参考、基础或标准。见 `game/docs/art_style.md` 第 6.3 节。

- 文件：`player_cape_sheet_v1.png`；生成日期：2026-10-27；1536 × 1024 px。
- 来源：内置 image_gen；AI 生成；套餐信息未提供。生成结果直接复制，无裁切或改色。
- 角色参考：`assets_src/inbox/art/player/player_01_3.png`（已认可设定）。
- 用途：供 ART-002 拆层与补画的服装参考；左侧为朝右侧视、敞开前襟展示深蓝内衬，右侧为完整背片外层。
- 目视检查：双视图完整且分离；银色外层、深蓝内衬、玫瑰金几何下摆；无兜帽、搭扣、人物、文字或武器。
- 背景：按用户允许的备用方案交付白底，非透明 PNG。背景像素存在轻微近白纸色波动，并非逐像素纯 #ffffff；后续接入游戏前需去底和拆层。
- 透明生成及一次去底修正均残留光晕，因此舍弃；本图重新依照角色原参考生成白底版本。
- 局限：这是单张服装参考，未拆分前后片、内衬与布料链，未补齐关节重叠区，未接入运行时。背片褶皱与下摆弧度仍需按实际骨骼校准。
- 验证：使用带 Pillow 的项目依赖运行 `python -m unittest discover -s tests`。

## 最终生成提示词

```text
Hand-drawn ink illustration for a 2D side-scrolling game. Dark sepia ink outlines (#2b2420) with slight hand-drawn wobble and varying line weight, thicker outer contour. Flat colour fills with at most one light and one shadow tone, subtle ink bleed and paper texture, no gradients, no painterly rendering, no realistic lighting. Low warm dusk sunlight from the LEFT: a thin warm rim light (#f4b860) on the left edges, shadows tinted cool violet (#7d4a8c).

Match the reference image exactly in colours, line, fabric and proportions. Draw ONLY the character's floor-length cape, with nobody inside it, as a costume sheet for 2D skeletal animation, two views side by side on one image:

LEFT: the cape seen from the side facing RIGHT, hanging as if worn but empty, the front opening spread wide so the whole inside is visible: the deep muted silver outside (#b4bac4) on the back half, the very dark navy lining (#1f2740) filling the inside, the thin rose-gold geometric band (#c08a78) along the hem, falling to the ankles in a soft rounded teardrop shape.
RIGHT: the same cape laid out flat from behind, the whole back panel visible from collar to hem, outside only, with the rose-gold hem band.

No hood on the cape (the hood is drawn separately), no clasp, no body, no head, no hands. Both views complete, edges clean, with margin. Plain flat pure white #ffffff background; no dark background, no vignette, no glow. No text, no frame. No red anywhere. No teal or cyan anywhere.

Input image role: approved character reference only. Extract and reconstruct its cape alone; exclude everything else. Deliver a completely solid pure white #ffffff background everywhere outside the capes. Two separate non-touching views with clear white gap and generous white margin around all edges. No background shadows whatsoever. This is a clean white-background costume asset sheet, never dark or atmospheric.
```
