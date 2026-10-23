# UI-008 第1轮审查

审查者：Codex｜日期：2026-10-22（America/Los_Angeles）｜结论：**需修改**（R1、R2、R3，均 P2）。不合并 master。

## 固定对象与范围

- 规划基线：`164cd977bcf8496fe217d223c39a42e3ad6ea89e`。
- 实现：`c439c575c2a065dc5adaff7a163124f8a6e53d5d`（c828ccc 实现，加 c439c57 的加速标记断言）。
- 首次交付：`ba4e5a54a53dfcce8d7283ea6d63c6cfcd9522bb`。
- 本轮固定被审 SHA：`3ac9188b19f76ff701fffb7aa2c50a89c1dbcb0e`，含用户 G4 记录。先执行 git switch --detach 固定，再审查和运行检查。
- 实现到被审交付仅新增 [delivery.md](delivery.md)、改 [task.md](task.md) 首部；ba4e5a5 到3ac9188只改交付记录中的G4结果。用户原话“G4核验完了，没问题”，说明行保留，记录已核对。
- 实现相对规划只改7个约定文件：FieldDialogue、对应测试/UID、验收适配/UID、实施文档及 T7 核对表。没有改会话、LifeUI、旧测试／断言、存档或输入映射。
- 审查分支独立于 Claude 实现分支，最终只新增本 review.md。未合并 master，也未代替实现者修复。

## R1 · P2：G-08 尚未显示就被对话消耗，结束后本次进入永远不再出现

位置：`game/ui/dialogue/field_dialogue.gd:291`（尤其301～305）与349～352。

_update_missed() 只检查过期对象、距离与摆放位置，没有检查 active。真实交谈打开对话后，_draw_missed() 因 active 返回、不画纸签，但 _update_missed() 仍置 _missed_shown=true 并推进4秒计时。这不是已显示过的纸签被对话暂时遮住：它可能从未出现过，就永久消耗本次进入的唯一机会。

**独立复现（真实 FinalBattleSession、过期存档、真实 E 输入，固定60帧）**：进入 HD_20001_2，将玩家放到 Survivor 位置，立即按E开始其过期对话，保持对话300帧，再用E结束对话并继续观察120帧。结果：

- 对话中：active=true，ever_drawn=false，missed_age=-1，_missed_shown=true。
- 对话结束后：active=false，ever_drawn仍为false，missed_age=-1，_missed_shown仍为true。
- 正确性探针 `UI008_G08_REVIEW_PROBE checks=3 failures=1`，退出1。原套件只覆盖先看到纸签再交谈，遗漏首次显示前就交谈的路径。

请让尚未显示的G-08在对话／当前不可绘制期间等待，不要先消耗本次进入状态；至少保证对话结束、仍靠近时能实际显示一次。已显示后的隐藏／计时策略写清即可，不要求每次交谈都重播。新增上述真实输入回归，同时保留同次进入只一次与离开重进可再显示的检查。

## R2 · P2：纸面与继续三角是自报记录，删除真实绘制仍全部通过

位置：`game/ui/dialogue/field_dialogue.gd:234`～235、252～253；`game/tests/test_dialogue_ui.gd` 的纸色和继续标记断言。

正文、名签文字与加速符号通过 _ink() 返回实际所画内容，这部分做法成立；但纸面由 _torn_sheet() 绘制后另写固定 record["paper"]，继续三角由 draw_colored_polygon() 绘制后另写 record["marker"]="continue"。这些记录不能证明实际绘制仍存在。

独立做两项变异，各次只移除一处真实绘制、保留状态与记录，跑原套件后按原字节恢复：

| 变异 | 原套件结果 |
| --- | --- |
| 删除整张纸面的 _torn_sheet(panel, BOX, ...) 调用（纸面与上下撕边都不画） | **33/0，退出0，存活** |
| 删除继续三角的 panel.draw_colored_polygon(...) 调用 | **33/0，退出0，存活** |

缺少方案D主体或继续标记均违背要求1／完成标准1，现有断言却通过，与交付所说“记录均由绘制调用同时产生”不符。请让这些关键元素的颜色、形状／几何记录来自实际绘制函数的返回，并据此断言；删除对应实际绘制调用必须失败。沿用既有 draw-and-return 模式即可，不要求建立像素截图测试。

