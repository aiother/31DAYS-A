/* Exercise the offline animation reviewer's actual controls without a browser. */
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const vm=require('node:vm');
const html=fs.readFileSync(path.join(__dirname,'../phf/walk_8_v1/index.html'),'utf8');
const js=html.match(/<script>([\s\S]*?)<\/script>/)[1];
class Element {
  constructor(){this.children=[];this.attributes={};this.checked=false;this.value='';this.textContent=''}
  append(e){this.children.push(e)}
  setAttribute(k,v){this.attributes[k]=v}
  click(){this.onclick()}
  matches(){return false}
}
const ids=['sprite','play','audit','speed','phase','timeline','previous','next'];
const elements=Object.fromEntries(ids.map(id=>[id,new Element()]));
elements.audit.checked=true; elements.speed.value='125';
let tick=null, delay=null, keydown;
vm.runInNewContext(js,{
  document:{getElementById:id=>elements[id],createElement:()=>new Element(),
    addEventListener:(name,fn)=>{if(name==='keydown')keydown=fn}},
  Image:class{},setInterval:(fn,ms)=>{tick=fn;delay=ms;return 1},clearInterval:()=>{tick=null},
});
assert.equal(elements.timeline.children.length,8);
assert.equal(elements.sprite.src,'audit_frames/walk_01.png');
assert.equal(delay,125); tick();
assert.equal(elements.sprite.src,'audit_frames/walk_02.png');
elements.play.click(); assert.equal(tick,null); assert.equal(elements.play.textContent,'播放');
elements.next.click(); assert.equal(elements.sprite.src,'audit_frames/walk_03.png');
elements.previous.click(); assert.equal(elements.sprite.src,'audit_frames/walk_02.png');
elements.audit.checked=false; elements.audit.onchange();
assert.equal(elements.sprite.src,'frames/walk_02.png');
elements.timeline.children[7].click(); assert.equal(elements.sprite.src,'frames/walk_08.png');
elements.speed.value='250';elements.play.click();assert.equal(delay,250);tick();
assert.equal(elements.sprite.src,'frames/walk_01.png');
keydown({target:new Element(),key:'ArrowRight'});
assert.equal(elements.sprite.src,'frames/walk_02.png');assert.equal(tick,null);
assert.equal(elements.timeline.children[1].attributes['aria-current'],'true');
assert.match(elements.phase.textContent,/2 \/ 8/);
assert(!/https?:\/\//.test(html),'Offline review must not depend on external services');
console.log('PASS: offline preview playback, pause, step, seek, speed, labels, keyboard and 8->1 loop.');
