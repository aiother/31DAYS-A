import json
import math
import unittest
from PIL import Image
from scripts.build_human_walk import pose, foot_at, OUT, GROUND, SPEED, STANCE


class HumanWalkTests(unittest.TestCase):
    def test_full_cycle_fixed_bones_contact_clearance_and_knee_direction(self):
        for i in range(1000):
            p=pose(i/1000)
            self.assertTrue(any(v['contact'] for v in p['limbs'].values()))
            for v in p['limbs'].values():
                for a,b,length in [(p['hip'],v['knee'],44.5),(v['knee'],v['ankle'],43.5),
                                   (p['shoulder'],v['elbow'],34),(v['elbow'],v['hand'],30),
                                   (v['heel'],v['toe'],22)]:
                    self.assertAlmostEqual(math.dist(a,b),length,places=7)
                low=max(v['heel'][1],v['toe'][1])
                self.assertLessEqual(low,GROUND+1e-8)
                if v['contact']:
                    self.assertAlmostEqual(low,GROUND)
                # Knee lies on the forward side of the hip-to-ankle chain.
                h,k,a=p['hip'],v['knee'],v['ankle']
                self.assertGreater((k[0]-h[0])*(a[1]-h[1])-(k[1]-h[1])*(a[0]-h[0]),0)

    def test_stance_pivot_is_stationary_in_world_space(self):
        for i in range(626):
            t=i/1000
            f=foot_at(t)
            world_offset=SPEED*t
            pivot=f['toe'] if f['pivot']=='toe' else f['heel']
            self.assertAlmostEqual(pivot[0]+world_offset,60 if f['pivot']=='toe' else 38)
            self.assertAlmostEqual(pivot[1],GROUND)

    def test_periodic_boundary_no_joint_jump_and_half_cycle_role_swap(self):
        for phase in (0,.5,STANCE,STANCE-.5):
            a,b=pose(phase-1e-7),pose(phase+1e-7)
            for side in ('right','left'):
                for joint in ('knee','ankle','heel','toe','elbow','hand'):
                    self.assertLess(math.dist(a['limbs'][side][joint],b['limbs'][side][joint]),.001)
        for i in range(16):
            a,b=pose(i/16),pose(i/16+.5)
            for joint in ('knee','ankle','elbow','hand'):
                self.assertLess(math.dist(a['limbs']['right'][joint],b['limbs']['left'][joint]),1e-8)
        p=pose(0)
        self.assertGreater(p['limbs']['right']['ankle'][0],0)
        self.assertLess(p['limbs']['right']['hand'][0],p['shoulder'][0])

    def test_exports_and_data_match_generator(self):
        data=json.loads((OUT/'human_walk_v2.json').read_text())
        self.assertEqual(data['layer_order'],['left','trunk','right'])
        self.assertEqual(data['poses'],json.loads(json.dumps([pose(i/16) for i in range(16)])))
        with Image.open(OUT/'human_walk_16_v2.png') as im:
            self.assertEqual(im.size,(2000,2020)); im.verify()
        with Image.open(OUT/'human_walk_v2.gif') as im:
            self.assertEqual(im.n_frames,64)
            self.assertEqual(im.info['loop'],0)
            for i in range(64):
                im.seek(i)
                self.assertEqual(im.info['duration'],20)


if __name__=='__main__':
    unittest.main()
