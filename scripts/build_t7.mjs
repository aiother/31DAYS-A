import fs from 'node:fs/promises';
import { createRequire } from 'node:module';
import { fileURLToPath, pathToFileURL } from 'node:url';
const runtime='C:/Users/Administrator/.cache/codex-runtimes/codex-primary-runtime/dependencies/node';
const require=createRequire(`${runtime}/package.json`);
const {Workbook,SpreadsheetFile}=await import(pathToFileURL(require.resolve('@oai/artifact-tool')).href);

const specs=[
 ['T7-A 界面导航',['界面','已知功能与约束','需要确定的内容','你的填写'],[
  ['游戏主界面','游戏启动时出现','背景表现、标题位置、菜单项目及排布'],
  ['开始游戏','进入V0.1开场','是否需要新游戏确认界面'],
  ['继续游戏','与存档系统关联','是否直接读取最近存档、无存档时如何显示'],
  ['游戏HUD','显示生命、可能性、时间','整体布局、常驻内容、信息优先级'],
  ['暂停菜单','T4已确定菜单暂停游戏时间','菜单包含哪些选项、如何返回游戏'],
  ['设置界面','基础游戏设置','需要开放哪些设置项'],
  ['NPC对话界面','7、10及基础NPC使用','文字框、角色名、对话推进方式'],
  ['场景交互提示','门、机关、NPC等','何时显示、放在什么位置'],
  ['死亡界面','玩家死亡后进入死亡处理流程','视觉表现、交互选项'],
  ['V0.1结束界面','最终战胜利后显示','标题、结算信息、返回主菜单方式'],
  ['超时失败反馈','T4已存在失败分支','与死亡界面共用还是单独呈现']],4],
 ['T7-B HUD信息',['大类','显示内容','已冻结规则','需要确定的UI规格','你的填写'],[
  ['生命','当前生命值','初始上限5，受击扣除','数字、图标、血条或混合形式？'],
  ['生命','最大生命值','V0.1不开放10的生命成长','是否显示明确上限？'],
  ['生命','低生命状态','T2已确定危险反馈','低于多少时提示？视觉如何变化？'],
  ['可能性','当前可能性','战斗及帮助NPC获得','数字、条形、图标或混合？'],
  ['可能性','可能性上限','初始10，可受7注视影响','如何显示上限变化？'],
  ['可能性','负数透支','最低可至-9','如何区分正常可能性与透支状态？'],
  ['可能性','获得反馈','击杀实体、帮助NPC等','数值弹出、资源动画或其他？'],
  ['可能性','消耗反馈','闪避、生命恢复','是否显示消耗数字或资源变化动画？'],
  ['恢复','恢复进度','长按2.8秒，完成后恢复生命','是否显示进度条？显示位置？'],
  ['闪避','连续闪避状态','最多三次，消耗递增','是否提示当前连续次数或资源不足？'],
  ['时间','当前日期','V0.1共3天','Day 1/2/3、倒数天数或其他？'],
  ['时间','日内时间','T4已确定自动流逝及事件推进','是否显示时钟？'],
  ['时间','最终战倒计时','10登场后启动15分钟倒计时','显示位置、形式与警告方式'],
  ['任务','当前任务信息','7救助任务及已冻结的剧情流程','常驻、短暂提示或仅在关键事件显示？'],
  ['区域','当前所在Region/Scene','荒地、田野、逆时战场','进入新区域时如何显示？'],
  ['战斗','当前战斗状态','探索/战斗状态区分','是否需要独立战斗状态提示？'],
  ['Boss','Boss生命信息','T5已有两名Boss','血条形式、出现与隐藏条件']],5],
 ['T7-C 对话交互反馈',['设计项','已知约束','需要确定的内容','你的填写'],[
  ['对话框布局','支持逐句对话','对话框在上方、下方还是角色附近？'],
  ['对话文本','支持NPC及剧情文本','一次显示多少行？是否逐字出现？'],
  ['角色信息','7、10与普通NPC','是否显示角色名称、头像或立绘？'],
  ['对话推进','玩家主动继续','使用什么输入方式？是否支持加速显示？'],
  ['对话结束','对话结束恢复控制','自动关闭还是确认关闭？'],
  ['强制剧情','剧情期间限制玩家控制','是否隐藏HUD？如何表示当前不可操作？'],
  ['NPC互动','普通互动手动、强制剧情自动','互动提示出现距离与位置'],
  ['救助选择','7任务存在帮助/放弃分支','选择界面如何呈现？'],
  ['放弃确认','离开可能导致任务永久失败','是否需要明确二次确认？'],
  ['任务完成','救助NPC后返回7','完成反馈与目标更新形式'],
  ['注视获得','7的注视提高可能性上限','如何提示永久成长？'],
  ['物品拾取','普通资源自动、关键物品手动','关键物品提示如何显示？'],
  ['机关交互','已有机关与限制门','是否需要状态文字或开启反馈？'],
  ['Boss初见','首次介绍仅播放一次','介绍名片的出现、消失及玩家控制规则'],
  ['10特殊救场','时间暂停、专用演出','HUD隐藏与恢复时机'],
  ['战斗胜利','解除战斗状态','胜利反馈及后续剧情衔接']],4],
 ['T7-D 暂停系统菜单',['设计项','需要确定的内容','当前约束','你的填写'],[
  ['暂停方式','如何进入暂停菜单','游戏时间暂停'],
  ['暂停布局','菜单占全屏或部分覆盖','不改变游戏玩法状态'],
  ['继续游戏','如何关闭菜单返回游戏','恢复原游戏状态'],
  ['设置','音量、画面、操作相关设置','具体可实现项目由T8确认'],
  ['操作说明','是否在菜单中显示按键说明','不新增独立教学系统'],
  ['返回主菜单','是否允许随时退出当前游戏','需要与存档规则一致'],
  ['退出游戏','是否需要确认','防止意外丢失进度'],
  ['菜单输入','鼠标、键盘、手柄如何导航','具体按键映射留给T8'],
  ['菜单音效','选中、确认、返回等','共用T6基础UI音效方案']],4],
 ['T7-E1 存档操作',['设计项','已冻结规则','需要确定的内容','你的填写'],[
  ['存档方式','8个检查点自动激活','是否同时允许其他自动保存时机？'],
  ['存档槽位','尚未确定','单存档还是多存档？'],
  ['新游戏','从开场坠落开始','新游戏是否覆盖已有进度？'],
  ['继续游戏','读取已保存数据','从最后位置还是检查点恢复？'],
  ['手动存档','尚未纳入冻结范围','是否仅使用自动存档？'],
  ['退出保存','退出时进度如何处理','必须防止事件重复领奖'],
  ['存档反馈','玩家需要知道保存成功','图标、文字或其他提示？'],
  ['死亡读取','检查点复活','与正常退出后重新进入是否采用相同规则？'],
  ['通关后存档','V0.1胜利结束','是否保留已完成标记？']],4],
 ['T7-E2 数据状态',['数据类别','已冻结规则或用途','需要明确的存档行为','你的填写'],[
  ['最后检查点','8个自动检查点','记录最后激活的ID'],
  ['玩家生命','死亡后恢复满生命','正常载入时的生命如何确定？'],
  ['当前可能性','死亡损失当前可能性的50%','正常载入是否恢复最后保存值？'],
  ['可能性上限','受7注视影响成长','永久保存'],
  ['可能性透支','可至-9','载入时负数如何处理？'],
  ['NPC任务','救助成功、失败等','已完成和永久失败状态如何保存？'],
  ['7的注视','完成任务后获得','不得重复领取成长奖励'],
  ['Boss击败','已击败永久保留','未击败Boss死亡后重置'],
  ['首次演出','初见敌人、Boss登场','首次观看记录永久保留'],
  ['普通敌人','死亡后重置','不永久保存普通敌人死亡状态'],
  ['Connection状态','Boss锁和事件门','已永久开启的通路保持开启'],
  ['Node完成状态','T5共有27个关键Node','按各Node的保存规则处理'],
  ['当前日期','V0.1三天','保留时间进度，不允许日期倒退'],
  ['当前倒计时','第三天最终战15分钟','死亡、退出、重试后如何处理？'],
  ['10救场','首次登场特殊事件','必须保留重试后的正确剧情阶段'],
  ['最终战进度','波次、增援与胜负','失败时从哪个阶段重新开始？']],4],
 ['T7-F 异常情况',['情况','需要确定的结果','你的填写'],[
  ['初次启动没有存档','“继续游戏”如何处理？'],
  ['玩家在恢复过程中暂停','恢复动作与计时如何处理？'],
  ['玩家在对话中暂停','是否允许暂停？对话进度如何保存？'],
  ['玩家选择放弃救助','如何反馈任务永久失败？'],
  ['可能性不足','如何提示恢复或闪避不可正常执行？'],
  ['可能性处于负数','HUD如何表示透支？'],
  ['玩家在Boss战死亡','Boss战、演出与通路如何重置？'],
  ['10登场后玩家死亡','如何避免首次救场重复及最终战无法继续？'],
  ['最终战倒计时耗尽','使用哪个已有失败反馈？'],
  ['最终战胜利同时倒计时归零','哪个结果优先？'],
  ['游戏退出时尚未到达下一个检查点','下次载入如何处理这段进度？'],
  ['玩家已完成V0.1','再次进入游戏时如何处理存档？']],3],
 ['T7-G 最终验收',['验收项目','通过条件','状态'],[
  ['主界面完整','能够开始游戏、继续游戏及进入设置'],
  ['HUD完整','生命、可能性、日期及倒计时可正确显示'],
  ['资源反馈完整','玩家清楚理解资源获得、消耗及透支'],
  ['对话交互完整','可完成7、10及基础NPC既定流程'],
  ['任务反馈完整','救助成功、失败与注视成长能够正确反馈'],
  ['菜单完整','暂停、设置和返回流程明确'],
  ['死亡恢复完整','正确恢复检查点、资源和世界状态'],
  ['存档完整','永久事件不丢失、不重复领奖'],
  ['时间状态完整','3天与最终倒计时的保存规则明确'],
  ['最终结算完整','胜利、超时、死亡不会触发错误结局'],
  ['V0.1范围一致','不引入T0之外的新功能系统']].map(r=>[...r,'待验收']),3]
];

