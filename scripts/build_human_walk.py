"""Side-orthographic, fixed-bone walk reference with world-space foot pivots."""
import json
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parents[1] / 'codexandclaude/tasks/ART-001/references'
GROUND, STANCE, SPEED, FOOT = 220., .625, 121.6, 22.
PAPER, INK, NEAR, FAR = '#f8f2e7', '#2b2420', '#233e62', '#9585a6'


def smooth(t):
    return t*t*(3-2*t)


def solve(a, b, l1, l2):
    dx, dy = b[0]-a[0], b[1]-a[1]
    dist = math.hypot(dx, dy)
    if not abs(l1-l2) < dist < l1+l2:
        raise ValueError(('Unreachable IK', a, b, dist))
    along = (l1*l1-l2*l2+dist*dist)/(2*dist)
    height = math.sqrt(l1*l1-along*along)
    return (a[0]+(along*dx+height*dy)/dist,
            a[1]+(along*dy-height*dx)/dist)


def foot_at(t):
    def stance_at(u):
        angle = (-.25*(1-smooth(u/.16)) if u < .16 else
                 .65*smooth((u-.65)/.35) if u > .65 else 0.)
        anchor = 38-SPEED*STANCE*u
        # Heel pivot initially, then flat sole, then fixed toe pivot.
        heel = ((anchor, GROUND) if angle <= 0 else
                (anchor+FOOT-FOOT*math.cos(angle), GROUND-FOOT*math.sin(angle)))
        return heel, angle
    if t <= STANCE:
        heel, angle = stance_at(t/STANCE)
    else:
        u = (t-STANCE)/(1-STANCE)
        start, a0 = stance_at(1)
        end, a1 = stance_at(0)
        # Hermite horizontal motion matches backward stance velocity at both ends.
        tangent = -SPEED*(1-STANCE)
        x = ((2*u**3-3*u*u+1)*start[0] + (u**3-2*u*u+u)*tangent
             + (-2*u**3+3*u*u)*end[0] + (u**3-u*u)*tangent)
        angle = a0+(a1-a0)*smooth(u)
        lift = 19*math.sin(math.pi*u)**2
        heel = (x, GROUND-max(0, FOOT*math.sin(angle))-lift)
    c, s = math.cos(angle), math.sin(angle)
    toe = (heel[0]+FOOT*c, heel[1]+FOOT*s)
    ankle = (heel[0]+5*c+7*s, heel[1]+5*s-7*c)
    return dict(heel=heel, toe=toe, ankle=ankle, contact=t <= STANCE,
                pivot='heel' if angle < 0 else 'toe' if angle > 0 else 'sole')


def pose(phase):
    phase %= 1
    # Two vertical oscillations: loading low, passing/high-support high.
    hip = (0., 134+4*math.cos(4*math.pi*(phase-.09)))
    shoulder = (4., hip[1]-64)
    result = dict(phase=phase, hip=hip, shoulder=shoulder,
                  head=(5., shoulder[1]-31), limbs={})
    for side, offset in [('right', 0.), ('left', .5)]:
        t = (phase+offset)%1
        foot = foot_at(t)
        knee = solve(hip, foot['ankle'], 44.5, 43.5)
        # Ipsilateral arm counters its leg: right leg forward -> right arm back.
        angle = -.60*math.cos(2*math.pi*t)
        elbow = (shoulder[0]+34*math.sin(angle), shoulder[1]+34*math.cos(angle))
        flex = .30+.15*(.5+.5*math.sin(2*math.pi*t))
        hand = (elbow[0]+30*math.sin(angle+flex), elbow[1]+30*math.cos(angle+flex))
        result['limbs'][side] = dict(**foot, knee=knee, elbow=elbow, hand=hand)
    return result


def font(n, bold=False):
    return ImageFont.truetype('C:/Windows/Fonts/msyh'+('bd' if bold else '')+'.ttc', n)


