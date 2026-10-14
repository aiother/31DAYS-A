import fs from 'node:fs/promises';
import { createRequire } from 'node:module';
import { pathToFileURL, fileURLToPath } from 'node:url';
const runtime = 'C:/Users/Administrator/.cache/codex-runtimes/codex-primary-runtime/dependencies/node';
const require = createRequire(`${runtime}/package.json`);
const { Workbook, SpreadsheetFile } = await import(pathToFileURL(require.resolve('@oai/artifact-tool')).href);

const specs = [
  ['T6-A 实体资源', ['资源类别','资源名称','已确定配置','制作等级 A/B/C','你的填写：制作形式与复用方案'], [
    ['玩家','玩家角色','1名'],['玩家武器','初始武器','至少1套'],['主要NPC','泥粪中的理想家（7）','1名'],
    ['主要NPC','镰刀与锤的抗争者（10）','1名，参与实际战斗'],['基础NPC','幸存者','包含救助、对话'],
    ['基础NPC','濒死战士/幸存者战士','包含救助、战斗'],['普通敌人','无色实体','地面/空中表现'],
    ['普通敌人','单色实体','高机动敌人'],['普通敌人','天人战士','近战、远程、协同战斗'],
    ['Boss','渴望俯视','T5已配置'],['Boss','寄生同伴者','T5已配置'],['资源实体','可能性','获取、消耗、恢复'],
    ['固定奖励','Boss及剧情奖励','无随机战利品系统'],['场景物件','检查点','8个逻辑节点'],
    ['场景物件','门、路障、机关','依据T5配置'],['交互物件','救助目标、拾取目标','依据T5配置']], [4,5], 4],
  ['T6-B1 玩家动画', ['动作组','已确定的动作需求','独立动画数量','复用方式 / 你的填写'], [
    ['待机','普通待机'],['基础移动','行走、跑步'],['转向','地面转向'],['跳跃','起跳、上升、最高点、下落'],
    ['落地','普通落地'],['特殊落地','高空落地、硬直'],['墙体互动','V0.1不制作',0,'已排除'],
    ['普通攻击','第一段、第二段'],['左右攻击','左右方向攻击'],['向上攻击','向上打击'],
    ['向下攻击','空中向下攻击、命中反弹'],['空中攻击','空中普通攻击'],['闪避','左右滑步'],
    ['受击','普通受击硬直'],['死亡','倒地、死亡表现'],['恢复','持续2.8秒的恢复动作'],
    ['互动','NPC互动'],['拾取','关键物品拾取'],['复活','复活表现']], [3,4]],
  ['T6-B2 NPC敌人动画', ['对象','最低动作需求','独立动画数量','复用方式 / 你的填写'], [
    ['7 泥粪中的理想家','待机、劳作、对话、恢复教学'],['10 镰刀与锤的抗争者','待机、移动、攻击、救场、对话'],
    ['普通幸存者','待机、受伤、获救、互动'],['幸存者战士','移动、攻击、受击、死亡'],
    ['无色实体','移动、近战、远程、受击、死亡'],['单色实体','移动、冲刺、闪避、攻击、受击、死亡'],
    ['天人战士','移动、连击、重击、远程、格挡、受击、死亡'],['渴望俯视','登场、移动、攻击、受击、死亡'],
    ['寄生同伴者','登场、移动、投射、吸血、受击、死亡']], [3,4]],
  ['T6-C 地图环境', ['资源类别','当前制作需求','制作等级 A/B/C','你的填写：资源形式与复用方案'], [
    ['荒地环境','无顶深谷、瓦砾塔、荒地巢都等'],['田野环境','黄金麦湖、麦秆镇'],['逆时战场环境','战场外围、堑壕、中心战场'],
    ['基础地形','地面、平台、墙体、斜坡、高低差'],['场景背景','近景、中景、远景'],['场景装饰','建筑、瓦砾、植物、残骸、杂物'],
    ['场景障碍','路障、可破坏环境、陷阱'],['Connection表现','普通通路、Boss锁、事件路障'],['Boss场景','渴望俯视、寄生同伴者战斗空间'],
    ['时间变化','三天内环境状态的可见变化'],['战场背景','远景友军与敌军战斗表现'],['检查点外观','8个检查点的视觉表现'],
    ['特殊空间','已冻结的隐藏区域与特殊地形']], [3,4],3],
  ['T6-D1 视觉特效', ['类型','资源需求','制作等级 A/B/C','你的填写：表现形式与复用方案'], [
    ['普通攻击特效','武器攻击、命中、击退'],['特殊攻击特效','向上打击、空中下攻击反弹'],['投射物反馈','可反弹投掷物、命中与反弹'],
    ['闪避特效','滑步、短暂无敌'],['可能性特效','获取、消耗、补充'],['生命恢复特效','持续恢复、成功、被打断'],
    ['玩家受击','受伤、低生命、死亡'],['玩家复活','检查点复活反馈'],['普通敌人死亡','爆体/消散、有限尸体残留'],
    ['Boss死亡','Boss专属死亡反馈'],['战场增援','敌方与友方进入战场'],['时间变化','日期推进、最终15分钟倒计时']], [3,4],3],
  ['T6-D2 音效音乐', ['类型','最低需求','制作等级 A/B/C','你的填写：制作方式与复用方案'], [
    ['移动音效','移动、跳跃、落地'],['战斗音效','攻击、命中、格挡、反弹'],['受击音效','玩家和敌人受击'],
    ['死亡音效','玩家、普通敌人、Boss死亡'],['可能性音效','获取、消耗、恢复'],['交互音效','对话、拾取、机关'],
    ['荒地环境音','荒芜、危险的环境氛围'],['田野环境音','相对平静的环境氛围'],['逆时战场环境音','大规模战争氛围'],
    ['探索音乐','V0.1探索场景'],['战斗音乐','普通战斗'],['大型战斗音乐','Boss或逆时战场'],['剧情音乐','7、10等关键叙事']], [3,4],3],
  ['T6-D3 剧情演出', ['演出','已确定内容','表现形式（实时演出/过场动画/混合）','制作等级 A/B/C','你的填写'], [
    ['开场演出','玩家高空坠落'],['首次敌人遭遇','无色实体、天人战士介绍'],['渴望俯视登场','Boss首次出现'],
    ['寄生同伴者登场','Boss首次出现'],['7首次相遇','黄金麦田中的相遇'],['7任务完成','注视效果获得'],
    ['10特殊救场','暂停时间、击败威胁敌人'],['战场增援','幸存者战士加入战斗'],['最终战胜利','战斗结束与10对话'],
    ['V0.1结束','试玩完成反馈与结束菜单']], [3,4,5],4],
  ['T6-E 制作原则', ['项目','需要确定的规则','你的填写'], [
    ['角色制作方式','2D逐帧、骨骼动画、3D或混合等'],['角色比例规范','玩家、NPC、敌人的视觉比例如何统一'],
    ['左右动作复用','哪些动作允许镜像'],['动画复用','哪些角色可以共用动作结构'],['敌人外观复用','哪些敌人可以通过变体制作'],
    ['Boss资源复用','两个Boss是否需要独立形象与AI'],['场景资源复用','不同Room如何共用地形与装饰'],
    ['特效复用','同类命中、击退、死亡等是否共用'],['音效复用','同类行为是否可以共用音效'],
    ['过场演出形式','实时演出与独立动画如何选择'],['临时占位标准','哪些资源允许先用临时版本'],
    ['V0.1最终质量要求','哪些内容必须达到正式美术品质']], [3]],
  ['T6-F 最终验收', ['验收项目','通过标准','当前状态','你的填写/备注'], [
    ['玩家资源完整','T1所有操作都有对应资源方案'],['敌人资源完整','三类敌人可实现T2战斗要求'],['Boss资源完整','两个Boss可按最低制作规模实现'],
    ['主要NPC完整','7、10能够执行既定剧情与功能'],['基础NPC完整','幸存者、战士满足救助与战斗要求'],
    ['地图资源完整','三个Region及其必要Room可制作'],['Node资源完整','27个关键Node有对应资源支持'],
    ['动画需求完整','各角色动作均有独立或复用方案'],['特效反馈完整','资源、攻击、受击、死亡可清楚识别'],
    ['音效需求完整','基础动作与场景均有音效方案'],['剧情演出完整','7、10及Boss等关键事件可以表现'],
    ['3天时间表现','日期变化及战场倒计时可以表现'],['资源复用明确','所有制作内容完成A/B/C分类'],
    ['无范围扩张','没有引入新玩法或额外系统']].map(r=>[...r,'待验收',null]), [3,4]]
];

