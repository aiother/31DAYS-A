# 玩家步行逐帧重设计 · 已确认骨架适配 v1

- 日期：2026-10-29；文件：`player_walk_approved_sheet_v1.png`，1536×1024，RGBA PNG。
- 来源：内置 image_gen；先生成角色逐帧图，再使用同一工具缩小各格人物、增加透明留白。最终生成文件直接复制，未做额外程序裁切或改色。
- 角色参考：`assets_src/inbox/art/player/player_01_3.png`；动作参考：用户确认的 `human_walk_approved_legs_v1.png`。二者分别约束角色造型与动作关系。
- 布局：5×2，共 10 帧，朝左。上排从左到右对应 01–05，下排对应 06–10。按源图顺序读取，不套用之前废弃的程序步态。
- 切图边界：x = [0, 307, 614, 922, 1229, 1536]；y = [0, 512, 1024]。各格宽 307 或 308 px，切图后统一到 308×512 画布再调根节点。当前交付未进行切图。
- 角色保持银灰兜帽与斗篷、黑色面纱、蓝紫眼光、菱形扣、玫瑰金下摆、深蓝工装及短靴；朝向改为与动作参考一致的左侧视。
- 作为基础移动层，手臂藏在斗篷内，萤环和武器不绘入本张。斗篷随腿部动作变化，下摆露出靴子；腿部依角色比例缩短，不能用成人骨架长度直接覆盖。
- 透明通道实际范围 0–254。背景区虽然保留 RGB 底色，但 alpha 为 0；不能把忽略透明通道的查看器画面当作不透明底图。轮廓仍可能含低透明度边缘，需要导入前按实际背景检查。
- 目视检查：10 个独立完整人物、统一朝左、跨步与屈膝等姿势变化、角色关键服装与遮臂一致。自动验证图像解码、透明度、10 格非空和主要轮廓不跨切图边界。
- 状态：新角色稿待用户确认，未接入游戏。已确认的是动作参考源图，不代表新逐帧图已获认可。自动检查不证明骨骼角度完全一致、左右腿身份持续正确、重心或 10→01 接续流畅；脚底基线、透视及斗篷遮挡仍需逐帧播放与美术验收。
- 验证命令：使用带 Pillow 的 Python 执行 `python -m unittest discover -s tests`。

## 最终提示词

排版修正：初稿个别人物越过等分切图边界，因此追加纯排版编辑，要求统一缩小至原来的 80%，保留十姿势及顺序。以下为排版编辑提示词：

```text
LAYOUT EDIT ONLY of this exact 10-sprite sheet. Preserve all TEN drawings and their pose order, costume, left-facing direction, short character proportions, hidden arms, every leg/boot position and cape shape. Do not redraw or change any pose. Keep FIVE columns and TWO rows. The current sprites crowd some cell boundaries. Uniformly SHRINK EVERY sprite to 80 percent of its current size and center each within its equal rectangular cell. Keep the entire head, cape and boots safely inside its own cell. Add generous genuinely transparent gutters around ALL ten figures. All figures must share the same scale and the original relative pose progression. Preserve alpha transparency: every empty margin and gutter alpha0, sprite interior opaque, no background or floor or shadow. No new numbers, borders, captions or objects. Only change uniform sprite size and cell placement. Retain the source canvas dimensions if possible.
```

初始生成提示词：

```text
Use case: stylized-concept / game animation sprite sheet.
TWO distinct reference roles:
IMAGE1 is the approved CHARACTER DESIGN: match this precise hooded chibi identity, silhouette, costume, palette, linework and proportions.
IMAGE2 is the approved LEG MOTION TEMPLATE: its TEN poses in order 01 through10 are AUTHORITATIVE. Reconstruct the character's lower body over each of these poses adapted proportionally to the chibi character's shorter legs. Do NOT invent a generic gait or substitute a previous run cycle.

Deliver ONE genuinely transparent PNG SPRITE SHEET, EXACTLY TEN full-body character sprites arranged in a precisely regular 5 COLUMNS x 2 ROWS grid. Top row corresponds source poses01,02,03,04,05; bottom row06,07,08,09,10. No text or numbers on image. Equal cell widths and heights. Each figure centered horizontally in its cell with 15% clear transparent margins on both sides. Fit ENTIRE hood, cape, boots in each cell without clipping, no cell overlap. All ten characters have identical scale, consistent pivot/pelvis horizontal center; ground level identical relative to cell bottom. Transparent gutters between cells. Design usable for later uniform cell slicing.

FACE LEFT in strict side-scroller side profile in EVERY sprite, matching image2 motion direction; reinterpret image1 costume in left-facing profile (image1 currently faces right). SAME character in all frames: huge floppy silver-grey hood with rear tip trailing RIGHT, dark mesh veil, a tiny pale blue-violet eye visible in side view, silver-grey long cape with rose-gold geometric border, small rose-gold diamond clasp and purple gem at neck, very dark navy workwear, heavy rounded dark boots. 2.5-head-tall chibi proportions and short limbs consistent with project. Hand-drawn varying dark sepia #2b2420 ink outline, flat colors, subtle paper texture on cape only, muted violet shadows, thin warm rim on silhouette. No realistic rendering or gradients. Near-side leg is navy and far-side leg a slightly darker violet navy. Preserve near/far layer ordering through overlapping poses.

MOST IMPORTANT: transfer source image2 exact 10 leg relationships. Pose01 planted leg vertical, opposite shin folded backward to RIGHT with foot lifted. 02 forward boot planted left, rear boot trailing right and rolling off toe. 03 wide stride, forward boot reaching LEFT and rear boot behind RIGHT. 04 feet passing close under pelvis, one knee bends, feet overlap but still exactly two legs. 05 vertical supporting leg and opposite shin folded back RIGHT. 06 source06 split stride, rear foot rolling toe. 07 source07 wide stride, front LEFT boot flat and rear RIGHT toe extended. 08 source08 broad stride, LEFT forward heel reaching and RIGHT rear foot behind. 09 source09 bent lifted knee driving LEFT with boot off floor while other foot planted behind RIGHT. 10 source10 passing pose with feet close under pelvis, one bent knee and one straight supporting leg. Check both legs against corresponding source pose, do not duplicate a single walk lunge ten times. Grounded feet remain on a common baseline; lifted foot stays lifted. NO run or all-feet-airborne pose.

Cape sways gently to RIGHT with modest phase lag and breathing folds, not windblown sprint. Preserve long cape but its moving front opening and slightly lifted side hems let BOTH BOOTS and the useful lower-leg silhouette remain readable. Torso/head subtly rise and fall with support phases, never stretch or change character scale. Arms and hands stay concealed under the cape as in the established gameplay art; arm counter-swing suggested only by fabric. This is a neutral locomotion base sheet: NO weapon, no floating crystal ring, no spell, no bones or skeleton overlay. No ground lines, no floor shadows, no grid/borders, no opaque background, no annotations. Fully colored actual character sprites, not diagrams. These are distinct sequential drawings, not static character duplicates.
```

