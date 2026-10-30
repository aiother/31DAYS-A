"""ART-003 player-scale proposal: reference-matched mockup (camera x1.875, ground at 88%)."""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(sys.argv[1])
CAP = ROOT / "captures_ref"
OUT = ROOT / "compare"

HEIGHT = 210  # 参考画面角色约占屏高 19.5%，1080p 下约 210 px
SHIFT_WORLD = 100  # 与 compose.py 相同，把角色从检查点旗杆右移

sprite = Image.open(OUT / "sprite_frame3.png")
w, h = sprite.size
legs = sprite.getchannel("A").crop((0, int(h * 0.65), w, h)).getbbox()
anchor_x = (legs[0] + legs[2]) / 2
scale = HEIGHT / h
scaled = sprite.resize((round(w * scale), round(h * scale)), Image.LANCZOS)
reference = Image.open(ROOT / "reference" / "reference_gameplay.webp").convert("RGB").resize((1920, 1080), Image.LANCZOS)
font = ImageFont.truetype("C:/Windows/Fonts/msyhbd.ttc", 30)

for slot in ("slot2", "slot1"):
    info = json.loads((CAP / f"{slot}_zoom1.88_no_player.json").read_text())
    base = Image.open(CAP / f"{slot}_zoom1.88_no_player.png").convert("RGBA")
    fx, fy = info["feet_canvas"]
    fx += SHIFT_WORLD * info["zoom"]
    base.alpha_composite(scaled, (round(fx - anchor_x * scale), round(fy - scaled.height)))
    base = base.convert("RGB")
    base.save(OUT / f"{slot}_参考比例_镜头1.875.png")
    pair = Image.new("RGB", (1920, 2160), (0, 0, 0))
    pair.paste(reference, (0, 0))
    pair.paste(base, (0, 1080))
    draw = ImageDraw.Draw(pair)
    for y, text in ((10, "参考：实机画面（角色约 19.5% 屏高，地面在 88%）"),
                    (1090, "本作：镜头 ×1.875，玩家 210 px（19.5%），地面压到 88%")):
        draw.rectangle((640, y, 1420, y + 48), fill=(0, 0, 0))
        draw.text((656, y + 4), text, font=font, fill=(255, 236, 190))
    pair.resize((1440, 1620), Image.LANCZOS).save(OUT / f"{slot}_参考对照.png")
