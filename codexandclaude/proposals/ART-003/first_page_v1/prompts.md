# 初页 v1：实际生成提示词

2026-10-30。工具：内置 image_gen。所有调用均为不透明背景，保留生成原图；未用程序改绘。三视图与拆分图是用于制作的设定参考。

## 1. 三视图初稿

参考：已选 A「初页」原始设定图，SHA256 `ac67b32000ae735089c0f0010740b533917425ef25f7db7aef90836dac0a2841`。使用左侧纯白初态作为身份与衣物参考。

```text
Use case: stylized-concept.
Asset type: STANDARD ORTHOGRAPHIC CHARACTER TURNAROUND SHEET, three views, for production of a hand-drawn 2D side-scrolling protagonist.
Input image 1 is the approved identity and costume REFERENCE: A "初页", especially the LARGE PURE-WHITE figure at LEFT. Re-express this exact character as three orthographic construction views. Preserve face identity, short layered white hair, ONE small flipped forelock, youthful androgynous proportions, soft folded standing collar, small WHITE diamond clasp at throat, short triangular two-panel cape ending at upper thigh, separate white loose sleeved tunic, shorts, white slender legs, and white folded-cuff ankle boots. Preserve the recognizable silhouette and charm of approved A. This is a clean technical restatement, not a new design.
Primary request: exactly THREE complete equal-scale figures LEFT TO RIGHT: strict FRONT 0 degrees, strict RIGHT-FACING SIDE 90 degrees, strict BACK 180 degrees. NO three-quarter views or perspective. Side view has one eye and a clear nose profile facing right; back view shows no face and no chest clasp. Same head size, body proportions, hair volume, collar height, cape hem and boot construction in every view. All three stand on ONE EXACT HORIZONTAL SOLE BASELINE; top of skull/forelock and shoulder, hip, knee and boot heights align. The side view must not be shorter or more slender in limb length. Retain the approved reference's compact body and relatively large head; do not force the unrelated old hooded 2.5-head design.
Pose: neutral production A-pose, weight centered, spine upright, feet parallel and close but separated, relaxed open hands. Front/back upper arms slightly abducted ~15 degrees to reveal arm and cape construction without wind. In profile, arms relaxed down, near hand slightly forward only enough to read it. Cape hangs naturally under gravity, no dynamic billow. Show the same layers wrapping continuously across views, especially cape over independent sleeves. Do not fuse the arms into the cape. Do not add a hood, scarf, long coat, veil, mask, jewelry, tools, weapon, bag, belt or extra garment panels.
Style: preserve delicate hand-drawn graphite-gray outlines and restrained white-on-white flat shape shading of reference, simpler and cleaner than the concept sheet, matte flat 2D drawing, light gray internal folds, no photorealism, no glossy 3D, no dramatic lighting. EVERYTHING on the character is achromatic WHITE: white hair, white skin, white clothes and boots; tiny neutral gray facial features and subtle neutral gray structure only. Absolutely no amber/blue/coral color and no growth-state patches. Use a clean solid MEDIUM GRAY neutral background (#A4A4A4) so the white contour reads. Soft outer white glow is omitted in this technical construction view to keep exact silhouette visible; the glow will be a separate runtime effect. No drop shadow except one minimal neutral sole contact.
Composition: wide landscape 3:2 at high resolution. Three columns of equal width; each figure occupies around 76% of image height and is centered in its column with generous clearance. Fine gray horizontal construction guides, extremely subtle and BEHIND figures, indicate top of head, eyes, shoulders, cape hem, knees and sole; do not draw a skeleton or joint circles. ONLY three full-body figures, no extra portraits, palette, progressions, scenery or action pose.
Text (verbatim): small elegant title at top "初页 · 标准三视图"; small labels beneath the three views respectively "正面" "右侧面" "背面". No other text, gibberish or watermark.
Quality criteria: exact orthographic direction, equal height and foot baseline, full uncropped bodies, exactly two arms/two legs per character, exposed clear hands, coherent cut of cape front/back, entirely grayscale white initial state.
```

## 2. 三视图朝向校正

