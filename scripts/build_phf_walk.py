"""Draw a schematic pose guide and package image_gen artwork without repainting.

The character pixels are produced by image_gen. Packaging only crops fixed cells
and encodes lossless PNG/APNG and shared-palette GIF previews.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "phf/walk_8_v1"
CELL = (384, 512)
ANKLES = [(238, 420), (216, 423), (192, 423), (168, 415),
          (145, 411), (157, 399), (190, 398), (225, 408)]
HEELS = [(225, 450), (202, 450), (178, 450), (157, 436),
         (138, 429), (148, 421), (178, 423), (212, 437)]
TOES = [(270, 444), (249, 450), (224, 450), (196, 450),
        (172, 450), (180, 440), (220, 428), (258, 435)]
PHASES = ["heel contact", "load / down", "support / passing", "toe support / up",
          "toe off", "early swing", "swing passing", "terminal swing"]
BOB = [2, 5, 0, -6]
LENGTHS = (84.0, 86.0)


def solve_knee(hip, ankle):
    dx, dy = ankle[0] - hip[0], ankle[1] - hip[1]
    distance = math.hypot(dx, dy)
    upper, lower = LENGTHS
    if not abs(upper - lower) < distance < upper + lower:
        raise ValueError("Unreachable ankle")
    along = (upper**2 - lower**2 + distance**2) / (2 * distance)
    perpendicular = math.sqrt(upper**2 - along**2)
    # Facing right, the knee bends forwards in both stance and swing.
    return (hip[0] + along * dx / distance + perpendicular * dy / distance,
            hip[1] + along * dy / distance - perpendicular * dx / distance)


def motion_plan():
    frames = []
    for index in range(8):
        hip = (192, 260 + BOB[index % 4])
        legs = {}
        for side, offset in (("left", 0), ("right", 4)):
            phase = (index + offset) % 8
            legs[side] = {
                "phase": PHASES[phase], "phase_index": phase,
                "depth": "near" if side == "left" else "far",
                "marker": "orange_dot" if side == "left" else "blue_double_bar",
                "hip": hip, "knee": solve_knee(hip, ANKLES[phase]),
                "ankle": ANKLES[phase], "heel": HEELS[phase], "toe": TOES[phase],
            }
        frames.append({"frame": index + 1, "legs": legs,
                       "support": "left" if index < 4 else "right"})
    return {"frames": frames, "cell_size": CELL, "grid": [4, 2],
            "leg_lengths": LENGTHS, "ground_y": 450,
            "scope": "Pose guide only; not measured character joints."}


def guide():
    ART.mkdir(parents=True, exist_ok=True)
    plan = motion_plan()
    canvas = Image.new("RGB", (1536, 1024), "#f2f0ea")
    draw = ImageDraw.Draw(canvas)
    for frame in plan["frames"]:
        index = frame["frame"] - 1
        ox, oy = index % 4 * 384, index // 4 * 512
        pt = lambda p: (round(p[0] + ox), round(p[1] + oy))
        draw.rectangle((ox+1, oy+1, ox+383, oy+511), outline="#bbb7ad")
        draw.text((ox+12, oy+12), f"{index+1:02}  LEFT NEAR / RIGHT FAR", fill="#333333")
        draw.line((ox+24, oy+450, ox+360, oy+450), fill="#99978f", width=2)
        bob = BOB[index % 4]
        draw.ellipse((ox+152, oy+62+bob, ox+238, oy+153+bob),
                     outline="#777777", width=3)
        draw.polygon([pt((235,100+bob)), pt((248,120+bob)), pt((235,128+bob))],
                     outline="#777777")
        draw.line([pt((192,164+bob)), pt((192,260+bob))], fill="#777777", width=12)
        draw.line([pt((192,180+bob)), pt((134,245+bob)), pt((122,307+bob))],
                  fill="#999999", width=7)
        draw.line([pt((192,180+bob)), pt((235,245+bob)), pt((245,302+bob))],
                  fill="#999999", width=7)
        # The far right is always drawn first, independent of horizontal position.
        for side, color in (("right", "#2577bf"), ("left", "#e07326")):
            leg = frame["legs"][side]
            draw.line([pt(leg[k]) for k in ("hip", "knee", "ankle")],
                      fill=color, width=13)
            draw.line([pt(leg[k]) for k in ("heel", "ankle", "toe", "heel")],
                      fill=color, width=7)
            for joint in ("hip", "knee", "ankle"):
                x, y = pt(leg[joint])
                draw.ellipse((x-5,y-5,x+5,y+5), fill=color, outline="white", width=2)
            x, y = pt(leg["ankle"])
            draw.text((x+10,y-25), "L" if side == "left" else "R", fill=color)
        draw.text((ox+12, oy+470), "L: " + frame["legs"]["left"]["phase"], fill="#c25a14")
        draw.text((ox+12, oy+487), "R: " + frame["legs"]["right"]["phase"], fill="#2577bf")
    canvas.save(ART / "pose_control.png")
    (ART / "motion_plan.json").write_text(json.dumps(plan, indent=2)+"\n", encoding="utf-8")


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def package():
    rig = json.loads((ART / "rig.json").read_text(encoding="utf-8"))
    frames = []
    for index in range(8):
        with Image.open(ART / "frames" / f"walk_{index+1:02}.png") as image:
            frames.append(image.convert("RGBA"))
    if any(frame.size != (768, 1024) for frame in frames):
        raise ValueError("All eight frames must use the same 768 x 1024 canvas")
    frames[0].save(ART / "walk_8.apng", format="PNG", save_all=True,
                   append_images=frames[1:], duration=125, loop=0, disposal=0, blend=0)

    def gif(source_frames, name, durations):
        previews = []
        for frame in source_frames:
            # A common preview-only reduction; project PNG/APNG stay full-size.
            reduced = frame.resize(CELL, Image.Resampling.LANCZOS)
            bg = Image.new("RGBA", CELL, "#dad8d1")
            previews.append(Image.alpha_composite(bg, reduced).convert("RGB"))
        strip = Image.new("RGB", (384 * 8, 512))
        for index, frame in enumerate(previews):
            strip.paste(frame, (index * 384, 0))
        palette = strip.quantize(colors=256)
        indexed = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in previews]
        indexed[0].save(ART / name, save_all=True, append_images=indexed[1:],
                        duration=durations, loop=0, disposal=2, optimize=False)

    gif(frames, "walk_preview.gif", [120, 130] * 4)
    gif(frames, "walk_slow.gif", 250)
    audit = []
    for index in range(8):
        with Image.open(ART / "audit_frames" / f"walk_{index+1:02}.png") as image:
            audit.append(image.convert("RGBA"))
    gif(audit, "walk_leg_audit.gif", 250)
    refs = [ROOT / "phf" / name for name in
            ["原案v0.1.png", "三视图_1.png", "三视图_2.png", "部件_1.png", "步行骨骼图.png"]]
    files = sorted(p for p in ART.rglob("*") if p.is_file() and p.name not in
                   {"manifest.json", "qa_report.json"})
    manifest = {
        "frame_count": 8, "cell_size": [768, 1024], "grid": [4, 2],
        "fps": 8, "cycle_ms": 1000, "apng_frame_ms": 125,
        "gif_frame_ms": [120, 130] * 4, "slow_frame_ms": 250,
        "tool": "image_gen", "generation_mode": "built-in",
        "animation": "Fixed image_gen raster parts; rigid skeleton; no per-frame scale changes.",
        "left": "anatomical left; near; orange L in audit only",
        "right": "anatomical right; far; blue R in audit only",
        "references": [{"file": p.relative_to(ROOT).as_posix(), "sha256": sha256(p)} for p in refs],
        "files": [{"file": p.relative_to(ART).as_posix(), "sha256": sha256(p)} for p in files],
        "verification_scope": "Tests check real rig transforms, file integrity, pixel sizes, "
                              "alpha, head stability, fixed layering and lossless APNG playback. "
                              "Naturalness and fidelity additionally require visual review.",
        "rig_frames": len(rig["frames"]),
    }
    (ART / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False)+"\n", encoding="utf-8")
    bounds = [frame.getchannel("A").point(lambda v: 255 if v > 32 else 0).getbbox() for frame in frames]
    print(json.dumps({"frames": 8, "size": [768, 1024], "bounds": bounds, "files": len(files)}))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["guide", "package"])
    args = parser.parse_args()
    guide() if args.action == "guide" else package()