const wb = Workbook.create();
const out = fileURLToPath(new URL('../Words/T6_资源配置填写模板.xlsx',import.meta.url));
const previewDir = process.env.T6_PREVIEW_DIR;
const col = n=>String.fromCharCode(64+n);
function layout(name, headers, rows, inputs, gradeCol, start=5) {
  const sh=wb.worksheets.add(name); const n=headers.length, end=start+rows.length;
  const grid=sh.getRange(`A1:${col(n)}${end}`);
  grid.format.font={name:'Arial',size:11,color:'#17202A'};
  grid.format.verticalAlignment='center'; grid.format.wrapText=true;
  grid.format.rowHeight=44; sh.showGridLines=false;
  sh.getRange('A2').values=[[name]]; sh.getRange('A2').format.font={name:'Arial',size:15,bold:true,color:'#000000'};
  sh.getRange('A3').values=[[name.startsWith('T6-F')?'A～E填写完成后共同验收；当前保持待验收。':'浅黄色为待填写栏目；既定需求无需重新设计。']];
  sh.getRange(`A1:${col(n)}1`).format.rowHeight=12;
  sh.getRange(`A2:${col(n)}2`).format.rowHeight=30;
  sh.getRange(`A3:${col(n)}3`).format.rowHeight=26;
  sh.getRange(`A4:${col(n)}4`).format.rowHeight=12;
  sh.getRange('A2:A3').format.wrapText=false;
  sh.getRange(`A${start}:${col(n)}${start}`).values=[headers];
  sh.getRange(`A${start}:${col(n)}${start}`).format={fill:'#26384C',font:{name:'Arial',size:11,bold:true,color:'#FFFFFF'},wrapText:true,verticalAlignment:'center',rowHeight:48};
  sh.getRange(`A${start+1}:${col(n)}${end}`).values=rows.map(r=>Array.from({length:n},(_,i)=>r[i]??null));
  for(let c=1;c<=n;c++) sh.getRange(`${col(c)}1:${col(c)}${end}`).format.columnWidth=[26,48,28,48,52][c-1];
  // Input text columns stay wide enough for reuse plans; grades and quantities are compact.
  for(const c of inputs) sh.getRange(`${col(c)}${start+1}:${col(c)}${end}`).format.fill='#FFF2CC';
  if(gradeCol) {
    const rg=sh.getRange(`${col(gradeCol)}${start+1}:${col(gradeCol)}${end}`);
    rg.format.columnWidth=21; rg.dataValidation={rule:{type:'list',values:['A','B','C']}};
  }
  if(name.startsWith('T6-B')) {sh.getRange(`C${start+1}:C${end}`).format.columnWidth=19;sh.getRange(`C${start+1}:C${end}`).setNumberFormat('0');}
  sh.freezePanes.freezeRows(start);
  return sh;
}

