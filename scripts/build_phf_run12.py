"""Control guide and fixed-cell packaging for image_gen's twelve-frame run.

The control skeleton has fixed lengths. Its joints are guidance, not a claim
that generated artwork joints have been measured at those exact positions.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "phf/run_12_v1"
CELL = (384, 512)
PUBLISH_CELL = (448, 512)
GROUND = 450
UPPER, LOWER = 84.0, 86.0
BOB = (265, 276, 266, 254, 249, 255)
ANKLES = [(244, 415), (200, 422), (122, 399), (75, 365), (91, 325), (104, 314),
          (118, 334), (160, 320), (204, 342), (236, 360), (258, 386), (258, 410)]
PITCH = (10, 0, 35, 60, 65, 60, 40, 20, -5, -12, -10, -3)
PHASES = ("forefoot_contact", "compression_and_drive", "toe_off_release", "flight_release",
          "heel_kick", "rear_fold", "recovery_passing", "folded_forward",
          "knee_drive", "forward_swing", "swing_extension", "terminal_swing")


def rotate(point, degrees):
    a = math.radians(degrees)
    x, y = point
    return (x*math.cos(a)-y*math.sin(a), x*math.sin(a)+y*math.cos(a))


def knee_for(hip, ankle):
    dx, dy = ankle[0]-hip[0], ankle[1]-hip[1]
    distance = math.hypot(dx, dy)
    if not abs(UPPER-LOWER) < distance < UPPER+LOWER:
        raise ValueError(f"Unreachable ankle {hip} -> {ankle}")
    along = (UPPER**2-LOWER**2+distance**2)/(2*distance)
    perpendicular = math.sqrt(UPPER**2-along**2)
    return (hip[0]+along*dx/distance+perpendicular*dy/distance,
            hip[1]+along*dy/distance-perpendicular*dx/distance)


def plan():
    frames = []
    for index in range(12):
        hip = (192, BOB[index % 6])
        shoulder = (229, hip[1]-84)
        legs = {}
        arms = {}
        for side, offset, depth, marker in (("right", 0, "near", "orange_dot"),
                                            ("left", 6, "far", "blue_double_bar")):
            phase = (index+offset) % 12
            pitch = PITCH[phase]
            heel_offset = rotate((-13, 28), pitch)
            toe_offset = rotate((35, 28), pitch)
            ankle = list(ANKLES[phase])
            grounded = phase <= 1
            if grounded:
                ankle[1] = GROUND-max(heel_offset[1], toe_offset[1])
            heel = (ankle[0]+heel_offset[0], ankle[1]+heel_offset[1])
            toe = (ankle[0]+toe_offset[0], ankle[1]+toe_offset[1])
            legs[side] = {"phase_index": phase, "phase": PHASES[phase],
                          "depth": depth, "marker": marker, "grounded": grounded,
                          "hip": hip, "knee": knee_for(hip, ankle), "ankle": ankle,
                          "heel": heel, "toe": toe, "pitch": pitch,
                          "marker_position": (ankle[0], ankle[1]-8)}
            swing = 50*math.cos((phase-3)*math.pi/6)
            elbow = (shoulder[0]+55*math.sin(math.radians(swing)),
                     shoulder[1]+55*math.cos(math.radians(swing)))
            wrist = (elbow[0]+35, elbow[1]-40)
            arms[side] = {"shoulder": shoulder, "elbow": elbow, "wrist": wrist}
        flight = not any(leg["grounded"] for leg in legs.values())
        frames.append({"frame": index+1, "hip": hip, "shoulder": shoulder,
                       "head_center": (250, hip[1]-150), "legs": legs, "arms": arms,
                       "flight": flight, "support": "none" if flight else
                       ("right" if index < 6 else "left")})
    return {"frame_count": 12, "grid": [4, 3], "cell_size": CELL,
            "fps": 20, "frame_ms": 50, "cycle_ms": 600,
            "ground_y": GROUND, "leg_lengths": [UPPER, LOWER],
            "identity": {"right": "orange dot; near/outside; bright ivory",
                         "left": "blue double bar; far/inside; gray"},
            "scope": "Control skeleton, not measured generated-art joints.", "frames": frames}


def guide():
    ART.mkdir(parents=True, exist_ok=True)
    data = plan()
    canvas = Image.new("RGB", (1536, 1536), "#eeeeea")
    draw = ImageDraw.Draw(canvas)
    for frame in data["frames"]:
        index = frame["frame"]-1
        ox, oy = index % 4*384, index // 4*512
        pt = lambda p: (round(p[0]+ox), round(p[1]+oy))
        draw.rectangle((ox+1, oy+1, ox+383, oy+511), outline="#bbbbbb")
        draw.text((ox+12, oy+12), f"{index+1:02}  "+("FLIGHT" if frame["flight"] else "SUPPORT "+frame["support"].upper()), fill="#333333")
        draw.line((ox+22, oy+GROUND, ox+362, oy+GROUND), fill="#aaa99e", width=2)
        hx, hy = frame["head_center"]
        draw.ellipse((ox+hx-43, oy+hy-48, ox+hx+43, oy+hy+48), outline="#888888", width=3)
        draw.line([pt(frame["shoulder"]), pt(frame["hip"])], fill="#777777", width=12)
        draw.line([pt((hx, hy+46)), pt(frame["shoulder"])], fill="#888888", width=6)
        # Cape envelope supplies a backwards-streaming silhouette, not a new design.
        sx, sy = frame["shoulder"]
        draw.line([pt((sx,sy)),pt((77,sy+65)),pt((104,sy+122)),pt((196,sy+100))],
                  fill="#b6b3a7", width=2)
        for side, color in (("left", "#287dc2"), ("right", "#e87527")):
            arm = frame["arms"][side]
            draw.line([pt(arm[k]) for k in ("shoulder","elbow","wrist")], fill=color, width=7)
            leg = frame["legs"][side]
            draw.line([pt(leg[k]) for k in ("hip","knee","ankle")], fill=color, width=11)
            draw.line([pt(leg[k]) for k in ("heel","ankle","toe","heel")], fill=color, width=6)
            for k in ("hip","knee","ankle"):
                x,y=pt(leg[k]); draw.ellipse((x-4,y-4,x+4,y+4),fill=color,outline="white",width=1)
            x,y=pt(leg["marker_position"])
            if side == "right":
                draw.ellipse((x-5,y-5,x+5,y+5),fill=color)
            else:
                for dy in (-3,3): draw.line((x-7,y+dy,x+7,y+dy),fill=color,width=3)
        draw.text((ox+12, oy+476), "RIGHT = ORANGE / BRIGHT / NEAR", fill="#c35e19")
        draw.text((ox+12, oy+493), "LEFT = BLUE / GRAY / FAR", fill="#287dc2")
    canvas.save(ART / "run_pose_control.png")
    (ART / "motion_plan.json").write_text(json.dumps(data,indent=2)+"\n",encoding="utf-8",newline="\n")


def marker_measurements(frame):
    points = {"right_orange": [], "left_blue": []}
    pixels = frame.load()
    for y in range(180, frame.height):
        for x in range(frame.width):
            r,g,b = pixels[x,y]
            if r > g+40 and g > b+15 and r > 150:
                points["right_orange"].append((x,y))
            # Measure the saturated stroke cores: pale antialias fringes can
            # connect the otherwise distinct two blue bars after resampling.
            if b > r+90 and b > g+45 and r < 100:
                points["left_blue"].append((x,y))
    result = {}
    for side, pts in points.items():
        if not pts:
            raise ValueError(f"Missing {side} mark")
        todo = set(pts)
        components = []
        while todo:
            queue = [todo.pop()]
            for x,y in queue:
                for dx in (-1,0,1):
                    for dy in (-1,0,1):
                        p = (x+dx,y+dy)
                        if p in todo:
                            todo.remove(p); queue.append(p)
            if len(queue) >= 8:
                components.append(len(queue))
        result[side] = {"x": sum(p[0] for p in pts)/len(pts),
                        "y": sum(p[1] for p in pts)/len(pts),
                        "pixels": len(pts), "components": sorted(components,reverse=True)}
    return result


def ink_bbox(frame, head=False):
    region = frame.crop((130,0,frame.width,180)) if head else frame
    mask = region.convert("L").point(lambda v: 255 if v > (200 if head else 170) else 0)
    bbox = mask.getbbox()
    if bbox is None:
        raise ValueError("Empty character")
    if head:
        return (bbox[0]+130,bbox[1],bbox[2]+130,bbox[3])
    return bbox


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def package():
    source = ART / "source/run_generated_03.png"
    with Image.open(source) as image:
        if image.width != image.height:
            raise ValueError("Expected 4x3 cells on a square sheet")
        # One whole-sheet scale only, never a different size for an individual pose.
        sheet = image.convert("RGB").resize((1536,1536),Image.Resampling.LANCZOS)
    frames = []
    records = []
    (ART / "frames").mkdir(exist_ok=True)
    background = (106,107,107)  # matched to the generated flat backdrop
    output_sheet = Image.new("RGB",(448*4,512*3),background)
    # Contact poses are registered to one floor. Airborne poses retain an
    # explicit repeating body-bob curve; no per-frame scale or joint warp.
    flight_head_tops = {2:48,3:39,4:35,5:43}
    for index in range(12):
        x,y=index%4*384,index//4*512
        frame = sheet.crop((x,y,x+384,y+512))
        bbox = ink_bbox(frame)
        head = ink_bbox(frame,head=True)
        flight = index%6 >= 2
        shift_y = flight_head_tops[index%6]-head[1] if flight else 488-bbox[3]
        # The SAME 32px padding on both sides preserves the wide sprint/cape
        # silhouettes without shrinking any individual character or pose.
        registered = Image.new("RGB",PUBLISH_CELL,background)
        registered.paste(frame,(32,shift_y))
        bounds = ink_bbox(registered)
        if bounds[0]<8 or bounds[1]<16 or bounds[2]>444 or bounds[3]>496:
            raise ValueError(f"Frame{index+1} clips its cell: {bounds}")
        marks = marker_measurements(registered)
        if len(marks["right_orange"]["components"]) != 1 or len(marks["left_blue"]["components"]) != 2:
            raise ValueError(f"Frame{index+1} has duplicated or malformed labels: {marks}")
        registered.save(ART / "frames" / f"run_{index+1:02}.png")
        output_sheet.paste(registered,(index%4*448,y))
        frames.append(registered)
        records.append({"frame":index+1,"translation_x":32,"translation_y":shift_y,"scale":1.0,
                        "bounds":bounds,"head_top":ink_bbox(registered,True)[1],
                        "flight":flight,"support":"none" if flight else
                        ("right" if index<6 else "left"),"markers":marks})
    output_sheet.save(ART / "run_sheet_12.png")
    frames[0].save(ART / "run_12.apng",format="PNG",save_all=True,
                   append_images=frames[1:],duration=50,loop=0,disposal=0,blend=0)
    strip=Image.new("RGB",(448*12,512))
    for index,frame in enumerate(frames): strip.paste(frame,(448*index,0))
    palette=strip.quantize(colors=256)
    indexed=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in frames]
    for name,duration in (("run_preview.gif",50),("run_slow.gif",150)):
        indexed[0].save(ART/name,save_all=True,append_images=indexed[1:],duration=duration,
                        loop=0,disposal=2,optimize=False)
    report={"frame_count":12,"cell_size":PUBLISH_CELL,"source_cell_size":CELL,"grid":[4,3],"fps":20,"frame_ms":50,
            "cycle_ms":600,"common_ground_bbox_bottom":488,"background":background,
            "processing":"One uniform whole-sheet resample, fixed-cell crops, integer root registration, encoding only. No joint deformation or individual scaling.",
            "scope":"Marker centers and rendered framing measured from actual artwork. Control skeleton joints are a separate guide; not claimed as exact generated-art measurements.",
            "frames":records}
    (ART / "render_audit.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8",newline="\n")
    files=sorted(p for p in ART.rglob("*") if p.is_file() and p.name not in
                 {"manifest.json","qa_report.json","prompts.json","README.md","index.html"})
    manifest={"tool":"image_gen","mode":"built-in","frame_count":12,"fps":20,
              "identity":{"right":"orange dot; bright outer/near",
                          "left":"blue double bar; dark inner/far"},
              "files":[{"file":p.relative_to(ART).as_posix(),"sha256":sha256(p)} for p in files]}
    (ART / "manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8",newline="\n")
    print(json.dumps({"frames":len(records),"cell_size":PUBLISH_CELL,
                      "contact_frames":[r["frame"] for r in records if not r["flight"]],
                      "head_tops":[r["head_top"] for r in records]}))


if __name__ == "__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("action",choices=["guide","package"])
    args=parser.parse_args()
    guide() if args.action=="guide" else package()