目标：只调整初稿中央侧视图为朝画面右方，保持正背面与比例。最终交付文件：`player_a_turnaround_v1.png`。

```text
Use case: precise-object-edit.
Input image 1 is the EDIT TARGET, a finished character turnaround. Make ONE precise correction: horizontally mirror ONLY the MIDDLE SIDE-VIEW CHARACTER inside its own column so that its NOSE, eyes direction, and BOOT TOES point to the RIGHT of the image. Its back is on the left. The middle character is currently facing left and must instead face right.
Keep the middle figure in exactly the same column, scale, head-top height and foot baseline. This is a clean mirror of that one whole figure, not a redesign or new pose.
INVARIANTS: preserve the entire LEFT front-view figure, entire RIGHT back-view figure, gray background, all guide lines, title "初页 · 标准三视图", three bottom labels, line style, all-white palette, clothing construction and all other pixels as closely as possible. Do not mirror the whole sheet. Do not change the outer figures at all. Do not add a fourth view. Keep strict orthographic three views and complete uncropped bodies.
```

## 3. 24 部件拆分

参考：原始 A 图与三视图初稿；用相同衣物结构绘制朝右的拆分部件。最终交付文件：`player_a_parts_breakdown_v1.png`。编号含义见 [parts_plan.json](parts_plan.json)。

```text
Use case: stylized-concept.
Asset type: NUMBERED 2D CHARACTER PARTS BREAKDOWN REFERENCE SHEET for animation and rigging, not an assembled character and not a poster.
Input image 1 is the APPROVED CHARACTER IDENTITY reference: A "初页", the white figure at left; ignore colored examples and environment.
Input image 2 is the CONSTRUCTION TURNAROUND reference: preserve exact hair, face, white folded collar, diamond clasp, short flexible triangular cape, independent white sleeves/tunic, white shorts, bare white legs, folded-cuff white ankle boots, proportions and line style.
Primary request: draw exactly TWENTY-FOUR separate complete isolated component drawings arranged in a perfectly ordered SIX-COLUMN by FOUR-ROW grid, one component per cell, read left to right, top to bottom. No assembled character, no decorative extra components, no extra rows or columns. Use a clean uniform medium neutral gray backdrop, delicate gray cell separators and large breathing room between parts. Wide landscape 3:2 high resolution with small title "初页 · 部件拆分". Each cell has ONLY its exact two-digit number below its part, no additional words or arrows. All components are the WHITE initial uncolored state.
Style: EXACT same hand-drawn 2D graphite-gray contour, matte white fill, sparse pale neutral gray flat structural shading. No colorful tint. No glow, halo, baked drop shadow, photo texture, gradient shading, realistic 3D or metallic finish. White skin/hair/clothes/boots; small gray eyes only.
Orientation: all laterally oriented components, head/hair and limbs face RIGHT, to match a right-facing side-scrolling rig. Reference 2's side figure faces left; use its mirrored construction for these right-facing parts. Anatomical near/far means closer/farther to camera, NOT screen left/right. Far limb drawings are independent matched pieces in slightly darker NEUTRAL gray-white, not black silhouettes, with same lengths and garment details.
Draw every piece COMPLETE including hidden underlaps: rounded shoulder/elbow/wrist/hip/knee/ankle joint ends extended ~15% so overlapping pieces can bend without holes. No joints cut as bare straight visible stumps, no gore, no anatomical skeleton. Hands simple relaxed human hands. Hair separated from white head face. Keep torso under cape fully drawn. A head without hair should remain a gentle stylized face, not a mask or detached floating skull. Leg pieces white and smooth, no muscle anatomy lines.
Keep one coherent relative scale across components so upper/lower paired limbs would match the reference's proportions. Do not enlarge the tiny diamond clasp to the size of the head. Cape pieces may be broad, fully contained in their own cell. Nothing touches neighboring parts or numbers.

EXACT GRID CONTENTS (each number is mandatory, exactly one of each):
Row 1, cells left to right:
01 — HEAD BASE: complete white head in right profile, includes ear and pale gray eye and mouth, no hair, round neck socket overlap.
02 — BACK HAIR: the short layered white nape/crown hair mass, right-profile curvature, no face.
03 — FRONT HAIR: front white fringe/forehead tufts swept as in approved A, no head or eyes.
04 — FORELOCK: the SINGLE small flipped-up white hair strand above crown, root overlap, not a whole hair mass.
05 — NECK: short white neck with broad rounded upper/lower overlaps, no head/collar.
06 — FOLDED STAND COLLAR: only the white folded neck collar BELOW chin, no cape body, no head, no diamond clasp.
Row 2:
07 — CHEST/TUNIC: white short sleeved-tunic TORSO WITHOUT ARMS, complete shoulders/waist under cape, no cape or head.
08 — HIP/SHORTS: only white waist and complete short pants, no legs or torso.
09 — CAPE BACK PANEL: complete short white triangular back drape with soft folding corner, no arms/head/clasp; upper shoulder overlap.
10 — CAPE FRONT FAR PANEL: one distinct white short front flap on far side, no torso, white inner fold visible.
11 — CAPE FRONT NEAR PANEL: matching other white short front flap on near side, no torso, white inner fold visible.
12 — DIAMOND CLASP: one tiny WHITE faceted diamond fabric/ceramic fastening with restrained gray contour, no colored stone or jewelry.
Row 3:
13 — FAR UPPER ARM: full white upper sleeve, shoulder to elbow with overlaps, no hand.
14 — FAR LOWER ARM: complete white forearm and flared folded sleeve cuff, elbow to wrist with overlaps, NO HAND.
15 — FAR HAND: one separate small white relaxed hand including wrist overlap, no sleeve or arm.
16 — NEAR UPPER ARM: matching independent white upper sleeve with shoulder/elbow overlaps, no hand.
17 — NEAR LOWER ARM: matching white forearm and flared folded sleeve cuff, elbow to wrist, NO HAND.
18 — NEAR HAND: one separate small white relaxed hand including wrist overlap, no sleeve or arm.
Row 4:
19 — FAR UPPER LEG: white thigh only from hip to knee with overlaps, no shorts or boot.
20 — FAR LOWER LEG: white shin only knee to ankle with overlaps, no boot.
21 — FAR BOOT: complete white right-facing folded-cuff ankle boot, rounded toe, complete sole, ankle overlap.
22 — NEAR UPPER LEG: white thigh only, same length as 19, joint overlaps.
23 — NEAR LOWER LEG: white shin only, same length as 20, joint overlaps.
24 — NEAR BOOT: complete white right-facing folded-cuff ankle boot matching 21 in length, complete sole and ankle overlap.

Must be a genuinely disassembled production-reference sheet: no fused hand+forearm, no leg+boot fusion, no head+hair fusion, no cape draped over torso. Correct strict grid and exact 01–24 numerals. Clear consistent garment construction, same protagonist as both references.
```