const infoRows=[
 ['填写范围','仅完成T6-A、B、C、D、E中的空白栏目。'],
 ['待定数量','暂不确定的数量可填写“待制作测试确认”；尽量明确独立制作、复用制作或临时占位。'],
 ['已冻结功能','普通敌人AI、Boss战斗规则、Node触发条件、可能性数值、时间推进规则不在本阶段重新设计。'],
 ['本轮完成标准','明确V0.1全部待制作资源，判断哪些可开始生产、哪些可在灰盒阶段占位。'],
 ['阶段边界','本阶段只确定资源制作方向，不涉及引擎和技术实现细节；技术方案留给T8。'],
 ['后续顺序','T6资源配置 → T7 UI与存档 → T8技术基线 → 正式开发。'],
 ['验收时间','T6-F不用现在填写，A～E完成后共同验收。'],
 ['来源','用户在本聊天提供的T6-A～F待填写内容，2026-10-14。'],
 ['A：独立制作','必须具有独立形象、动作或表现的核心资源；单独制作，不以普通复用素材替代核心特征。'],
 ['B：复用制作','可使用已有资源换色、镜像、组合或适配；优先复用，降低制作量。'],
 ['C：临时占位','当前只需验证功能，无需最终表现质量；允许灰盒、简单动画或临时素材。']
];
const info=layout('填写说明',['项目','说明'],infoRows,[]);
info.getRange('A3').values=[['先填写A～E；F留待共同验收。']];
info.getRange('B1:B16').format.columnWidth=92;
info.getRange('A6:B16').format.rowHeight=58;
for(const [name,headers,rows,inputs,grade] of specs) {
  const sh=layout(name,headers,rows,inputs,grade);
  if(name.startsWith('T6-B1')) sh.getRange('C12:D12').format.fill='#E9EDF2';
  if(name.startsWith('T6-D3')) sh.getRange('C6:C15').dataValidation={rule:{type:'list',values:['实时演出','过场动画','混合']}};
  if(name.startsWith('T6-F')) sh.getRange('C6:C19').dataValidation={rule:{type:'list',values:['待验收','通过','需补充']}};
  if(name.startsWith('T6-E')) {
    const r=20;
    sh.getRange(`A${r}:C${r}`).values=[['等级','定义','实施原则']];
    sh.getRange(`A${r}:C${r}`).format={fill:'#26384C',font:{name:'Arial',size:11,bold:true,color:'#FFFFFF'},wrapText:true,rowHeight:36};
    sh.getRange(`A${r+1}:C${r+3}`).values=[
      ['A：独立制作','必须具有独立形象、动作或表现的核心资源','单独制作，不以普通复用素材替代核心特征'],
      ['B：复用制作','可以使用已有资源进行换色、镜像、组合或适配','优先复用，降低制作量'],
      ['C：临时占位','当前只需验证功能，不需要最终表现质量','允许使用灰盒、简单动画或临时素材']];
    sh.getRange('A21:C23').format={font:{name:'Arial',size:11,color:'#17202A'},wrapText:true,rowHeight:68};
  }
}
wb.recalculate();
console.log((await wb.inspect({kind:'sheet',include:'id,name',maxChars:1800})).ndjson);
await (await SpreadsheetFile.exportXlsx(wb)).save(out);
await fs.unlink(`${out}.inspect.ndjson`).catch(e=>{if(e.code!=='ENOENT')throw e;});
if(previewDir) {
  await fs.mkdir(previewDir,{recursive:true});
  for(const name of ['填写说明',...specs.map(s=>s[0])]) {
    const cols=name==='填写说明'?2:specs.find(s=>s[0]===name)[1].length;
    const lastRow=name==='填写说明'?16:name.startsWith('T6-E')?23:5+specs.find(s=>s[0]===name)[2].length;
    const preview=await wb.render({sheetName:name,range:`A1:${col(cols)}${lastRow}`,scale:1,format:'png'});
    await fs.writeFile(`${previewDir}/${name}.png`,new Uint8Array(await preview.arrayBuffer()));
  }
}
console.log(`Saved ${out}; ${specs.reduce((n,s)=>n+s[2].length,0)} fill/acceptance rows.`);