const wb=Workbook.create();
const out=fileURLToPath(new URL('../Words/T7_UI_UX与存档规格填写模板.xlsx',import.meta.url));
const col=n=>String.fromCharCode(64+n);
const endRows=new Map();
function layout(name, headers, rows, inputCol) {
 const sh=wb.worksheets.add(name),n=headers.length,end=5+rows.length;
 endRows.set(name,[n,end]); sh.showGridLines=false;
 const grid=sh.getRange(`A1:${col(n)}${end}`);
 grid.format={font:{name:'Arial',size:11,color:'#17202A'},wrapText:true,rowHeight:50,verticalAlignment:'center'};
 sh.getRange('A2').values=[[name]];sh.getRange('A2').format.font={name:'Arial',size:15,bold:true,color:'#000000'};
 sh.getRange('A3').values=[[name==='T7-G 最终验收'?'A～F填写后共同验收，当前保持待验收。':'浅黄色为待填写栏目；预填规则不要求重新设计。']];
 sh.getRange('A2:A3').format.wrapText=false;
 sh.getRange(`A1:${col(n)}1`).format.rowHeight=12;sh.getRange(`A2:${col(n)}2`).format.rowHeight=30;
 sh.getRange(`A3:${col(n)}3`).format.rowHeight=26;sh.getRange(`A4:${col(n)}4`).format.rowHeight=12;
 sh.getRange(`A5:${col(n)}5`).values=[headers];
 sh.getRange(`A5:${col(n)}5`).format={fill:'#26384C',font:{name:'Arial',size:11,bold:true,color:'#FFFFFF'},wrapText:true,rowHeight:44,verticalAlignment:'center'};
 sh.getRange(`A6:${col(n)}${end}`).values=rows.map(r=>Array.from({length:n},(_,i)=>r[i]??null));
 const widths=n===5?[18,30,42,54,54]:n===4?[30,46,57,54]:[45,68,56];
 for(let c=1;c<=n;c++) sh.getRange(`${col(c)}1:${col(c)}${end}`).format.columnWidth=widths[c-1];
 if(inputCol)sh.getRange(`${col(inputCol)}6:${col(inputCol)}${end}`).format.fill='#FFF2CC';
 sh.freezePanes.freezeRows(5);return sh;
}
const notes=[
 ['填写范围','T7只确定界面布局、信息反馈、用户交互和存档规则，填写A～F空白栏。'],
 ['范围限制','不增加背包成长、技能树、复杂任务日志、独立地图菜单或复杂任务管理界面。'],
 ['已有任务提示','通过HUD、NPC对话与事件反馈实现已冻结任务信息。'],
 ['HUD呈现选择','决定常驻全部资源，还是按探索、战斗、剧情等行为动态显示；不新增玩法。'],
 ['存档与死亡','存档不等于死亡回档；永久完成事件保留，临时敌人与战斗状态按既定规则重置。'],
 ['具体技术','引擎实现、可支持设置和具体按键映射留给T8。'],
 ['验收时间','T7-G由双方在A～F填写完后共同检查，不需要现在填写。'],
 ['T6制作勘误','初始武器独立2D素材；视觉特效采用2D粒子与Shader；最终战胜利为实时演出配合关键专用动画。'],
 ['T6备注用词','残留“过场动画”备注统一按已确认实时演出方案执行，不扩大开发范围。'],
 ['来源','用户本聊天提供的T7《V0.1 UI / UX与存档系统规格》待填写内容，2026-10-14。']
];
const info=layout('填写说明与Todo',['项目','说明'],notes);
info.getRange('A3').values=[['先填写A～F；G留待共同验收。']];
info.getRange('A1:A28').format.columnWidth=36;info.getRange('B1:B28').format.columnWidth=100;
info.getRange('A6:B15').format.rowHeight=62;
info.getRange('A18:B18').values=[['开发前主Todo','状态']];
info.getRange('A18:B18').format={fill:'#26384C',font:{name:'Arial',size:11,bold:true,color:'#FFFFFF'},rowHeight:36};
info.getRange('A19:B27').values=[
 ['T0 V0.1范围冻结','完成'],['T1 玩家操作','完成'],['T2 战斗系统','完成'],['T3 基础属性与成长','完成'],
 ['T4 三天时间系统','完成'],['T5 地图、Room与Node','完成'],['T6 资源制作配置','完成'],
 ['T7 UI / UX与存档规格','正在进行'],['T8 技术开发基线','尚未开始']];
