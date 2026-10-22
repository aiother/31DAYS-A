# UI-007 第1轮审查

审查者：Codex｜日期：2026-10-22（America/Los_Angeles）｜结论：**需修改**（R1、R2，均 P2）。不合并。

## 固定对象与范围

- 基线：`2ca7ca139fa95e85c6c399e17bfd2065dfd76874`。
- 实现：`80a8a9d3660086adb40851fa7937157bae6d198b`。
- 固定交付／被审 SHA：`900ebff2033cef3163d9ef6402aae0fa34b0b4f5`，先执行 `git switch --detach` 固定；审查分支 `codex/UI-007-review` 只新增本记录。
- 实现到交付仅新增 [delivery.md](delivery.md)、修改 [task.md](task.md) 首部，符合交接约定。
- 实现相对基线为11个文件：新区域名/提示脚本、测试、验收适配、对应UID、实施文档，LifeUI仅挂载节点，RoomPickup仅高亮表现。未改会话、范围、交互判定、存档、输入、旧测试或旧断言。
- 另核对 `db594dab9911c93cc731a0345b6aeb2865c6c0b8` 相对交付只新增 `tasks/UI-007/acceptance.md`。用户 G4 原话“没问题”、无调整要求，记录通过；本轮被审对象仍是900ebff，不把后续验收记录并进审查基线。

## R1 · P2：交互提示未避开真实错误提示，避让测试漏项

位置：`game/ui/hud/interact_prompt.gd:91` 的 `avoided()`、`:68` 的 `place()`；`game/tests/test_area_prompts.gd:237`。

避让列表只读取 HUD 的 emblem/hint/warning/final/banner 和区域名矩形，没有 LifeUI 的真实可见 `_error_label`，也遗漏了 HUD 的 horizon。布局测试只遍历 `prompt().avoided()` 来验证，因而无法发现列表自身漏掉了必须避让的对象。

**确定性复现**：在原始交付代码上使用测试已有的真实 FinalBattleSession + WithExtras，调用真实 `LifeUI.save_failed("无法写入存档，请检查磁盘空间和权限")`（这是 SlotStore 现有错误文字）；追加一个位于错误行附近的可用目标、以相机逆变换定位，正常帧后读取真实 Label 矩形和实际绘制的纸签矩形。1920×1080与1280×720都得到以下逻辑UI坐标：

- 错误行：`Rect2(40,360,900,31)`。
- 交互纸签：`Rect2(526,351.5,166,44)`。
- `intersects=true`。这不是假设多行错误才会出现的问题，现有一行保存失败提示即可复现。

额外边界探针：查询仍报告可用、目标投影在屏幕下方 `(1800,1300)` 时，clamp后的纸签为 `Rect2(1738,1020,166,44)`，与实际地平线 HUD `Rect2(0,988,1920,92)` 相交。该例是画面外可用目标的边界，不冒充普通屏内对象；现有测试没有底部/画面外分支。另用8行真实Label内容时，居中区域名矩形也与错误Label相交，区域名同样没有错误区域保护。

**建议修改**：让表现层取得可见错误Label和完整HUD的真实占区，候选位置必须对全部约束复验，空间不足时提示让位，不能盖住错误信息。区域名也应在错误区域占用时等待/让位或避让。新增两种分辨率下真实 `save_failed()` 用例，独立读取错误Label与HUD实际矩形比较，而不是只验证函数自行声明的避让集合；补底部边界。无需改变交互规则或会话接口。

原探针脚本与日志（忽略目录）：`runs/ui007-layout-probe.gd`、`ui007-layout-one-line.txt`、`ui007-layout-probe.txt`。探针使用独立临时槽，已清理；没有改被审实现。

## R2 · P2：关键物品测试没有约束实际高亮绘制

位置：`game/tests/test_area_prompts.gd:278`；`game/world/items/room_pickup.gd:37、42`。

当前高亮断言检查 `key_item()`、`highlight()` 数值随帧变化、拾取后visible=false，没有读取光晕/圆环实际绘制的记录。现有“highlight返回0”变异可以失败，但只证明辅助计算，不证明画面上的高亮存在。

**独立反例**：只删除 `_draw()` 中 `if pulse > 0.0` 下的 `InkDraw.glow(...)` 与金色 `draw_arc(...)` 两项实际绘制，保留 `highlight()`、动画时间、普通拾取绘制和所有游戏逻辑。完整新套件仍 **45/45、退出0**，没有错误；此时关键物品根本没有新增光晕或呼吸圆环。日志 `runs/ui007-mutant-remove-highlight-draw.txt`。检查后按原始字节恢复，并验证Git无源码差异。

**建议修改**：沿用本仓库已采用的绘制调用与记录同源方式，让实际光晕/圆环调用输出其强度、颜色与几何记录；测试真实关键拾取物的绘制、随帧变化、普通物品不画、拾取后不再可见。至少加入“删除实际高亮绘制仍保留highlight辅助函数”的反向变异，必须失败。无需强制引入像素测试。

