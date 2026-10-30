"""Validate the sprint control skeleton, actual exported frames and loop encoding."""
import hashlib
import json
import math
import subprocess
import unittest
from pathlib import Path

from PIL import Image, ImageStat

ART = Path(__file__).resolve().parents[1] / "phf/run_12_v1"


class PhfRun12Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.control = json.loads((ART / "motion_plan.json").read_text(encoding="utf-8"))
        cls.audit = json.loads((ART / "render_audit.json").read_text(encoding="utf-8"))
        cls.frames = []
        for i in range(12):
            with Image.open(ART / "frames" / f"run_{i+1:02}.png") as image:
                cls.frames.append(image.convert("RGB"))

    def test_fixed_control_bone_lengths_and_forward_knees(self):
        for frame in self.control["frames"]:
            for leg in frame["legs"].values():
                hip, knee, ankle = [leg[k] for k in ("hip", "knee", "ankle")]
                self.assertAlmostEqual(math.dist(hip, knee), 84, places=8)
                self.assertAlmostEqual(math.dist(knee, ankle), 86, places=8)
                cross=(ankle[0]-hip[0])*(knee[1]-hip[1])-(ankle[1]-hip[1])*(knee[0]-hip[0])
                self.assertLess(cross, 0)

    def test_control_leg_identities_complete_twelve_phases(self):
        for i, frame in enumerate(self.control["frames"]):
            self.assertEqual(frame["legs"]["right"]["phase_index"], i)
            self.assertEqual(frame["legs"]["left"]["phase_index"], (i+6)%12)
            self.assertEqual(frame["legs"]["right"]["depth"], "near")
            self.assertEqual(frame["legs"]["left"]["depth"], "far")
            self.assertEqual(frame["legs"]["right"]["marker"], "orange_dot")
            self.assertEqual(frame["legs"]["left"]["marker"], "blue_double_bar")

    def test_control_has_push_off_and_real_airborne_phases(self):
        for i, frame in enumerate(self.control["frames"]):
            self.assertEqual(frame["flight"], i%6 >= 2)
            for leg in frame["legs"].values():
                sole=max(leg["heel"][1],leg["toe"][1])
                if leg["grounded"]:
                    self.assertAlmostEqual(sole, 450)
                else:
                    self.assertLess(sole, 450)

    def test_twelve_unique_equal_size_frames_no_clipping(self):
        self.assertEqual(len(self.frames), 12)
        self.assertEqual(len({f.tobytes() for f in self.frames}), 12)
        for image, record in zip(self.frames,self.audit["frames"]):
            self.assertEqual(image.size, (448,512))
            bbox=image.convert("L").point(lambda v:255 if v>170 else 0).getbbox()
            self.assertEqual(list(bbox), record["bounds"])
            self.assertGreaterEqual(bbox[0], 8)
            self.assertGreaterEqual(bbox[1], 24)
            self.assertLessEqual(bbox[2], 440)
            self.assertLessEqual(bbox[3], 488)

    def test_actual_boot_marks_are_one_orange_dot_and_two_blue_bars(self):
        for image, record in zip(self.frames,self.audit["frames"]):
            for side, count in (("right_orange",1),("left_blue",2)):
                mark=record["markers"][side]
                self.assertEqual(len(mark["components"]),count)
                self.assertGreater(mark["pixels"],80)
                x,y=round(mark["x"]),round(mark["y"])
                pixels=image.crop((x-15,y-15,x+16,y+16)).get_flattened_data()
                if side=="right_orange":
                    n=sum(r>g+40 and g>b+15 for r,g,b in pixels)
                else:
                    n=sum(b>r+90 and b>g+45 and r<100 for r,g,b in pixels)
                self.assertGreater(n,80)

    def test_leg_tracks_keep_anatomical_identity_at_opposite_contacts(self):
        records=self.audit["frames"]
        for index,front in ((0,"right_orange"),(2,"left_blue"),(3,"left_blue"),
                            (6,"left_blue"),(8,"right_orange"),(9,"right_orange")):
            other="left_blue" if front=="right_orange" else "right_orange"
            self.assertGreater(records[index]["markers"][front]["x"]-
                               records[index]["markers"][other]["x"],120)

    def test_contact_floor_and_flight_clearance_are_measured_from_real_pixels(self):
        for i, record in enumerate(self.audit["frames"]):
            if i%6<2:
                self.assertFalse(record["flight"])
                self.assertEqual(record["bounds"][3],488)
                self.assertEqual(record["support"],"right" if i<6 else "left")
            else:
                self.assertTrue(record["flight"])
                self.assertLess(record["bounds"][3],480)

    def test_common_camera_scale_padding_and_body_bob(self):
        self.assertEqual({r["scale"] for r in self.audit["frames"]},{1.0})
        self.assertEqual({r["translation_x"] for r in self.audit["frames"]},{32})
        tops=[r["head_top"] for r in self.audit["frames"]]
        for a,b in zip(tops,tops[1:]+tops[:1]):
            self.assertLessEqual(abs(a-b),20)
        for i in range(6):
            self.assertLessEqual(abs(tops[i]-tops[i+6]),4)

    def test_twelve_to_one_marker_positions_continue_without_id_swap(self):
        a,b=self.audit["frames"][-1],self.audit["frames"][0]
        for side in ("right_orange","left_blue"):
            p,q=a["markers"][side],b["markers"][side]
            self.assertLess(math.hypot(p["x"]-q["x"],p["y"]-q["y"]),75)

    def test_sheet_is_pixel_exact_four_by_three_pack(self):
        with Image.open(ART / "run_sheet_12.png") as sheet:
            self.assertEqual(sheet.size,(1792,1536))
            for i,frame in enumerate(self.frames):
                x,y=i%4*448,i//4*512
                self.assertEqual(sheet.crop((x,y,x+448,y+512)).tobytes(),frame.tobytes())

    def test_apng_is_lossless_twelve_frames_twenty_fps(self):
        with Image.open(ART / "run_12.apng") as image:
            self.assertEqual(image.n_frames,12)
            self.assertEqual(image.info["loop"],0)
            for i,frame in enumerate(self.frames):
                image.seek(i)
                self.assertEqual(image.info["duration"],50)
                self.assertEqual(image.convert("RGB").tobytes(),frame.tobytes())

    def test_gif_frame_count_timing_and_loop(self):
        for filename,duration in (("run_preview.gif",50),("run_slow.gif",150)):
            with Image.open(ART / filename) as image:
                self.assertEqual(image.n_frames,12)
                self.assertEqual(image.size,(448,512))
                self.assertEqual(image.info["loop"],0)
                for i in range(12):
                    image.seek(i)
                    self.assertEqual(image.info["duration"],duration)

    def test_gray_background_has_no_light_halos(self):
        for frame in self.frames:
            stat=ImageStat.Stat(frame.crop((0,0,448,24)))
            self.assertLess(max(stat.stddev),3)
            self.assertTrue(all(100 < m < 113 for m in stat.mean))

    def test_saved_sources_and_outputs_match_manifest(self):
        manifest=json.loads((ART / "manifest.json").read_text(encoding="utf-8"))
        self.assertEqual(manifest["identity"]["right"],"orange dot; bright outer/near")
        self.assertEqual(manifest["identity"]["left"],"blue double bar; dark inner/far")
        for item in manifest["files"]:
            self.assertEqual(hashlib.sha256((ART/item["file"]).read_bytes()).hexdigest(),item["sha256"])
        text_paths=["phf/run_12_v1/"+item["file"] for item in manifest["files"]
                    if Path(item["file"]).suffix==".json" or item["file"]==".gitattributes"]
        attrs=subprocess.run(["git","check-attr","-z","eol","--",*text_paths],
                             cwd=ART.parents[1],capture_output=True,check=True)
        fields=attrs.stdout.decode("utf-8").split("\0")[:-1]
        self.assertTrue(all(fields[i+2]=="lf" for i in range(0,len(fields),3)))


if __name__ == "__main__":
    unittest.main()
