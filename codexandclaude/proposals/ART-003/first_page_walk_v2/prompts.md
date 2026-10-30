# 初页：带左右腿标识的 8 帧行走

2026-10-30。内置 image_gen；参考已确认三视图与运动控制图，生成新的 4×2 帧表。透明背景。左腿近侧亮白、靴口橙色圆点；右腿远侧浅灰、靴口蓝色双短线。标识仅用于本轮动作核对。

```text
Use case: stylized-concept.
Create a fresh EXACTLY EIGHT FRAME WALK animation sprite sheet of the approved white protagonist 初页. Image 1 is the character's identity/costume reference; match its center RIGHT-FACING PROFILE. Image 2 is the precise 8-frame leg-motion control guide: follow each individually identified leg through the entire cycle. This is NOT eight arbitrary walk poses.

Output: 1536x1024, FOUR columns and TWO rows, row-major order 01 02 03 04 / 05 06 07 08. Each cell 384x512, one complete character, truly transparent RGBA background. At least 24px empty alpha padding around every character inside its cell. No background, no ground drawing, no checkerboard, no glow or haze, no shadow, no labels or borders. Same stationary pelvis x=192 in each cell, same scale, sole contact baseline y=450, head top around y=60; characters approximately 390px tall. All face RIGHT in strict side profile.

APPEARANCE INVARIANTS: same youthful androgynous face, white layered short hair, single small flipped forelock, tiny neutral gray eye, white folded standing collar, small WHITE diamond throat clasp, soft short triangular white cape, white shorts, slender white legs and folded-cuff white ankle boots, faithful to reference 1. Thin hand-drawn graphite-gray contour and restrained flat white/pale-gray fill, 2D, not 3D. BOTH arms and BOTH hands remain completely hidden by the cape and do not swing. Cape stays SHORT and exposes both knees, calves and complete boots. Only very mild cape hem/forelock settling; no new garment folds or accessories appearing/disappearing. Do not alter head size, face, boot type, collar or cape length across frames.

FIXED IDENTITIES, CRITICAL:
LEFT LEG = camera-near leg = BRIGHT WHITE leg and boot. Put ONE small clearly visible ORANGE FILLED CIRCLE on its boot cuff, SAME leg in ALL 8 frames. Always drawn in front when legs overlap.
RIGHT LEG = camera-far leg = NEUTRAL LIGHT GRAY leg and boot (#c8c8c8). Put TWO short BLUE PARALLEL BARS on its boot cuff, SAME leg in ALL 8 frames. Always behind the white near leg at overlap.
These tiny colored symbols are deliberate animation-inspection labels, not a costume recoloring. No other colors anywhere. Each frame must show exactly one orange-dot boot and exactly one blue-double-bar boot, each attached continuously to its own thigh/knee/shin. Keep markings visible during crossing by preserving the swing foot's correct vertical clearance, NEVER swapping markers onto another leg. No extra feet or fused legs.

FULL MOTION OF EACH LEG:
Orange-dot LEFT leg goes BACK -> LIFT -> UNDER BODY -> FORWARD -> HEEL CONTACT -> SUPPORT -> UNDER BODY -> BACK -> repeat. Its forward swing is continuous through frames 01/02/03/04/05; it MUST NOT reset or get replaced by the right leg before reaching front contact in 05.
Blue-bars RIGHT leg follows the SAME full closed trajectory offset exactly four frames. It supports in 01/02/03/04, then swings continuously in 05/06/07/08/01. It MUST NOT reset before reaching front contact in 01.

EXACT frame poses; all positions local to EACH cell. Preserve anatomical limb lengths; knees bend naturally FORWARD, and boot toes face right:
01: ORANGE LEFT ankle BACK at x145,y411, rear toe push-off; BLUE RIGHT ankle FRONT at x238,y419, heel makes contact. Left orange boot is behind, right blue boot in front.
02: ORANGE LEFT lifts from rear x157,y399, knee swings forward, heel lifted and boot off floor. BLUE RIGHT accepts body weight, flat planted foot x216,y423, slight knee flex. Body slightly lower.
03: ORANGE LEFT passes forward UNDER HIP x190,y398, swing knee ahead and lower leg folded back, its raised boot crosses IN FRONT of stance leg. BLUE RIGHT stays planted beneath hip x192,y423. Orange swing boot must be lifted above blue stance boot, not placed on the ground.
04: ORANGE LEFT extends FORWARD x225,y408, orange boot ahead preparing heel contact, slightly above ground. BLUE RIGHT moves BACK into toe support x168,y415, heel lifts. Body slightly higher. Orange left is now clearly the forward boot, and remains the forward boot in frame 05.
05: ORANGE LEFT finishes its forward swing and lands HEEL-FIRST FRONT at x238,y419. BLUE RIGHT finishes rear push-off at x145,y411. Orange left boot is front, blue right boot is rear. DO NOT repeat pose 01 with the same forward foot.
06: ORANGE LEFT accepts weight, flat planted foot x216,y423. BLUE RIGHT lifts from rear x157,y399 with forward knee flex. Orange remains support; do not abruptly return it to rear.
07: ORANGE LEFT stays planted beneath hip x192,y423. BLUE RIGHT swing ankle passes beneath body x190,y398, knee ahead, lower leg folded back, raised boot crossing BEHIND near white leg. Blue boot remains off floor, orange sole supports.
08: ORANGE LEFT now trails on toe x168,y415, heel raised. BLUE RIGHT extends FORWARD x225,y408, raised boot preparing its next heel contact in 01. The 08->01 change is a small natural continuation to right heel contact, not a snap, reversal, leg identity swap, or duplicate endpoint.

Kinematics: at least one foot supports on baseline y450 in every frame; no airborne run or hopping. Support feet travel consistently backward relative to stationary torso; swing feet travel continuously from rear to front. Modest normal walking stride, slight twice-per-cycle body bob, proper heel-to-toe roll. No sliding stance resets or reverse-bending knees.
Do not draw the guide's sticks, circles at joints, head circle, text, floor or grid. Render the complete approved character around these controlled motions. Final result must be eight consistent COMPLETE character drawings with leg labels and the exact left/right temporal logic above.
```