## 非阻断建议

N1（P3）：`AreaBanner.blocked()` 还包括玩家不可控制（例如受伤）和HUD换日纸签；`:67` 对已经显示的名字在这些条件出现时同样直接清掉，不再补播。文档“等待/让位”目前只把对话与剧情列为显示中让位的条件。建议准确区分“尚未显示时等待”与“已经显示后被任一种非暂停blocked打断即丢弃”，并补受伤/换日的确定性用例。任务卡允许延后或不显示，并不要求改成补播。

## 三个交付说明的判断

1. **区域名称策略**：按scene_id识别跨区、同区换房不重播、恢复后首次显示；待显示时让剧情/对话/暂停/换日先行、新区域替换旧名字，方向合理。“显示中被对话打断即消失、不补显示”符合卡中“延后或不显示”的授权，可以接受；N1请补全实际条件的描述。错误Label避让仍须按R1补齐。
2. **位置与模拟目标**：在真实会话上叠加少量模拟目标测试最近者、边界、unlimited等，保留全部已存脚本属性并调用super查询，是合理的表现层测试方式，不算替换SYS-009规则。世界坐标经真实相机变换的做法正确。问题是现有断言覆盖范围与真实绘制不足，分别见R1/R2，不是反对模拟目标本身。
3. **灰盒提示保留**：不在本卡范围，且依赖旧断言；保留并另立任务移除合理，不作为本轮阻断项。未擅自替用户扩大任务范围。按键并列E/RB、keyitem前缀与SYS-009一致、UI-001字体和既有关键色用法可接受。

## 独立验证

- 原始交付新套件：`Godot --headless --path game --fixed-fps 60 --script res://tests/test_area_prompts.gd`，**45/0、退出0**。
- 验收入口自测：`Godot --headless --path game --fixed-fps 60 --script res://tests/acceptance/run_acceptance.gd -- --adapter=res://tests/acceptance/ui007_area_prompts.gd --self-test`，**UI007_ACCEPTANCE_TESTS 12/0、退出0**。
- 固定交付从干净工作区独立执行full：**G2 90/90，G3 108/108 + 67/67，content_stable=True，起止干净，ObjectDB泄漏0，退出0**。实际命令、工具版本、完整性、日志与哈希见下方自动摘要；原目录 `runs/20261022T083607.163723Z/`。
- 交付四项变异均独立复现，临时改错后跑45项套件：同区也显示 **1失败**，放远侧 **2失败**，忽略available **3失败**，高亮强度置零 **2失败**，均退出1。按原始字节恢复后再跑 **45/0**。明细 `runs/ui007-review-mutations.json`、`ui007-mutant-*.txt`。
- 这些门禁通过与R1/R2不矛盾：R1是缺少异常布局用例，R2有实际删除绘制而全绿的反例。未将“full通过”等同于全部完成标准通过。
- 所有临时变异均恢复，未修改Claude分支或提交实现修复。只提交本审查记录；记录新增后另跑G3。

## full 自动摘要

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`900ebff2033cef3163d9ef6402aae0fa34b0b4f5`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-22T08:36:07.163723+00:00；结束：2026-10-22T08:46:40.815156+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际90 / 预期90；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`1f92dbda8f0e2492c5bef67cade14d504210dd04`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`e137cfc681cdf141fc5d41a0d4c66fb6072308946dfb8135a79ac8963f7e2293`；工作区范围指纹（原始字节）：`f1b24059f9bfc14ea441a0d6a18f7c7a0c58e5cf53c36cb945b4a52ce91b3501`。
全工作区指纹：`2de65b476fd42ff8949dd888239bd850cd172764e45cbdb811650cd28f473c4d`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T083607.163723Z\001.txt`；SHA256=`22298b49dda31763858fcbe3823ba2543e047336e26c94881cbf7782b4d0a155`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T083607.163723Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T083607.163723Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.281秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T083607.163723Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T083607.163723Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T083607.163723Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\codex\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\20261022T083607.163723Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=618.141秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T083607.163723Z\007.txt`；SHA256=`6b57cfcf56fcab6835d6ff66b680f6d221d3f48cb07892179fe7512b7522b708`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.187秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T083607.163723Z\008.txt`；SHA256=`f25e66390a2e0387341a874c37f60a3ea6c266c97685c383c084880160267774`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=10.782秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T083607.163723Z\009.txt`；SHA256=`8223cb539945fa6fef2214442c3733f7fed6cb9f69020f5be8e6328844bf8aa2`。
- 报告 `D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T083607.163723Z\engine.txt` SHA256=`72c2419c80ad9549341fa32d4ed4519c1288893db4f8a4d3197c2c839ce9ad52`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
