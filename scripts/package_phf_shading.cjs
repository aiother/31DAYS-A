/* Selectively composite image_gen's shading edits into the user's exact sheet.
 * No colors are painted/recalculated here: edited RGB comes from image_gen.
 * Source alpha, dark linework, colored markers and all non-target pixels stay.
 */
const fs=require('node:fs');
const path=require('node:path');
const {createRequire}=require('node:module');
const {createHash}=require('node:crypto');
const modules=process.env.CODEX_NODE_MODULES || 'C:/Users/Administrator/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules';
const bundled=createRequire(path.join(modules,'__phf__.cjs'));
const {createCanvas,loadImage}=bundled('@napi-rs/canvas');
const sharp=bundled('sharp');
const ROOT=path.resolve(__dirname,'..');
const ART=path.join(ROOT,'phf/walk_shading_v2');
const areas=[
  {frame:1,points:[[165,334],[202,341],[207,344],[221,347],[256,336],
    [275,428],[331,480],[331,503],[65,503],[65,438],[105,410],[138,365]]},
  {frame:7,points:[[209,318],[234,315],[245,354],[252,485],[110,485],
    [110,381],[160,360],[179,351],[180,334],[204,334],[207,339]]},
  {frame:8,points:[[156,320],[190,329],[205,338],[214,325],[240,320],
    [281,407],[338,449],[338,483],[60,483],[60,410],[105,383],[129,349]]},
];
const isMarker=(r,g,b)=> (r>g+20&&g>b+10)||(b>r+20&&b>g+15);

(async()=>{
  const source=await loadImage(path.join(ART,'source/original.png'));
  const edit18=await loadImage(path.join(ART,'source/edit_1_8.png'));
  const edit7=await loadImage(path.join(ART,'source/edit_frame7.png'));
  if(source.width!==1536||source.height!==1024||edit18.width!==1536||edit18.height!==1024)
    throw Error('Expected the exact 1536x1024 source and edit sheet');
  // Decode the source without Canvas premultiplication: even hidden RGB and
  // semitransparent antialias pixels must remain byte-exact outside the edit.
  const decoded=await sharp(path.join(ART,'source/original.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  const original={data:decoded.data};
  const edits=createCanvas(1536,1024), ec=edits.getContext('2d');ec.drawImage(edit18,0,0);
  // image_gen returned the isolated frame at 1086x1448, the exact 3:4 ratio.
  // Register its two original boot marks; no original character pixels move.
  ec.drawImage(edit7,768-.4,512-.1,384,512);
  const revised=ec.getImageData(0,0,1536,1024);
  const mask=createCanvas(1536,1024),mc=mask.getContext('2d');mc.fillStyle='white';
  for(const area of areas){
    const index=area.frame-1,ox=index%4*384,oy=Math.floor(index/4)*512;
    mc.beginPath();area.points.forEach(([x,y],i)=>i?mc.lineTo(ox+x,oy+y):mc.moveTo(ox+x,oy+y));
    mc.closePath();mc.fill();
  }
  fs.writeFileSync(path.join(ART,'edit_mask.png'),mask.toBuffer('image/png'));
  const selected=mc.getImageData(0,0,1536,1024), counts={1:0,7:0,8:0};
  for(let p=0;p<1536*1024;p++){
    const q=p*4, s=original.data, t=revised.data;
    if(selected.data[q+3]<128||s[q+3]<180||isMarker(s[q],s[q+1],s[q+2]))continue;
    const oldGray=(s[q]+s[q+1]+s[q+2])/3,newGray=(t[q]+t[q+1]+t[q+2])/3;
    // Exclude original ink contours and any generated exterior/background ink.
    if(oldGray<115||newGray<135)continue;
    const changed=s[q]!==t[q]||s[q+1]!==t[q+1]||s[q+2]!==t[q+2];
    if(changed){
      const x=p%1536,y=Math.floor(p/1536),frame=Math.floor(y/512)*4+Math.floor(x/384)+1;
      counts[frame]++;
      s[q]=t[q];s[q+1]=t[q+1];s[q+2]=t[q+2];
    }
    // Original alpha is intentionally never assigned from generated pixels.
  }
  await sharp(original.data,{raw:{width:1536,height:1024,channels:4}}).png().toFile(path.join(ART,'walk_sheet_corrected.png'));
  fs.writeFileSync(path.join(ART,'edit_regions.json'),JSON.stringify({
    frame_size:[384,512],sheet_size:[1536,1024],edited_frames:[1,7,8],
    right:'orange dot; bright; outer',left:'blue double dash; dark; inner',
    compositing:'RGB from image_gen only; preserve original alpha, ink and marker pixels',
    changed_pixels:counts,areas},null,2)+'\n');
  const files=['source/original.png','source/edit_1_8.png','source/edit_frame7.png',
    'source/frame7_reference.png','edit_mask.png','walk_sheet_corrected.png'];
  fs.writeFileSync(path.join(ART,'manifest.json'),JSON.stringify({
    tool:'image_gen',mode:'built-in',source:'User attached sheet; no pose regeneration in final composition',
    sheet_size:[1536,1024],frame_size:[384,512],edited_frames:[1,7,8],
    identity:{right:'orange dot, bright outer leg',left:'blue double dash, dark inner leg'},
    files:files.map(file=>({file,sha256:createHash('sha256').update(fs.readFileSync(path.join(ART,file))).digest('hex')}))
  },null,2)+'\n');
  console.log(JSON.stringify({changed_pixels:counts}));
})().catch(e=>{console.error(e);process.exit(1)});
