# 已确认人体步行基准与腿部提取

日期：2026-10-29。

用户明确认可 `human_walk_approved_v1.png`：“这版才对，记住了，这版才是正确的人体步行姿势”。该图来自用户提供的 `1793286884578.webp` 第二行的参考重绘；本次将已认可原文件原样保存到仓库。后续人体步行以此版本的朝左方向、01–10 顺序及双腿关系为准。此前程序生成的步行示意不作为用户认可标准。

`human_walk_approved_legs_v1.png` 使用内置 image_gen 编辑，只提取髋、双腿、脚和地面线；输出直接复制，未额外裁切或改色。目视对照十姿势顺序、直立/屈膝、跨步、脚底接触及深浅线区分。本轮腿部提取是新交付，尚待用户确认，标题中的“已确认姿势”指源图获认可。

这两张图均为视觉参考，不是精确坐标或已绑定的运行时资源。图像自动验证检查解码、宽幅布局、原图 SHA256 以及动画文档的基准链接；不以这些测试代替逐关节几何精度验收。使用带 Pillow 的 Python 执行 `python -m unittest discover -s tests`。

## 最终编辑提示词

```text
EDIT TARGET: the attached approved TEN-pose human walk skeleton sheet. The user explicitly approved these exact poses. This is a STRICT LOWER-BODY ISOLATION EDIT, not a new animation or correction.

Erase each head, neck, spine, shoulders, arms and hands. Preserve ONLY each small oval pelvis/hip pivot and the EXACT TWO attached legs, knee circles, ankle circles, heels and toes. Do not leave any hand or wrist near the hips. Preserve the lower-body drawing geometry exactly as provided, including all 10 individual poses, their differences, leg bends, foot orientation, foot-ground contacts, overlapping legs, dark/light gray stroke identities. No redrawing into a different gait. No straightening knees. No swapping legs or colors. No adding interpolated frames. No mirroring. Keep original horizontal locations and common floor baseline, all feet face LEFT as in input. Keep labels 01 02 03 04 05 06 07 08 09 10 in the same positions beneath the floor. Exactly TEN lower-body figures in ONE horizontal row, on clean white, ample side margins.
Remove the original title and replace with small Chinese title “步行腿部骨架 · 已确认姿势”. Remove the now-empty upper body area by tightening vertical composition around pelvis to floor; give generous white margin around the row. Uniform enlargement of the whole lower-body row is allowed, but no relative limb or pose changes. Graphic style remains the same thin graphite black and light gray lines, hollow joint circles, plain white background and thin floor line. NO torso, head, arms, shoulder, hands, ghost upper body, clothing, extra lines, extra text or decorations. If a foot was raised in source it must remain raised; if it touched floor it must still touch floor. Faithful extraction of the APPROVED drawing is the sole goal.
```