## R3 · P2：ALWAYS 处理模式改变了 show_notice() 的暂停行为

位置：`game/ui/dialogue/field_dialogue.gd:61` 与119～122。

将整个 FieldDialogue 改为 PROCESS_MODE_ALWAYS 用来守护暂停按钮后，show_notice() 中绑定该节点、采用默认暂停策略的 Tween 也会在暂停时继续运行。源码虽没改 show_notice() 函数体，行为仍变了；卡要求6明确把 quest／show_notice() 保持原行为并留给UI-010。

**基线对照**：从164cd977提取原 FieldDialogue（只去掉 class_name，避免与当前类重复注册），与当前 FieldDialogue 同挂在一个真实会话下，各调用 show_notice()。同一帧暂停、等待60物理帧：

- 基线提示 alpha：0.98888886 → **0.98888886**（冻结）。
- 当前提示 alpha：0.98888886 → **0.65555561**（仍淡出）。
- `UI008_NOTICE_REVIEW_PROBE checks=2 failures=1`，退出1。暂停足够久会在玩家恢复前耗尽本应暂停的通知。

请保留按钮暂停守护，同时为原 notice 的 Tween 保留原暂停语义，增加暂停冻结、恢复继续淡出的回归，不改UI-010的呈现范围。

## 已核对与非阻断说明

- 保留隐藏 text／speaker／hint Label 作为旧接口的数据模型合理，未见需要改会话或旧断言才能配合的接口变化。用户G4选定方案D与说明行保留均已留证。
- T7核对表仅补对话外观、名签说明与G-08实施说明；出处为EXP-004用户选定，采用修订注且不改T7原件，与已有任务惯例相同，没有替用户改变救助裁决或输入规则。
- G-08要求当前Room id等于任务id，避免把小镇任务的过期提示画到7处，这个限制合理；复用实际HUD、区域名、正式交互提示、错误矩形并逐候选复验的思路也合理。
- **N1（非阻断）**：沟壑深处 HD_20001_3 是清敌自动救助，没有 Survivor 交谈查询；这里实际走 MISSED_REACH=160 的UI距离回退，而不是 SYS-009 in_range。代码注释、实施文档与交付说明已披露；建议补该房间真实过期存档用例并明确这是提示距离，不是新增交互范围。当前自动测试只用沟壑救助房间覆盖出现路径。

- **N2（非阻断）**：完整回归的 test_day_clock_session 43项断言通过，但在同一帧 paused=false 后立即 show_departure() 时，按钮仍保留暂停态的 FOCUS_NONE，grab_focus() 报“This control can't grab focus”警告（回溯到 FieldDialogue:195）。下一处理帧的 _guard_pause(false) 才恢复。建议公开 show_departure() 同步当前暂停／聚焦状态，或只在可聚焦时抢焦点，并补这个同帧用例。当前工具不把这类普通WARNING当失败，不能把它误报为full失败；本记录照实保留诊断。

## 独立检查

工具与完整full命令、计数、指纹见下方自动证据。补充检查使用同一个 Godot 4.7.2，命令中的Godot指 D:/DMyself/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe。

- 原始固定交付专项：`Godot --headless --path game --fixed-fps 60 --script res://tests/test_dialogue_ui.gd`，**33/0，退出0**。
- 验收入口自测：`Godot --headless --path game --fixed-fps 60 --script res://tests/acceptance/run_acceptance.gd -- --adapter=res://tests/acceptance/ui008_dialogue.gd --self-test`，**12/0，退出0**。此为入口自测，不替代用户G4。
- R1／R3探针通过同一Godot、同一项目与固定帧率，以 runs 下绝对脚本路径运行；各自期望行为断言失败如上。均使用独立临时存档，正常释放与清理。
- 交付列出的六项原变异均独立复现，正常跑满33项、退出1，失败数如下；另两项存活变异见R2。

| 原变异 | 失败数 |
| --- | --- |
| hold_speed | 1 |
| default_leave | 1 |
| paused_buttons | 2 |
| not_expired | 1 |
| lock_player | 3 |
| repeat_visit | 2 |

变异结束后立即按原字节恢复，git diff --exit-code 确认无源码差异，才开始固定3ac9188的full。审查记录写入前不改任何被测文件；临时脚本和原始日志仅在忽略的runs目录，不入库。

本地补充证据：

