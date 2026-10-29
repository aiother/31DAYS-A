"""Draw original, deterministic leg diagrams; no generated images are edited.

Units are design units, not Godot physics coordinates. The in-place pose keeps
constant segment lengths and a constant stance-foot speed relative to the root.
"""
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'codexandclaude/tasks/ART-001/references'
INK, PAPER = '#2b2420', '#efe4cc'
NEAR, FAR, GOLD = '#1f2740', '#7d4a8c', '#f4b860'
THIGH, SHIN, GROUND = 27.0, 26.0, 132.0


def pose(motion, phase):
    phase %= 1.0
    stance = 0.625 if motion == 'walk' else 0.36
    stride = 36.0 if motion == 'walk' else 44.0
    hip_y = (89 + 2 * math.cos(4 * math.pi * (phase - .10))
             if motion == 'walk' else
             87 + 5 * math.cos(4 * math.pi * (phase - .14)))
    legs = {}
    for side, shift in [('near', 0.0), ('far', .5)]:
        t = (phase + shift) % 1.0
        planted = t < stance
        if planted:
            u = t / stance
            x, lift = stride * (.5 - u), 0.0
            # Heel strike -> flat support -> toe off, with contact at y=GROUND.
            roll = -.28 * max(0, 1 - u * 5) + .55 * max(0, (u - .65) / .35)
        else:
            u = (t - stance) / (1 - stance)
            x = -stride / 2 + stride * (3 * u * u - 2 * u * u * u)
            lift = (12 if motion == 'walk' else 26) * math.sin(math.pi * u)
            roll = .55 * (1 - u) - .28 * u
        heel = (0.0, 0.0)
        toe = (11 * math.cos(roll), 11 * math.sin(roll))
        lowest = max(heel[1], toe[1])
        heel = (x, GROUND - lift - lowest)
        toe = (x + toe[0], GROUND - lift - lowest + toe[1])
        ankle = (heel[0] + 2, heel[1] - 5)
        hip = (-2 if side == 'far' else 2, hip_y)
        dx, dy = ankle[0] - hip[0], ankle[1] - hip[1]
        distance = math.hypot(dx, dy)
        if not abs(THIGH - SHIN) < distance < THIGH + SHIN:
            raise ValueError(f'Unreachable ankle: {motion}, {phase}, {side}')
        along = (THIGH ** 2 - SHIN ** 2 + distance ** 2) / (2 * distance)
        bend = math.sqrt(THIGH ** 2 - along ** 2)
        # Forward knee solution, consistent through the whole cycle.
        knee = (hip[0] + along * dx / distance + bend * dy / distance,
                hip[1] + along * dy / distance - bend * dx / distance)
        legs[side] = dict(hip=hip, knee=knee, ankle=ankle, heel=heel,
                          toe=toe, planted=planted)
    return dict(phase=phase, hip_y=hip_y, legs=legs,
                flight=not any(leg['planted'] for leg in legs.values()))


def font(size, bold=False):
    return ImageFont.truetype('C:/Windows/Fonts/msyh' + ('bd' if bold else '') + '.ttc', size)


def dashed(draw, a, b, fill, width, dash):
    length = math.dist(a, b)
    for start in range(0, math.ceil(length), dash * 2):
        end = min(start + dash, length)
        draw.line([(a[0] + (b[0] - a[0]) * t / length,
                    a[1] + (b[1] - a[1]) * t / length) for t in (start, end)],
                  fill=fill, width=width)


