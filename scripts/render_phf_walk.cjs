/* Animate image_gen's fixed raster parts with a rigid 2D skeleton.
 * No generative per-frame anatomy, mesh deformation or per-frame resizing.
 */
const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');
const moduleRoot = process.env.CODEX_NODE_MODULES ||
  'C:/Users/Administrator/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules';
const requireBundled = createRequire(path.join(moduleRoot, '__phf__.cjs'));
const { createCanvas, loadImage } = requireBundled('@napi-rs/canvas');
const ROOT = path.resolve(__dirname, '..');
const ART = path.join(ROOT, 'phf/walk_8_v1');
const S = 2, W = 384, H = 512;
const rad = x => x * Math.PI / 180;
const deg = x => x * 180 / Math.PI;
const add = (a,b) => [a[0]+b[0],a[1]+b[1]];
const sub = (a,b) => [a[0]-b[0],a[1]-b[1]];
const length = a => Math.hypot(...a);
const rotate = (p,a) => [p[0]*Math.cos(a)-p[1]*Math.sin(a),p[0]*Math.sin(a)+p[1]*Math.cos(a)];
const bounds = {
  1:[50,55,245,256], 2:[290,48,515,265], 3:[545,56,790,265],
  4:[850,123,1000,233], 5:[1080,119,1180,245], 6:[1288,110,1500,250],
  7:[45,282,260,536], 8:[290,326,510,468], 9:[530,333,793,540],
  10:[806,334,985,534], 11:[1060,334,1270,536], 12:[1349,356,1455,448],
  13:[70,542,254,725], 14:[301,545,511,727], 15:[594,592,723,700],
  16:[806,542,988,727], 17:[1065,565,1270,727], 18:[1330,592,1481,700],
  19:[86,742,195,939], 20:[342,745,445,962], 21:[571,819,758,966],
  22:[858,742,985,940], 23:[1081,745,1192,962], 24:[1325,820,1506,966],
};
const anchors = {
  left:{thigh:[136,773,129,929],shin:[380,785,409,930],boot:[634,863],
        heel:[601,947],toe:[744,946],parts:[19,20,21]},
  right:{thigh:[908,773,920,930],shin:[1155,785,1119,933],boot:[1393,865],
        heel:[1353,949],toe:[1490,946],parts:[22,23,24]},
};
// Each side shares one physical boot geometry for ground anchoring. Different
// source boot drawings receive a one-time uniform registration, never per-frame.
const BOOT_SCALE = .34;
const FOOT_POSES = [
  {anchor:'heel',at:[225,450],angle:-8},
  {anchor:'heel',at:[202,450],angle:.4},
  {anchor:'heel',at:[178,450],angle:.4},
  {anchor:'toe',at:[196,450],angle:25},
  {anchor:'toe',at:[172,450],angle:40},
  {anchor:'toe',at:[180,440],angle:42},
  {anchor:'toe',at:[220,428],angle:10},
  {anchor:'heel',at:[212,437],angle:-12},
];
const PHASES = ['heel_contact','load_down','support_passing','toe_support_up',
                'toe_off','early_swing','swing_passing','terminal_swing'];
const BOB = [2,5,0,-6];
const UNITS = [84,86];
const assets = {};
let atlas, head;

function normalizeAlpha(canvas) {
  // Retain solid artwork components and their antialiased edge. image_gen's
  // alpha matte can contain isolated opaque flecks in otherwise empty space.
  // RGB artwork is not repainted; only detached matte noise is discarded.
  const ctx=canvas.getContext('2d'), im=ctx.getImageData(0,0,canvas.width,canvas.height);
  const w=canvas.width,h=canvas.height,n=w*h, seen=new Uint8Array(n), keep=new Uint8Array(n);
  const components=[];
  for(let start=0;start<n;start++) {
    if(seen[start]||im.data[start*4+3]<200) continue;
    const queue=[start]; seen[start]=1;
    for(let q=0;q<queue.length;q++) {
      const p=queue[q],x=p%w,y=Math.floor(p/w);
      for(const v of [x>0?p-1:-1,x<w-1?p+1:-1,y>0?p-w:-1,y<h-1?p+w:-1])
        if(v>=0&&!seen[v]&&im.data[v*4+3]>=200) {seen[v]=1;queue.push(v);}
    }
    components.push(queue);
  }
  const largest=Math.max(...components.map(c=>c.length));
  for(const c of components) if(c.length>=Math.max(32,largest*.003)) for(const p of c) keep[p]=1;
  // Preserve a one-pixel antialiased margin around the retained components.
  const padded=keep.slice();
  for(let p=0;p<n;p++) if(keep[p]) {
    const x=p%w,y=Math.floor(p/w);
    for(let dy=-1;dy<=1;dy++) for(let dx=-1;dx<=1;dx++)
      if(x+dx>=0&&x+dx<w&&y+dy>=0&&y+dy<h) padded[p+dy*w+dx]=1;
  }
  for(let p=0;p<n;p++) if(!padded[p]) im.data[p*4+3]=0;
  ctx.putImageData(im,0,0);
  return canvas;
}