info.getRange('A19:B27').format={font:{name:'Arial',size:11,color:'#17202A'},rowHeight:36,wrapText:true};
endRows.set('填写说明与Todo',[2,27]);
for(const [name,headers,rows,inputCol] of specs) {
 if(name==='T7-F 异常情况') createFlow();
 const sh=layout(name,headers,rows,inputCol);
 if(name==='T7-G 最终验收') sh.getRange('C6:C16').dataValidation={rule:{type:'list',values:['待验收','通过','需补充']}};
}
// E3是冻结的基础流程和一个明确的待确认问题，不复制成新的操作决策表。
function createFlow() {
const flow=layout('T7-E3 死亡加载流程',['步骤','已冻结的死亡恢复基础流程'],[
 [1,'HP归零'],[2,'玩家倒地、死亡反馈'],[3,'进入死亡菜单'],[4,'返回最后检查点'],
 [5,'恢复满生命，按规则扣除可能性'],[6,'重置临时敌人，保留永久事件'],[7,'3秒复活无敌，恢复操作']]);
flow.getRange('A3').values=[['请确认正常退出重进与死亡复活是否有所不同。']];
flow.getRange('A1:A16').format.columnWidth=42;flow.getRange('B1:B16').format.columnWidth=95;
flow.getRange('A15').values=[['你的填写：正常退出重进与死亡复活是否不同？']];
flow.getRange('A15').format={font:{name:'Arial',size:11,color:'#17202A'},wrapText:true,rowHeight:65};
flow.getRange('A15:B15').format.verticalAlignment='center';
flow.getRange('B15').format.fill='#FFF2CC';endRows.set('T7-E3 死亡加载流程',[2,15]);
}
wb.recalculate();
console.log((await wb.inspect({kind:'sheet',include:'id,name',maxChars:1700})).ndjson);
await (await SpreadsheetFile.exportXlsx(wb)).save(out);
await fs.unlink(`${out}.inspect.ndjson`).catch(e=>{if(e.code!=='ENOENT')throw e;});
if(process.env.T7_PREVIEW_DIR) {
 await fs.mkdir(process.env.T7_PREVIEW_DIR,{recursive:true});
 for(const [name,[n,end]] of endRows) {
  const preview=await wb.render({sheetName:name,range:`A1:${col(n)}${end}`,scale:1,format:'png'});
  await fs.writeFile(`${process.env.T7_PREVIEW_DIR}/${name}.png`,new Uint8Array(await preview.arrayBuffer()));
 }
}
console.log(`Saved ${out}; ${specs.reduce((s,r)=>s+r[2].length,0)} specification/acceptance rows.`);