def draw_pose(d, p, ox, oy, scale, grid=False):
    def xy(v):
        return (ox+scale*v[0], oy+scale*v[1])
    def line(points, color, width, halo=False):
        pts = [xy(v) for v in points]
        if halo:
            d.line(pts, fill=PAPER, width=round((width+4)*scale), joint='curve')
        d.line(pts, fill=color, width=round(width*scale), joint='curve')
    def joint(v, color, r=2.7):
        x,y=xy(v); r*=scale
        d.ellipse((x-r,y-r,x+r,y+r), fill=PAPER, outline=color, width=max(2,round(scale)))
    d.line([xy((-68,GROUND)),xy((75,GROUND))], fill='#cdbfa9', width=2)
    if grid:
        for x in range(-300,301,20):
            gx=x-SPEED*p['phase']
            if -100 < gx < 100:
                d.line([xy((gx,GROUND+3)),xy((gx,GROUND+7))], fill='#cdbfa9', width=2)
    # Depth never changes when the legs cross: far arm/leg, trunk, near arm/leg.
    for side, color in [('left',FAR),('right',NEAR)]:
        limb=p['limbs'][side]
        if side == 'right':
            line([p['hip'],p['shoulder']],INK,4,True)
            hx,hy=xy(p['head']); rx,ry=14*scale,18*scale
            d.ellipse((hx-rx,hy-ry,hx+rx,hy+ry),fill=PAPER,outline=INK,width=round(2*scale))
            line([(p['head'][0]+13,p['head'][1]-4),
                  (p['head'][0]+19,p['head'][1]+1),
                  (p['head'][0]+13,p['head'][1]+3)],INK,2)
            line([(p['head'][0],p['head'][1]+18),p['shoulder']],INK,3)
        line([p['hip'],limb['knee'],limb['ankle']],color,4,side=='right')
        line([limb['ankle'],limb['heel'],limb['toe']],color,3,side=='right')
        line([p['shoulder'],limb['elbow'],limb['hand']],color,3,side=='right')
        for v in [p['hip'],limb['knee'],limb['ankle'],p['shoulder'],limb['elbow'],limb['hand']]:
            joint(v,color)
        hx,hy=xy(limb['heel'])
        d.text((hx-10*scale,hy+9*scale), 'R' if side=='right' else 'L',font=font(round(9*scale)),fill=color)
        if limb['contact']:
            v=limb['toe'] if limb['pivot']=='toe' else limb['heel']
            x,y=xy(v)
            d.line((x-4*scale,y+2,x+4*scale,y+2),fill='#c38c37',width=3)


def build():
    poses=[pose(i/16) for i in range(16)]
    sheet=Image.new('RGB',(2000,2020),PAPER); d=ImageDraw.Draw(sheet)
    d.text((60,26),'人体步行 · 大跨步 16 关键帧',font=font(48,True),fill=INK)
    d.text((60,96),'严格侧视 / 朝右   深蓝 R = 右侧近腿   灰紫 L = 左侧远腿   近侧始终遮挡远侧',font=font(25),fill=INK)
    titles=['右脚接触','右腿承重','左脚蹬离','左腿前摆','前摆过渡','摆腿经过','左腿伸出','准备换步',
            '左脚接触','左腿承重','右脚蹬离','右腿前摆','前摆过渡','摆腿经过','右腿伸出','准备换步']
    for i,p in enumerate(poses):
        x=30+(i%4)*490; y=160+(i//4)*440
        d.rounded_rectangle((x,y,x+475,y+425),radius=14,outline='#ded2c1',width=2)
        d.text((x+18,y+12),f'{i+1:02}  {titles[i]}',font=font(25,True),fill=INK)
        draw_pose(d,p,x+225,y+15,1.5)
        contacts=sum(v['contact'] for v in p['limbs'].values())
        d.text((x+160,y+389),'双支撑交接' if contacts==2 else '单腿支撑',font=font(19),fill=INK)
    d.text((50,1940),'01 → 16 → 01  /  对侧摆臂 · 足底滚动 · 无腾空 · 固定骨长 · 接地枢轴锁定',font=font(25),fill=INK)
    d.text((50,1980),'人体结构动作参考；不是医学测量数据。角色比例、步频与移动速度需在游戏中适配。',font=font(21),fill='#73685b')
    sheet.save(OUT/'human_walk_16_v2.png')
    frames=[]
    for i in range(64):
        p=pose(i/64)
        im=Image.new('RGB',(640,640),PAPER); dr=ImageDraw.Draw(im)
        dr.text((30,20),'大跨步 · 人体步行',font=font(30,True),fill=INK)
        draw_pose(dr,p,315,40,2.15,True)
        dr.text((40,580),'R 右近侧   L 左远侧   01 → 16 → 01',font=font(23),fill=INK)
        frames.append(im)
    frames[0].save(OUT/'human_walk_v2.gif',save_all=True,append_images=frames[1:],duration=20,loop=0,disposal=2)
    (OUT/'human_walk_v2.json').write_text(json.dumps(dict(cycle_seconds=1.28,
        root_displacement=SPEED,projection='orthographic side, facing right',
        layer_order=['left','trunk','right'],poses=poses),indent=2),encoding='utf-8')


if __name__=='__main__':
    build()