function knee(hip,ankle) {
  const [dx,dy] = sub(ankle,hip), d = Math.hypot(dx,dy);
  if (d >= 170 || d <= 2) throw Error('Unreachable foot');
  const along = (84**2-86**2+d*d)/(2*d);
  const perp = Math.sqrt(84**2-along**2);
  return [hip[0]+along*dx/d+perp*dy/d, hip[1]+along*dy/d-perp*dx/d];
}
function local(id,p) { return [p[0]-bounds[id][0],p[1]-bounds[id][1]]; }
function mapPoint(t,p) { return add(t.destination,rotate(sub(p,t.source_anchor).map(v=>v*t.scale),rad(t.rotation))); }

function soleOffset(side,angle) {
  const a=anchors[side], id=a.parts[2], c=assets[id];
  const pixels=c.getContext('2d').getImageData(0,0,c.width,c.height).data;
  let bottom=-Infinity;
  for(let y=0;y<c.height;y++) for(let x=0;x<c.width;x++) if(pixels[(y*c.width+x)*4+3]>128) {
    const point=[x+.5+bounds[id][0]-a.boot[0],y+.5+bounds[id][1]-a.boot[1]];
    bottom=Math.max(bottom,rotate(point.map(v=>v*BOOT_SCALE),rad(angle))[1]);
  }
  return bottom;
}

function render(index, audit=false) {
  const canvas = createCanvas(W*S,H*S), ctx = canvas.getContext('2d');
  ctx.scale(S,S);
  const transforms=[];
  function part(name,id,pivot,destination,rotation,scale,shade=1) {
    const image = id==='head' ? head : assets[id];
    const source = id==='head' ? pivot : local(id,pivot);
    const t={name,asset:id,source_anchor:source,destination,rotation,scale,shade,order:transforms.length};
    transforms.push(t);
    ctx.save(); ctx.translate(...destination); ctx.rotate(rad(rotation)); ctx.scale(scale,scale);
    if (shade!==1) ctx.filter=`brightness(${shade})`;
    ctx.drawImage(image,-source[0],-source[1]); ctx.restore();
    return t;
  }
  function segment(name,id,source,target,expectedLength,shade) {
    const p0=source.slice(0,2), p1=source.slice(2);
    const vector=sub(p1,p0), goal=sub(target[1],target[0]);
    return part(name,id,p0,target[0],deg(Math.atan2(goal[1],goal[0])-Math.atan2(vector[1],vector[0])),
                expectedLength/length(vector),shade);
  }
  const bob=BOB[index%4], hip=[192,260+bob], shoulder=[195,181+bob];
  const legs={};
  for(const side of ['right','left']) {
    const phase=(index+(side==='left'?0:4))%8;
    const a=anchors[side], pose=FOOT_POSES[phase];
    const bootScale=BOOT_SCALE;
    const ankle=add(pose.at,rotate(sub(a.boot,a[pose.anchor]).map(v=>v*bootScale),rad(pose.angle)));
    const sole=soleOffset(side,pose.angle);
    // Calibrate the planted boot against its real alpha silhouette rather than
    // a guessed point inside the illustrated sole. Swing boots retain clearance.
    if(phase<=4) ankle[1]=450-sole;
    legs[side]={phase_index:phase,phase:PHASES[phase],depth:side==='left'?'near':'far',
      hip,ankle,knee:knee(hip,ankle),foot_anchor:pose.anchor,contact:pose.at,
      boot_angle:pose.angle,sole_y:ankle[1]+sole,grounded:phase<=4,
      marker:side==='left'?'orange_L':'blue_R'};
  }
  const cloth=Math.sin((index-.6)*Math.PI/2)*3;
  const fullSwing=Math.cos(index*Math.PI/4);
  // Rear cape and the far arm remain behind the whole torso and both legs.
  part('cape_rear',9,[700,321],shoulder,-2+cloth,.58);
  part('cape_far',11,[1127,321],shoulder,-7-cloth*.75,.43,.96);
  function arm(side) {
    const near=side==='left';
    const angle=90+(near?1:-1)*20*fullSwing;
    const start=add(shoulder,[near?-2:6,near?3:0]);
    const end=add(start,[Math.cos(rad(angle))*76,Math.sin(rad(angle))*76]);
    const sleeve=near?13:16, hand=near?15:18;
    const source=near?[101,575,213,666]:[953,575,849,665];
    segment(side+'_sleeve',sleeve,source,[start,end],76,near?1:.90);
    // Hand is a fixed cutout rotating with the sleeve, attached at its wrist.
    const handStart=near?[626,620]:[1360,622];
    part(side+'_hand',hand,handStart,end,angle-42,.43,near?1:.90);
  }
  arm('right');
  // Far chain is ALWAYS below near chain: x position never determines depth.
  for(const side of ['right','left']) {
    const leg=legs[side], a=anchors[side], shade=side==='left'?1:.86;
    segment(side+'_shin',a.parts[1],a.shin,[leg.knee,leg.ankle],86,shade);
    segment(side+'_thigh',a.parts[0],a.thigh,[hip,leg.knee],84,shade);
    // Cuff must cover the shin attachment, as on the reference model.
    const boot=part(side+'_boot',a.parts[2],a.boot,leg.ankle,leg.boot_angle,BOOT_SCALE,shade);
    leg.marker_position=mapPoint(boot,local(a.parts[2],add(a.boot,[0,-16])));
  }
  part('shorts',8,[397,350],[192,249+bob],0,.40);
  part('tunic',7,[136,321],[194,182+bob],-.8,.43);
  arm('left');
  // The head/collar/clasp share the torso bob and are never rescaled by phase.
  // One intact head/neck/collar/clasp cutout preserves the original neckline.
  part('head_neck_collar_clasp','head',[117,174],[222,188+bob],0,.75);
  part('cape_near',10,[945,321],shoulder,1.5+cloth*.85,.59);
  if(audit) {
    ctx.font='bold 11px sans-serif';
    for(const side of ['right','left']) {
      const p=legs[side].marker_position, color=side==='left'?'#ed792e':'#217bd0';
      ctx.fillStyle=color; ctx.strokeStyle='white'; ctx.lineWidth=1.5;
      ctx.beginPath(); ctx.arc(p[0],p[1],4,0,Math.PI*2); ctx.fill(); ctx.stroke();
      const tx=p[0]+(side==='left'?10:-20), ty=p[1]-8;
      ctx.fillText(side==='left'?'L':'R',tx,ty);
    }
    ctx.fillStyle='#484848'; ctx.font='12px sans-serif';
    ctx.fillText(`${String(index+1).padStart(2,'0')}   L=NEAR   R=FAR`,18,486);
  }
  return {canvas,meta:{frame:index+1,hip,legs,transforms,support:index<4?'left':'right'}};
}

