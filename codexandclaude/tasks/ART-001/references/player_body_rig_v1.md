# 玩家无披风身体绑定参考 v1

- 文件：`player_body_rig_v1.png`；生成日期：2026-10-27。
- 来源：内置 image_gen；AI 生成；套餐信息未提供。原始生成文件直接复制，未裁切或改色。
- 角色参考：`assets_src/inbox/art/player/player_01_3.png`（已认可设定）。
- 用途：补充披风下的身体形象，供 ART-002 拆层与补画参考；不是已拆层或已绑骨的运行时素材。
- 目视检查：无五官、无披风/兜帽/面纱/武器；深蓝工装、手套和靴；左侧暖边光、紫色阴影；全身留白、四肢分开。
- 局限：生成图的严格侧视与 2.5 头身仍需拆层时按设定校准；肢体根部仍存在自然遮挡，拆件时需补齐关节约 15% 重叠区。未替换游戏中的角色。
- 验证：`python -m unittest discover -s tests -p test_player_body_art.py`。

## 最终提示词（含第二次生成的约束补充）

```text
Use case: stylized-concept. Asset type: 2D side-scrolling game skeletal-animation body rigging reference, single character.
Input image: reference for the SAME character's identity, proportions, ink line style and flat colouring. Remove its cape, hood, veil and weapon completely, revealing the plain body underneath.
Hand-drawn ink illustration for a 2D side-scrolling game. Dark sepia ink outlines (#2b2420) with slight hand-drawn wobble and varying line weight, thicker outer contour. Flat colour fills with at most one light and one shadow tone, subtle ink bleed and paper texture, no gradients, no painterly rendering, no realistic lighting. Low warm dusk sunlight from the LEFT: a thin warm rim light (#f4b860) on the left edges, shadows tinted cool violet (#7d4a8c).
Match the reference image exactly in colours, line and proportions: the same small chibi character, exactly 2.5 heads tall, big round head about 40% of the height. This is the SAME character with the cape, hood and veil REMOVED, drawn as a rigging sheet for 2D skeletal animation: the plain body that is normally hidden under the cape.
Show: the big round head with a little dark hair at the sides and a smooth, very dark face with NO features (no eyes, no mouth, no nose; the eyes are drawn on the veil, not on the face); a short neck; the very dark navy work coverall (#1f2740) on the torso, hips, arms and legs, plain with a few seams; dark gloves; sturdy dark boots. Strict side view facing RIGHT, in a wide "T-pose for rigging": both arms held out and slightly down, away from the body, the far arm visible behind the body and offset so it does not overlap the near arm; legs apart in a mid-stride so the far leg is visible behind and not hidden by the near leg. The far arm and far leg are the same shape as the near ones, one tone darker, shadows more violet. Every limb drawn completely, elbows and knees clearly readable.
Whole figure visible with margin, genuinely transparent background. No dark background, no vignette, no glow, no ground shadow. Single character, no text, no frame. No cape, no hood, no veil, no ring of fragments, no weapon. No red anywhere. No teal or cyan anywhere.
Refinement priorities: only a LITTLE short dark hair at the sides of the big smooth round head, no large shaggy hairstyle, no bangs or tall tuft. Keep the entire figure inside the canvas with generous transparent padding on every side, including above head. Make head and torso a strict right-facing profile. Far arm visibly darker violet than near arm. Arms spread away from torso in rigging pose, fully readable. Legs clearly separated mid-stride, both boots pointing RIGHT. Flat cel fills, minimize texture and extra highlight tones. Head exactly 40% total figure height.
```