- `codexandclaude/runs/ui008-review-g1.txt`，SHA256=854b69ae7d7c0220e4284b3ccd2ddb2a3d39e89ad369f6dc300143e1fe955b91。
- `codexandclaude/runs/ui008-review-acceptance.txt`，SHA256=79648b9ed8654787b9df74941bc8e8f876fc4d35e2fce8b5be686057875377e6。
- `codexandclaude/runs/ui008-g08-input-probe.txt`，SHA256=8c1346617de71ff8658f2f7af4982bcb6aadcd08617fa51300078f6c0aab502a。
- `codexandclaude/runs/ui008-notice-probe.txt`，SHA256=511120849af66045d5b3b7c544fc939204990aa8180cdf42b2355e81d7bf7f52。
- `codexandclaude/runs/ui008-review-mutations.json`，SHA256=d358c2fd3b3075a5b0643adb83722110843df09f3fbef1595ec1092b55ad0956。
- `codexandclaude/runs/ui008-original-mutations.json`，SHA256=c347aa88cdbb7af2b5ab0aba8e67a06fc912cff3610aaa4518dc9eebb57aaf5e。

## 固定交付独立 full 自动证据

固定交付上的full通过：G2 91/91，G3 108/108 + 67/67；起止干净，content_stable=True，无ObjectDB泄漏。日志含N2所述一条普通焦点警告；不宣称无警告。两个独立正确性探针和两项绘制变异揭示的是原套件未覆盖的问题，不能用full通过抵消R1～R3。

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`3ac9188b19f76ff701fffb7aa2c50a89c1dbcb0e`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-22T15:59:29.064212+00:00；结束：2026-10-22T16:09:58.540874+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际91 / 预期91；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`4fd47ba923b50c78013452572279e7e26ad50eca`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`34b1630a881e81930275d1cf1a8029bec63f30ddf17c2fa2a0650819958af1f3`；工作区范围指纹（原始字节）：`1238f3bd5cd4352553e4ac55fdae7a95a37bda6b08ce2fc3ca7f4cb31924bbff`。
全工作区指纹：`c341d793cb2f98240d4a91dd4d2d3971066a3fb31b77cef0c28634ca3305cea5`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T155929.063208Z\001.txt`；SHA256=`ddcfb28d4f6a4532ba18f7f0f062e71e129af99cc549e51f78e66ae47985e20e`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T155929.063208Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T155929.063208Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.281秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T155929.063208Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T155929.063208Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T155929.063208Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\codex\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\20261022T155929.063208Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=611.562秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T155929.063208Z\007.txt`；SHA256=`5022187fced72da987181f30ff80cdf48935b4dd7fa113830441c8433a57dfff`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.125秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T155929.063208Z\008.txt`；SHA256=`b8f1e7989a7db52d0b87a61ceea078ecf856cbbc6b454ec174deef949f4bc92e`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=13.266秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T155929.063208Z\009.txt`；SHA256=`391790151263fba0454fd2a2b6f1361c5eac0138eb3976c3dc81d5c9a0259eac`。
- 报告 `D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T155929.063208Z\engine.txt` SHA256=`1565f1dc3e370e65f4b0c6253987ff4e9226564f34137f26668acd8f685350bf`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

## 审查记录 G3

审查记录写入后 focused --python-all 通过：G3 108/108 + 67/67，退出0；摘要 codexandclaude/runs/20261022T161026.017111Z/summary.json。此次仅新增 review.md，不作为干净 G2 复用来源。

---

# UI-008 第2轮复审（第1轮审查修复）

审查者：Codex｜日期：2026-10-22（America/Los_Angeles）｜结论：**通过，无阻断项**。上一轮R1～R3已解决，N1、N2已采纳；新增一条非阻断测试建议N3。本结论仅针对下列固定修复交付，不改写首轮历史；未合并master。

## 固定对象与修订范围

- 首轮审查：`bb517681a907c1dfae9ba066cb5a66c1e41ae7eb`，已被Claude快进包含。
- 修复实现：`97de9c73e07957a29af77f84cb360f5e024dda4a`（8093efa修复、9ae0f65说明、97de9c7确定性用例）。相对首轮审查只改 `game/ui/dialogue/field_dialogue.gd`、`game/tests/test_dialogue_ui.gd`、`game/docs/dialogue_ui.md`。
- 固定被审交付：`0d8e3a60706e29e136f2fbd1fe0bea928c5de67d`。先 git switch --detach 固定，再读代码、执行探针／变异及独立full。
- 修复实现到交付仅更新 [delivery.md](delivery.md) 与 [task.md](task.md) 首部；无额外实现变化，没有修改会话、存档、交互范围、输入或旧断言。
- 复审记录只在独立 codex/UI-008-review 分支追加，保留首轮记录。未改 Claude 实现分支或 master。