(async()=>{
  for(const dir of ['frames','audit_frames','source/parts']) fs.mkdirSync(path.join(ART,dir),{recursive:true});
  atlas=await loadImage(path.join(ART,'source/parts_atlas.png'));
  for(const [id,b] of Object.entries(bounds)) {
    const c=createCanvas(b[2]-b[0],b[3]-b[1]);
    c.getContext('2d').drawImage(atlas,...[b[0],b[1],b[2]-b[0],b[3]-b[1]],0,0,c.width,c.height);
    assets[id]=normalizeAlpha(c);
    fs.writeFileSync(path.join(ART,'source/parts',`${id.padStart(2,'0')}.png`),c.toBuffer('image/png'));
  }
  const source=await loadImage(path.join(ART,'source/head_source.png'));
  head=createCanvas(175,195);
  const hc=head.getContext('2d');
  // Polygon extraction follows the collar and clasp instead of retaining a
  // rectangular strip of the original cape below the neckline.
  hc.beginPath(); hc.moveTo(0,0); hc.lineTo(175,0); hc.lineTo(175,168);
  hc.lineTo(134,168); hc.lineTo(130,176); hc.lineTo(117,187); hc.lineTo(104,176);
  hc.lineTo(104,168); hc.lineTo(0,168); hc.closePath(); hc.clip();
  hc.drawImage(source,132,10,175,195,0,0,175,195);
  normalizeAlpha(head);
  fs.writeFileSync(path.join(ART,'source/head.png'),head.toBuffer('image/png'));
  const sheet=createCanvas(W*S*4,H*S*2), auditSheet=createCanvas(W*S*4,H*S*2);
  const frames=[];
  for(let index=0;index<8;index++) {
    const clean=render(index), audit=render(index,true);
    const filename=`walk_${String(index+1).padStart(2,'0')}.png`;
    fs.writeFileSync(path.join(ART,'frames',filename),clean.canvas.toBuffer('image/png'));
    fs.writeFileSync(path.join(ART,'audit_frames',filename),audit.canvas.toBuffer('image/png'));
    sheet.getContext('2d').drawImage(clean.canvas,index%4*W*S,Math.floor(index/4)*H*S);
    auditSheet.getContext('2d').drawImage(audit.canvas,index%4*W*S,Math.floor(index/4)*H*S);
    frames.push(clean.meta);
  }
  fs.writeFileSync(path.join(ART,'walk_sheet.png'),sheet.toBuffer('image/png'));
  fs.writeFileSync(path.join(ART,'walk_leg_audit.png'),auditSheet.toBuffer('image/png'));
  fs.writeFileSync(path.join(ART,'rig.json'),JSON.stringify({frame_count:8,cell_size:[W*S,H*S],
    logical_cell_size:[W,H],render_scale:S,fps:8,grid:[4,2],bone_lengths:UNITS,
    animation_method:'Rigid cutout skeleton; image_gen raster parts; fixed per-part scale.',
    left:'near, always above right',right:'far, always behind left',frames},null,2)+'\n');
  console.log('Rendered 8 rigid-part frames, clean and labeled sheets.');
})().catch(e=>{console.error(e);process.exit(1);});
