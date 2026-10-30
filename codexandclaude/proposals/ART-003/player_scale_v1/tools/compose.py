"""ART-003 player-scale proposal: matte one walk frame and paste it into real gameplay captures."""
import json
import sys
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(sys.argv[1])
SHEET = Path(sys.argv[2])
CAP = ROOT / "captures"
OUT = ROOT / "compare"
OUT.mkdir(exist_ok=True)

BASE_HEIGHT = 112  # asset_spec 第 1 节：玩家显示高度（1080p，头顶到脚底）
FACTOR = 1.5
FRAME = 3  # 步行第 3 帧（经过位），姿态最收拢


def matte(cell: Image.Image) -> Image.Image:
    rgb = cell.convert("RGB")
    w, h = rgb.size
    px = rgb.load()
    bg = px[3, 3]
    dist = lambda p: max(abs(p[0] - bg[0]), abs(p[1] - bg[1]), abs(p[2] - bg[2]))
    # Background = gray connected to the border; interior grays (far leg) survive.
    outside = [[False] * w for _ in range(h)]
    queue = deque((x, y) for x in range(w) for y in (0, h - 1))
    queue.extend((x, y) for y in range(h) for x in (0, w - 1))
    while queue:
        x, y = queue.popleft()
        if outside[y][x] or dist(px[x, y]) > 14:
            continue
        outside[y][x] = True
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not outside[ny][nx]:
                queue.append((nx, ny))
    out = Image.new("RGBA", (w, h))
    op = out.load()
    for y in range(h):
        for x in range(w):
            p = px[x, y]
            if outside[y][x]:
                continue
            # Edge pixels next to background get a soft alpha and are un-mixed from gray.
            edge = any(0 <= x + dx < w and 0 <= y + dy < h and outside[y + dy][x + dx]
                       for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            a = min(1.0, dist(p) / 40.0) if edge else 1.0
            if a <= 0.02:
                continue
            c = tuple(max(0, min(255, round((p[i] - (1 - a) * bg[i]) / a))) for i in range(3))
            op[x, y] = (*c, round(a * 255))
    return out.crop(out.getbbox())


sheet = Image.open(SHEET)
col, row = (FRAME - 1) % 4, (FRAME - 1) // 4
sprite = matte(sheet.crop((col * 384, row * 512, (col + 1) * 384, (row + 1) * 512)))
sprite.save(OUT / "sprite_frame3.png")

# Horizontal anchor: centre of the lowest 35% (legs), so feet sit over the capsule.
alpha = sprite.getchannel("A")
w, h = sprite.size
legs = alpha.crop((0, int(h * 0.65), w, h)).getbbox()
anchor_x = (legs[0] + legs[2]) / 2


SHIFT_WORLD = 100  # 把角色从检查点旗杆右移，避免遮挡


def paste(capture: str, height: float, label: str, note: str) -> Image.Image:
    info = json.loads((CAP / f"{capture}.json").read_text())
    base = Image.open(CAP / f"{capture}.png").convert("RGBA")
    scale = height / h
    s = sprite.resize((round(w * scale), round(h * scale)), Image.LANCZOS)
    fx, fy = info["feet_canvas"]
    fx += SHIFT_WORLD * info["zoom"]
    base.alpha_composite(s, (round(fx - anchor_x * scale), round(fy - s.height)))
    draw = ImageDraw.Draw(base)
    font = ImageFont.truetype("C:/Windows/Fonts/msyhbd.ttc", 40)
    small = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 26)
    draw.rectangle((660, 520, 1460, 640), fill=(0, 0, 0, 200))
    draw.text((684, 530), label, font=font, fill=(255, 236, 190))
    draw.text((684, 590), note, font=small, fill=(230, 230, 230))
    return base


rooms = {"slot2": "堑壕第二间", "slot1": "无顶深谷·起始区"}
for slot, room in rooms.items():
    shots = {
        "0_基准": paste(f"{slot}_zoom1.00_no_player", BASE_HEIGHT, "基准 · 现行规格",
                         f"{room}  镜头 1.0  玩家显示 112 px"),
        "A_镜头1.5": paste(f"{slot}_zoom1.50_no_player", BASE_HEIGHT * FACTOR, "方案 A · 镜头整体拉近 ×1.5",
                         f"{room}  世界与玩家同步放大  玩家 168 px  视野 1280×720 世界单位"),
        "B_玩家1.5": paste(f"{slot}_zoom1.00_no_player", BASE_HEIGHT * FACTOR, "方案 B · 只放大玩家 ×1.5",
                         f"{room}  镜头 1.0  玩家 168 px  世界、敌人、平台不变"),
    }
    for name, image in shots.items():
        image.convert("RGB").save(OUT / f"{slot}_{name}.png")
    # Side-by-side contact sheet (half size) for quick comparison.
    sheet_img = Image.new("RGB", (960 * 3 + 40, 540 + 20), (20, 20, 20))
    for i, image in enumerate(shots.values()):
        sheet_img.paste(image.convert("RGB").resize((960, 540), Image.LANCZOS), (10 + i * 970, 10))
    sheet_img.save(OUT / f"{slot}_对比.png")
print("sprite", sprite.size, "anchor", anchor_x)

# Close-up of the player area: baseline / A / B (B shows the head entering the low platform).
crops = ((f"slot2_0_基准.png", (150, 600, 750, 860)), (f"slot2_A_镜头1.5.png", (300, 600, 1000, 900)),
         (f"slot2_B_玩家1.5.png", (150, 600, 750, 860)))
close = Image.new("RGB", (600 + 700 + 600 + 20, 300), (20, 20, 20))
x = 0
for name, box in crops:
    part = Image.open(OUT / name).crop(box)
    close.paste(part, (x, 0))
    x += part.width + 10
close.save(OUT / "slot2_角色特写.png")