## 4. 发束重复修正

目标：仅移除 02、03 发片中重复的头顶翻起发束，让该发束只出现在独立的 04 部件。最终拆分文件保留本轮修正后的原始 PNG。

```text
Use case: precise-object-edit.
Input image 1 is the EDIT TARGET: finished 24-cell numbered character parts breakdown sheet. Make ONE localized production correction to the HAIR PARTS ONLY:
In top row cell 02, remove the small isolated FLIPPED-UP FORELOCK strand sticking above the crown. Close its former root with the natural rounded white crown contour of the back-hair mass.
In top row cell 03, remove the small isolated FLIPPED-UP FORELOCK strand sticking above the fringe. Close its former root with the natural rounded white fringe/crown contour.
The flipped-up forelock is ALREADY its own independent component 04, so it must appear ONLY in cell 04, not duplicated in 02 or 03.
Preserve the full rest of the 02 back-hair and 03 front-hair shapes and their roots, size and placement, reference white hair identity, graphite gray outlines and neutral grayscale shading.
INVARIANTS: do not change cell 04 at all; do not change ANY of cells 01 or 05 through 24. Keep the exact 6-column/4-row grid, all 01–24 labels, title, gray background, all component sizes, positions, and every garment/limb drawing unchanged. No new piece, no missing label, no new colors or added glow. This is not a redesign. Output same complete sheet and resolution.
```

