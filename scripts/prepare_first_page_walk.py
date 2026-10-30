"""Build a motion-control diagram and package image_gen's eight walk frames.

Character artwork is generated/edited only with image_gen. This script creates
a separate schematic guide, then crops fixed cells and encodes previews without
painting, warping, retiming, interpolating or otherwise redrawing the character.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "codexandclaude/proposals/ART-003/first_page_walk_v2"
CELL = (384, 512)
GROUND = 450
UPPER, LOWER = 80.0, 84.0
ANKLES = [(238, 419), (216, 423), (192, 423), (168, 415),
          (145, 411), (157, 399), (190, 398), (225, 408)]
HEELS = [(225, 450), (202, 450), (178, 450), (157, 436),
         (138, 429), (148, 421), (178, 423), (212, 437)]
TOES = [(270, 444), (249, 450), (224, 450), (196, 450),
        (172, 450), (180, 440), (220, 428), (258, 435)]
PHASES = ("heel_contact", "weight_acceptance", "midstance", "terminal_stance",
          "toe_off", "early_swing", "swing_passing", "terminal_swing")
BOB = (2, 3, 0, -7)


def knee_for(hip, ankle):
    dx, dy = ankle[0] - hip[0], ankle[1] - hip[1]
    distance = math.hypot(dx, dy)
    if not abs(UPPER - LOWER) < distance < UPPER + LOWER:
        raise ValueError("Unreachable ankle")
    along = (UPPER ** 2 - LOWER ** 2 + distance ** 2) / (2 * distance)
    perpendicular = math.sqrt(UPPER ** 2 - along ** 2)
    middle = (hip[0] + along * dx / distance, hip[1] + along * dy / distance)
    candidates = [(middle[0] + s * perpendicular * dy / distance,
                   middle[1] - s * perpendicular * dx / distance) for s in (-1, 1)]
    # Facing right: the knee bends forward; never select the reversed solution.
    return max(candidates, key=lambda point: point[0])


def motion_plan():
    frames = []
    for index in range(8):
        hip = (192, 260 + BOB[index % 4])
        legs = {}
        for side, offset in (("near_left", 4), ("far_right", 0)):
            phase = (index + offset) % 8
            ankle = ANKLES[phase]
            legs[side] = {
                "hip": hip, "knee": knee_for(hip, ankle), "ankle": ankle,
                "heel": HEELS[phase], "toe": TOES[phase], "phase": PHASES[phase],
                "marker": "orange_dot" if side == "near_left" else "blue_double_bar",
            }
        frames.append({
            "frame": index + 1, "phase": PHASES[(index + 4) % 8],
            "stance": "far_right" if index < 4 else "near_left",
            "hip": hip, "legs": legs,
        })
    return {
        "frame_count": 8, "columns": 4, "rows": 2, "cell_size": CELL,
        "fps": 8, "duration_ms": 125, "ground_y": GROUND,
        "direction": "right", "near_left": "white with orange dot on boot cuff",
        "far_right": "neutral light gray with blue double bar on boot cuff",
        "leg_lengths": {"thigh": UPPER, "shin": LOWER},
        "note": "Motion control coordinates are guidance, not measured artwork joints.",
        "frames": frames,
    }


def guide():
    ART.mkdir(parents=True, exist_ok=True)
    plan = motion_plan()
    image = Image.new("RGB", (CELL[0] * 4, CELL[1] * 2), "#565656")
    draw = ImageDraw.Draw(image)
    for item in plan["frames"]:
        col, row = (item["frame"] - 1) % 4, (item["frame"] - 1) // 4
        ox, oy = col * CELL[0], row * CELL[1]
        point = lambda p: (round(p[0] + ox), round(p[1] + oy))
        draw.rectangle((ox + 1, oy + 1, ox + CELL[0] - 1, oy + CELL[1] - 1),
                       outline="#777777")
        draw.text((ox + 16, oy + 16), str(item["frame"]).zfill(2) + " " + item["phase"],
                  fill="white")
        draw.line((ox + 22, oy + GROUND, ox + CELL[0] - 22, oy + GROUND),
                  fill="#9c9c9c", width=2)
        hip = item["hip"]
        head_y = 103 + BOB[(item["frame"] - 1) % 4]
        draw.ellipse((ox + 153, oy + head_y - 42, ox + 237, oy + head_y + 42),
                     outline="#a0a0a0", width=2)
        draw.line((point((hip[0], 175 + BOB[(item["frame"] - 1) % 4])), point(hip)),
                  fill="#b0b0b0", width=8)
        for side, color in (("far_right", "#a5a5a5"), ("near_left", "#ffffff")):
            leg = item["legs"][side]
            draw.line([point(leg[k]) for k in ("hip", "knee", "ankle")],
                      fill=color, width=9)
            draw.line([point(leg[k]) for k in ("heel", "ankle", "toe", "heel")],
                      fill=color, width=6)
            for name in ("hip", "knee", "ankle"):
                x, y = point(leg[name])
                draw.ellipse((x - 5, y - 5, x + 5, y + 5), fill=color, outline="#333333")
            mx, my = point((leg["ankle"][0] - 6, leg["ankle"][1] - 9))
            if side == "near_left":
                draw.ellipse((mx - 5, my - 5, mx + 5, my + 5), fill="#e66a32")
            else:
                for delta in (-4, 3):
                    draw.line((mx - 7, my + delta, mx + 7, my + delta), fill="#368de0", width=3)
        draw.text((ox + 14, oy + 478), "LEFT=ORANGE DOT   RIGHT=BLUE ||", fill="#dedede")
    image.save(ART / "walk_motion_guide.png")
    (ART / "motion_plan.json").write_text(
        json.dumps(plan, indent=2) + "\n", encoding="utf-8")


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def marker_measurements(frame):
    """Read the generated artwork's labels; never infer identity from foot order."""
    rgba = frame.convert("RGBA")
    data = rgba.load()
    pixels = {"left": [], "right": []}
    for y in range(frame.height // 2, frame.height):
        for x in range(frame.width):
            r, g, b, a = data[x, y]
            if a < 100:
                continue
            if r > 130 and r > g + 30 and g > b + 12:
                pixels["left"].append((x, y))
            elif b > 100 and b > r + 30 and b > g + 8 and g > r + 8:
                pixels["right"].append((x, y))
    result = {}
    for side, points in pixels.items():
        if not points:
            raise ValueError(f"Missing {side} boot label")
        todo = set(points)
        components = []
        while todo:
            seed = todo.pop()
            stack, component = [seed], [seed]
            while stack:
                x, y = stack.pop()
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        other = (x + dx, y + dy)
                        if other in todo:
                            todo.remove(other)
                            component.append(other)
                            stack.append(other)
            if len(component) >= max(3, len(points) * 0.01):
                components.append(len(component))
        result[side] = {
            "x": round(sum(p[0] for p in points) / len(points), 3),
            "y": round(sum(p[1] for p in points) / len(points), 3),
            "pixels": len(points), "components": sorted(components, reverse=True),
        }
    return result


def audit_frames(frames):
    measured = [marker_measurements(frame) for frame in frames]
    width, height = frames[0].size
    tolerance = width * 0.025
    failures = []
    def check_path(side, indices, direction):
        positions = [measured[i][side]["x"] for i in indices]
        deltas = [b - a for a, b in zip(positions, positions[1:])]
        if direction * (positions[-1] - positions[0]) < width * 0.12:
            failures.append(f"{side} has no complete {direction:+} travel: {positions}")
        if any(direction * delta < -tolerance for delta in deltas):
            failures.append(f"{side} reverses or swaps identity in {indices}: {positions}")
    check_path("left", [0, 1, 2, 3, 4], 1)
    check_path("right", [4, 5, 6, 7, 0], 1)
    check_path("left", [4, 5, 6, 7, 0], -1)
    check_path("right", [0, 1, 2, 3, 4], -1)
    for i, expected_forward in ((0, "right"), (3, "left"), (4, "left"), (7, "right")):
        other = "right" if expected_forward == "left" else "left"
        if measured[i][expected_forward]["x"] <= measured[i][other]["x"] + width * 0.06:
            failures.append(f"Frame {i + 1}: wrong forward leg")
    for i, swinging, stance in ((2, "left", "right"), (6, "right", "left")):
        if measured[i][swinging]["y"] >= measured[i][stance]["y"] - height * 0.01:
            failures.append(f"Frame {i + 1}: passing foot not lifted")
    for i, frame in enumerate(measured):
        if len(frame["left"]["components"]) != 1:
            failures.append(f"Frame {i + 1}: left marker is not one continuous dot")
        if len(frame["right"]["components"]) != 2:
            failures.append(f"Frame {i + 1}: right marker is not two separate bars")
    return {"passed": not failures, "failures": failures, "marker_tracks": measured,
            "scope": "Measured boot labels and path continuity; anatomy and identity also need visual review."}


def package():
    source = ART / "player_walk_8_sheet.png"
    image = Image.open(source)
    image.load()
    if image.mode != "RGBA" or image.width % 4 or image.height % 2:
        raise ValueError("Expected a true-alpha RGBA sheet divisible into 4x2 cells")
    width, height = image.width // 4, image.height // 2
    frame_dir = ART / "frames"
    frame_dir.mkdir(exist_ok=True)
    frames = []
    for index in range(8):
        col, row = index % 4, index // 4
        frame = image.crop((col * width, row * height, (col + 1) * width, (row + 1) * height))
        if not frame.getchannel("A").getbbox():
            raise ValueError(f"Frame {index + 1} is empty")
        frame.save(frame_dir / f"player_walk_{index + 1:02}.png")
        frames.append(frame)
    # Lossless animated PNG retains the exact RGBA pixels and all eight poses.
    frames[0].save(ART / "player_walk_8.apng", format="PNG", save_all=True,
                   append_images=frames[1:], duration=125, loop=0, disposal=0, blend=0)
    previews = []
    for frame in frames:
        background = Image.new("RGBA", frame.size, "#777777")
        previews.append(Image.alpha_composite(background, frame).convert("RGB"))
    # Use one shared palette, avoiding per-frame palette flicker.
    palette_strip = Image.new("RGB", (width * 8, height))
    for i, frame in enumerate(previews):
        palette_strip.paste(frame, (i * width, 0))
    palette = palette_strip.quantize(colors=256)
    gif_frames = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in previews]
    for name, duration in (("player_walk_preview.gif", [120, 130] * 4), ("player_walk_slow.gif", 250)):
        gif_frames[0].save(ART / name, save_all=True, append_images=gif_frames[1:],
                           duration=duration, loop=0, disposal=2, optimize=False)
    files = [source, ART / "player_walk_8.apng", ART / "player_walk_preview.gif",
             ART / "player_walk_slow.gif", *sorted(frame_dir.glob("*.png"))]
    metadata = {
        "tool": "image_gen", "generation_mode": "built-in", "frame_count": 8,
        "grid": [4, 2], "cell_size": [width, height], "fps": 8,
        "apng_duration_ms": 125, "gif_durations_ms": [120, 130] * 4, "slow_gif_duration_ms": 250,
        "near_leg": "near_left, white, orange dot", "far_leg": "far_right, gray, blue double bar",
        "processing": "Fixed-cell extraction and animation encoding only; no repaint or deformation.",
        "reference_sha256": "a32debf9dbf6fd7148e7f6f7a0ef9fe7748682162d167a1b63bff2eaddf84ba6",
        "files": [{"file": p.relative_to(ART).as_posix(), "sha256": sha256(p)}
                  for p in files],
    }
    (ART / "manifest.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    audit = audit_frames(frames)
    (ART / "qa_report.json").write_text(json.dumps(audit, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"cell_size": [width, height], "files": len(files), "audit": audit}))
    if not audit["passed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=("guide", "package"))
    args = parser.parse_args()
    guide() if args.action == "guide" else package()