## R1～R3 与 N1、N2

| 项目 | 复核结论 |
| --- | --- |
| R1：G-08尚未显示就被对话消耗 | 启动条件新增 not active；已启动的只在非对话时推进age。场景切换重置仍先执行，不会把旧房间提示带到新房间。三条真实会话回归覆盖立即E交谈、先开对话再靠近、先见提示再交谈。单次进入／离开重进原检查保留。特别是97de9c7新增的确定性用例明确要求对话中age<0、未标已用，能杀死50项版本曾漏掉的提前启动变异。 |
| R2：纸面与三角自报记录 | _torn_sheet() 在实际绘制处返回fill、edge与实际点集，_go_on()绘制并返回三角；调用方取其返回值。主体纸面调用删除后失败2项，三角调用删除但保留旧continue常量后失败1项，均跑满52项，不再像首轮33/0存活。正文／名签文字／加速符号原draw-and-return模式保留。当前底边与三角的实际计算正确；边界测试的可加强处见N3。 |
| R3：notice暂停仍淡出 | Tween显式 TWEEN_PAUSE_STOP，保留ALWAYS按钮守护而恢复notice原暂停语义。新增60帧冻结与恢复淡出回归通过；原基线对照探针也转为通过，旧、新两者alpha均保持0.98888886不变。 |
| N1：沟壑深处的显示距离回退 | 新增真实过期状态的HD_20001_3用例，确认无Survivor交谈目标、距离外不出、距离内出且can_control为真。文档明确160像素只是提示显示距离，不是新增交互范围。 |
| N2：同帧恢复后抢焦点警告 | show_departure() 先设默认_refocus再同步当前暂停状态；同帧恢复立即聚焦、暂停中调用保持按钮禁用、恢复后聚焦均有用例。_guard_pause()仍恢复正常暂停前的选项。最终full的焦点诊断见下方。 |

原G-08探针原样重跑 **3/0**：本次输入时纸签可在按键前一帧已开始，故对话中age=0、已用=true，但age冻结且对话结束后确实画出（ever_drawn=true）；不把该探针单独当作“从未启动”的证明，后者由上述确定性用例和提前启动变异独立证明。原notice基线对照探针 **2/0**。两个旧探针都使用隔离临时存档，没有修改固定实现。

## N3 · 非阻断：几何边界断言还可补完整

新测试验证纸面fill/edge、顶边位置和起伏、上下沿点数及轮廓横跨；继续三角验证颜色、3点、首点在纸笺内。但底边当前只检查点数，尚未逐点检查y位置／起伏；三角尚未检查另外两点是否在纸笺内。

补充两项独立变异：①底边改成完全平直；②只将三角第二顶点向右移1600像素，首点不动。两者均 **52/0、退出0，存活**。这不否定R2本轮已解决的核心问题：实际绘制返回记录，删除纸面／三角绘制已能被拦住，且当前真实几何计算无误；不是新的现有功能错误。建议补底边位置／起伏、三角所有顶点的边界断言，并让交付说明精确对应实际覆盖范围。本建议不阻断通过。

## 独立检查与变异

- 固定交付专项：`Godot --headless --path game --fixed-fps 60 --script res://tests/test_dialogue_ui.gd`，**DIALOGUE_UI_TESTS 52/0**。
- 原R1／R3探针：同一Godot与项目、固定60帧，分别以 runs/ui008-g08-review-probe.gd、runs/ui008-notice-probe.gd 的绝对路径启动；**3/0、2/0**。
- 验收入口：`Godot --headless --path game --fixed-fps 60 --script res://tests/acceptance/run_acceptance.gd -- --adapter=res://tests/acceptance/ui008_dialogue.gd --self-test`，**12/0**。此为自动自检，不冒充用户G4。
- 12项修复变异在最终52项版本上均独立复现，逐项按原字节恢复，结果与交付表一致：