def figure(draw, data, origin, scale, motion):
    def pt(p):
        return (origin[0] + p[0] * scale, origin[1] + p[1] * scale)
    bob = data['hip_y'] - 89
    lean = 6 if motion == 'run' else 0
    # Original faint character construction, preserving hood/cape silhouette.
    hood = [(-36 + lean, 36 + bob), (-19 + lean, 9 + bob),
            (14 + lean, 0 + bob), (29 + lean, 13 + bob),
            (30 + lean, 44 + bob), (17 + lean, 54 + bob),
            (-13 + lean, 51 + bob), (-26 + lean, 39 + bob)]
    draw.polygon([pt(p) for p in hood], fill='#dedbd2', outline='#a99e92', width=2)
    draw.ellipse([pt((5 + lean, 17 + bob)), pt((28 + lean, 45 + bob))],
                 fill='#c5c1bf', outline='#a99e92', width=2)
    draw.line([pt((21 + lean, 29 + bob)), pt((21 + lean, 33 + bob))], fill='#fbf6ec', width=3)
    cape = [(-7 + lean, 53 + bob), (15 + lean, 53 + bob),
            (25, 95 + bob), (-45, 94 + bob), (-30, 76 + bob)]
    draw.polygon([pt(p) for p in cape], fill='#e5dfd2', outline='#b5a797', width=2)
    draw.line([pt((-43, 91 + bob)), pt((23, 92 + bob))], fill='#c9b39b', width=2)
    draw.line([pt((-2, data['hip_y'])), pt((2, data['hip_y']))], fill=INK, width=5)
    for side, color in [('far', FAR), ('near', NEAR)]:
        leg = data['legs'][side]
        for a, b in [('hip', 'knee'), ('knee', 'ankle')]:
            if side == 'far':
                dashed(draw, pt(leg[a]), pt(leg[b]), color, max(3, round(3 * scale)), max(3, round(3 * scale)))
            else:
                draw.line([pt(leg[a]), pt(leg[b])], fill=color, width=max(3, round(3 * scale)))
        draw.line([pt(leg['ankle']), pt(leg['heel']), pt(leg['toe'])], fill=color, width=round(4 * scale))
        for joint in ('hip', 'knee', 'ankle'):
            x, y = pt(leg[joint])
            r = 3.1 * scale
            draw.ellipse((x-r, y-r, x+r, y+r), fill=GOLD, outline=color, width=2)
        if leg['planted']:
            foot = max((leg['heel'], leg['toe']), key=lambda p: p[1])
            x, y = pt(foot)
            draw.line((x - 5 * scale, y + 2, x + 5 * scale, y + 2), fill=GOLD, width=3)
    draw.line([pt((-65, GROUND + 2)), pt((65, GROUND + 2))], fill='#b5a797', width=1)


def caption(data):
    if data['flight']:
        return '双脚腾空'
    supports = [side for side, leg in data['legs'].items() if leg['planted']]
    return '双脚交接' if len(supports) == 2 else ('近腿支撑' if supports[0] == 'near' else '远腿支撑')


def build():
    manifest = {'frames': 16, 'bone_lengths': [THIGH, SHIN], 'ground': GROUND, 'motions': {}}
    for motion, title, duration in [('walk', '走路', 80), ('run', '跑步', 50)]:
        poses = [pose(motion, n / 16) for n in range(16)]
        manifest['motions'][motion] = {'duration_ms': duration, 'poses': poses}
        sheet = Image.new('RGB', (1600, 1400), PAPER)
        d = ImageDraw.Draw(sheet)
        d.text((60, 24), f'{title} · 16 帧完整循环', font=font(42, True), fill=INK)
        d.text((60, 80), '《末日前31天》  /  朝右  /  腿部骨架动作参考', font=font(21), fill=INK)
        animation = []
        for n, data in enumerate(poses):
            x, y = (n % 4) * 390 + 20, (n // 4) * 300 + 125
            d.rounded_rectangle((x, y, x+380, y+290), radius=12, outline='#d4c4a9', width=2)
            d.text((x+14, y+10), f'{n+1:02}', font=font(25, True), fill=INK)
            figure(d, data, (x+185, y+24), 1.65, motion)
            d.text((x+125, y+255), caption(data), font=font(19), fill=INK)
            frame = Image.new('RGB', (480, 460), PAPER)
            fd = ImageDraw.Draw(frame)
            fd.text((24, 18), f'{title}  {n+1:02}/16', font=font(26, True), fill=INK)
            figure(fd, data, (240, 72), 2.25, motion)
            fd.text((165, 400), caption(data), font=font(22), fill=INK)
            animation.append(frame)
        d.text((40, 1340), '深蓝实线：近腿（右）   紫色虚线：远腿（左）   金点：髋 / 膝 / 踝', font=font(22), fill=INK)
        d.text((40, 1372), '按行播放 01—16 → 01 · 固定骨长 · 动作设计参考，非运行时资源', font=font(18), fill=INK)
        sheet.save(OUT / f'player_{motion}_16_rig_v1.png')
        animation[0].save(OUT / f'player_{motion}_16_preview_v1.gif', save_all=True,
                          append_images=animation[1:], duration=duration, loop=0, disposal=2)
    (OUT / 'player_locomotion_16_rig_v1.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')


if __name__ == '__main__':
    build()
