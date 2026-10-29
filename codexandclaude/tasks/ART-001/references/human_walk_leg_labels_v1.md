# 步行骨架左右腿标注 v1

2026-10-29，用户指定：**右腿＝虚线、左腿＝实线**。左右按角色自身判断，不按画面位置判断。

- 文件：`human_walk_leg_labels_v1.png`；来源：内置 image_gen 编辑，输出直接复制。
- 编辑目标：本轮用户附件，内容与已确认的 `human_walk_approved_v1.png` 一致。保留原图与旧版提取图，新增标注版。
- 深蓝实线及“左 L”表示左腿；橙色虚线及“右 R”表示右腿。原脚部黑色外形保留，归属沿对应踝关节和腿链判断。
- 01–10 维持原顺序和朝左姿势；增加总图例和每个姿势的引线标签。
- 目视检查十帧均有左右腿标识，虚实线可区分。自动验证 PNG 可解码、横向画幅及文档中的用户约定；这些检查不替代逐关节坐标一致性验收。
- 验证：使用带 Pillow 的 Python 运行 `python -m unittest discover -s tests`。未修改运行时资源。

## 最终编辑提示词

```text
Precision annotation EDIT of the attached approved 10-pose skeleton image. Preserve ALL ten poses, body outlines, all head/torso/arm drawings, exact joint coordinates, limb angles, foot contact positions, left-facing direction, horizontal layout, source title and numbers01–10. Do not redesign the walk or change the pose order.
User-specified convention: RIGHT LEG = DASHED LINE, LEFT LEG = SOLID LINE. These are the character's anatomical right/left, not screen positions.
Make each leg unambiguous by tracing its existing hip→knee→ankle→foot path: LEFT leg in dark navy continuous SOLID lines, RIGHT leg in muted orange visibly DASHED lines (short separated dashes with real white gaps throughout thigh, shin and foot). Preserve the original hollow joint circles. Do not create extra legs or offset a limb. Replacing a leg's stroke style/color is allowed; changing geometry is not.
Source near/darker leg becomes LEFT solid; source far/lighter leg becomes RIGHT dashed. Where stroke color is ambiguous, use this explicit correspondence to the existing shapes, without moving any joint:
01 left=straight planted leg, right=backward bent lifted leg on screen right.
02 left=forward planted leg on screen left, right=rear trailing leg on screen right.
03 left=forward reaching leg on screen left, right=rear leg on screen right.
04 left=almost vertical planted leg on screen right, right=bent passing leg to screen left.
05 left=straight planted leg, right=backward bent raised leg to screen right.
06 left=front planted leg screen left, right=rear trailing leg screen right.
07 left=front planted leg screen left, right=rear extended toe-contact leg screen right.
08 left=forward reaching leg screen left, right=rear leg screen right.
09 left=bent lifted leg screen left, right=planted extended leg screen right.
10 left=vertical planted leg screen right, right=bent passing leg screen left.
At overlapping segments show the dashed chain legibly but never shift its joints.
Add TWO small leg labels to EVERY pose: “左 L” in navy next to solid leg and “右 R” in orange next to dashed leg, each with a short fine leader to its shin. Labels must not cover leg lines or source frame numbers. Use available whitespace beside shins, increase canvas height/margins only if needed.
Add a clean centered legend below title and above figures: a sample navy solid line followed by “左腿 L · 实线”; a sample orange dashed line followed by “右腿 R · 虚线”. Add small subtitle “左右以角色自身为准”. Color is purely annotation, monochrome upper bodies stay as in source. White background. Exactly ten complete figures, exactly original floor baseline and 01–10 indexing. Make distinction obvious at a glance and keep all poses intact.
```