| 变异 | 失败项数 |
| --- | --- |
| hold_speed | 1 |
| default_leave | 3 |
| paused_buttons | 3 |
| not_expired | 1 |
| lock_player | 8 |
| repeat_visit | 4 |
| start_in_dialogue | 1 |
| age_in_dialogue | 4 |
| remove_paper | 2 |
| remove_continue | 1 |
| notice_pause | 1 |
| departure_sync | 1 |

全部正常跑满52项并退出1，不是解析错误。源码按原字节恢复、git diff --exit-code 确认干净后才跑full；full运行期间不改被测内容。补充两项存活变异见N3。

用户G4仍为3ac9188记录的2026-10-22原话“G4核验完了，没问题”，按键说明行保留。修复记录没有声称重新G4；本次未重做用户验收。此次不改纸笺／按钮布局、颜色、文字与输入设计，修正预期的计时／暂停／焦点语义并有自动回归，沿用该外观验收记录的理由成立；不据此自动授权合并。

工具、完整命令、full计数与指纹见下方自动证据；补充命令的Godot为 D:/DMyself/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe。

本地补充日志（runs不入库）：

- `codexandclaude/runs/ui008-r2-g1.txt`；SHA256=ade741bba4a324a3b1affc7437dff1005093571c29abe883c04b6e831d28ed99。
- `codexandclaude/runs/ui008-r2-g08-probe.txt`；SHA256=2a110b333c9439960eca06d045e15a17a90075527307108363d8f3f6d68d290f。
- `codexandclaude/runs/ui008-r2-notice-probe.txt`；SHA256=484752f2f4d4c16ea1d9c0abd890fe4afc2e68d6db18bbb861ddffafacebd529。
- `codexandclaude/runs/ui008-r2-acceptance.txt`；SHA256=b64ac75dd7ab9d3ae6f309d38f8aceee217512ff51ec0433aea96c8fbcb37eaf。
- `codexandclaude/runs/ui008-r2-mutations.json`；SHA256=8724624fed5fde3e64570ea6ebefb673cd252721a07f44fa98e709beb4eac66a。

## 固定修复交付独立 full 自动证据

独立full通过：G2 91/91，G3 108/108 + 67/67；起止干净，content_stable=True。engine.txt 无 ERROR、WARNING、ObjectDB 泄漏；上一轮 can't grab focus 警告为0。

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`0d8e3a60706e29e136f2fbd1fe0bea928c5de67d`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-23T03:00:00.522568+00:00；结束：2026-10-23T03:10:24.583869+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际91 / 预期91；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`303844f4759042de441c413ccf5c459cda12ebef`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`dc94dab3ee42a4ab0b91efda941afc26a934b341ae684b4a3e5fa16eaf1a0bbd`；工作区范围指纹（原始字节）：`d0434d8b9229c19d6e4a745858344fa4de91eec1c11258af19f3a33f082cb7a4`。
全工作区指纹：`5e36d4a40c8ad7f392c0a9f1c75b5b87ceb5f107ad6437eb46dd6babbb8b94c3`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T030000.521644Z\001.txt`；SHA256=`350945b73214a2c56bbedef90c7fe4c9dcc96126aa5c8f69001d91a37388382d`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T030000.521644Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T030000.521644Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.281秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T030000.521644Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T030000.521644Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T030000.521644Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\codex\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\20261023T030000.521644Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=608.171秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T030000.521644Z\007.txt`；SHA256=`142d563f65597c9d18298882f4450a735c81f008f59bec1b56806b33c440c80e`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.234秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T030000.521644Z\008.txt`；SHA256=`27eefd6acea352694b2d7367391dace665c6daa918987978c3efe8728b126a64`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=10.86秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T030000.521644Z\009.txt`；SHA256=`e1528687f0ee4dfa21ec51e4f5f9f50b53cc7eb28cb7cca7ba0a3615027dd5b4`。
- 报告 `D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T030000.521644Z\engine.txt` SHA256=`e1ea86ece2dc1683adaada42bccebb5d1d6627db52f4d1ac20bce5138f327444`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

## 复审记录 G3

复审记录写入后 focused --python-all 通过：G3 108/108 + 67/67，退出0；摘要 codexandclaude/runs/20261023T031058.677738Z/summary.json。此次仅 review.md 待提交，不作为干净 G2 复用来源。
