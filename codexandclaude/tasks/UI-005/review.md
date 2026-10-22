# UI-005 第1轮审查

日期：2026-10-21（America/Los_Angeles）｜审查者：Codex｜结论：**需修改**，一项P2测试缺口。

## 固定对象与范围

- 基线：`2183e7760072afe8f9f1cf3378a08610c896b994`。
- 实现：`3caa56735fa748aaae80f984f4f2097dc9ec1537`。
- 被审交付：`22a635d017e214f397a3c647539064902fe245ea`，在Codex工作区用git switch --detach固定后审查；实现到交付只有delivery.md新增与任务卡首部变化。
- 范围符合任务卡：OutcomeSheet、三份菜单脚本、新专项、验收适配、两处必要旧断言与实施说明。没有修改final_battle_session.gd、checkpoint_lab.gd、存档格式、重试规则或InputMap。
- G4补充 `520de2abe663f96a696add3e8ed2e645c49035d4` 相对交付只新增acceptance.md，记录用户2026-10-22原话“G4没问题”。已读取核对，但本轮代码审查对象仍是22a635d，没有切换到G4提交或合入master。
- 本审查只新增review.md。Claude分支已有G4后继提交，后续修订时可普通合并本固定审查SHA，保留acceptance与两轮记录，不丢弃任一方历史。

## R1（P2）：暂停“返回标题”确认页的记录仍可脱离实际绘制

位置：`game/ui/menus/pause_menu.gd` 281～289行；`game/tests/test_outcome_sheets.gd` 226、235行。

新增确认页在_page_sheet / ink_text绘制后，另从heading、line、_error_text赋值drawn。新测试读取这些原始字符串，因此未证明确认标题与保存失败提示真的画出。注意：本项是测试覆盖缺口；原交付当前文字与保存行为本身通过了现有测试和用户G4。

独立变异均固定同一交付，在另一个Codex临时工作区执行，按原字节恢复：

1. 仅将 `_page_sheet(time, heading)` 的实际绘制参数改为“错误的确认标题”，保留drawn赋值：**OUTCOME_SHEETS_TESTS checks=57 failures=0，退出0**。确认标题实际错误，但测试仍认为“保存并返回标题？”正确显示。
2. 仅删除保存失败分支中实际画_error_text的ink_text调用，保留 `drawn["error"] = _error_text`：**57/0，退出0**。保存失败提示消失，但“失败时留在确认页并显示错误”的断言仍通过。

这不满足完成标准1“断言读实际绘制记录”，也使要求6的保存失败提示回归缺少有效保护。新OutcomeSheet的_ink绘制记录已经正确，问题集中在PauseMenu新增确认页的标题/说明及错误记录。

建议：让确认页的绘制辅助调用返回实际画出的文字，再用返回值组成confirm/error记录；没有执行错误绘制时记录应为空。补上述两种只改实际绘制的变异，确认专项失败。无需改变当前UI文案、返回标题保存逻辑或重试规则。

复现命令：`Godot --headless --path game --fixed-fps 60 --script res://tests/test_outcome_sheets.gd`。日志：`worktrees/codex/codexandclaude/runs/ui005-mutant-wrong_title_draw.txt`、ui005-mutant-error_draw_missing.txt。临时变异全部恢复后git diff为空，原专项57/0。

## 用户指定重点的其余结论

- **旧断言两处有必要且未削弱规则**：pause_menu保留四个选项及导航检查，只把存档槽替换为返回标题并明确排除旧按钮；final_retry原预算0时改为精确检查只有返回标题，比旧“第二个按钮含存档槽”更严格，重试拒绝断言保留。
- **设计取舍可接受**：任务卡要求2～4和T7-A原表第15、16行分别列“夕阳将至/未来已失、游玩时长、返回标题”；A-011另加入最终战确认重试，探索超时保留独立反馈。去掉结束/超时的保存并退出与该清单一致，返回标题后仍可从主界面退出，不改变保存或重试规则。A-014要求的死亡退出游戏保留。G4补充记录也未提出该取舍的异议。
- **死亡问句与模式恢复正常**：真实输入额外检查Back关闭、Enter取消后恢复death模式与退出游戏焦点；死亡设置的Back及鼠标返回恢复death和设置焦点。另检查最终战超时返回标题保存失败时仍暂停、仍有会话与纸面、错误位于纸面，恢复目录后再次确认可回主界面。扩展探针 **65/0**，无ERROR/WARNING，日志ui005-state-probe.txt。
- **布局**：补充探针覆盖死亡四选项、死亡问句、有/无预算最终战超时、探索超时、结局演出及结束纸面的1920×1080、1280×720，纸面及按钮均在窗口/纸面内，既有错误布局断言通过；扩展专项 **71/0**，日志ui005-all-layout-probe.txt。
- 所有返回标题都调用会话return_to_title，保存失败不离开；final_ui.message作为会话写入来源在ending期间同步到纸面，slots_requested保留连接但不再发出，未改系统接口的规则实现。

## 非阻断建议

N1：正式layout_cases目前只在零预算纸面执行。建议把本次独立全纸面布局探针中的14项几何检查纳入登记专项，持续覆盖死亡四选项及问句等较高纸面；本轮独立探针已全部通过，没有发现实际重叠。

## 独立检查与变异证据

固定交付、起点dirty=false，执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**退出0，G2 88/88，G3 102/102 + 67/67**。原始摘要：`worktrees/codex/codexandclaude/runs/20261022T015153.269059Z/summary.json`。

规定变异在独立工作区执行，每次结束立即按原字节恢复；绕过保存时只调用既有_return_title，保留临时save_directory的传递，不让后续测试进入玩家正式目录。命令同上述专项。

| 变异/专项 | 实际结果 |
| --- | --- |
| 暂停返回标题绕过保存 | 57项、2失败、退出1 |
| 死亡返回标题绕过保存 | 55项、1失败、退出1 |
| 最终战重试改为返回标题 | 57项、1失败、退出1 |
| 最终战返回标题改为重试 | 57项、2失败、退出1 |
| 原预算0仍显示重试 | 57项、2失败、退出1 |
| 实际确认标题画错 | 57/0，漏检（R1） |
| 实际错误提示不画 | 57/0，漏检（R1） |
| 原字节恢复后的专项 | 57/0、退出0 |
| 死亡状态/超时失败补充探针 | 65/0、退出0 |
| 全纸面双分辨率布局探针 | 71/0、退出0 |

五个独立验收自测：UI-005 21/0、UI-003 16/0、UI-004 22/0、UI-006 20/0、SYS-004 16/0，均退出0、无ERROR/WARNING。命令 `Godot --headless --path game --script res://tests/acceptance/run_acceptance.gd -- --adapter=res://tests/acceptance/<适配名>.gd --self-test`；适配名依次ui005_outcomes、ui003_pause、ui004_title、ui006_settings、completed_slots。日志ui005-acceptance-*.txt均位于Codex runs目录。

探针脚本位于本工作区codexandclaude/runs/ui005_state_probe.gd、ui005_all_layout_probe.gd（不入库），用 `--fixed-fps 60 --script ../codexandclaude/runs/<探针名>.gd`启动。原full通过与R1变异漏检分别记录，不把漏检或预期失败算作原full失败。

full结束content_stable=False，仅生成EXP-003的capture.gd.uid、smoke_test.gd.uid两个未跟踪导入文件，已跟踪diff为空。原始摘要不改写，不作为后续复用来源；结束后只删除这两个本轮生成文件。写入本记录后另跑G3，通过再仅提交本文件。工具版本与完整证据如下。

## full自动证据

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`22a635d017e214f397a3c647539064902fe245ea`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-22T01:51:53.269059+00:00；结束：2026-10-22T02:04:37.840312+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际88 / 预期88；完整=True；通过=True。
- G3:tests：实际102 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`01cfe189ff0b01f8e951284c5d0763d9d44a51d9`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`d30b6bcb9b824b2ad168a411b81d49e9eb10dbecbc68d47d5f186505cf227c52`；工作区范围指纹（原始字节）：`3beaea47946488e5cc4e572986805ebe487e712f3163a56a37d282d0500e9df7`。
全工作区指纹：`9eb51d8fc896f9791384c4127c44e4d992cf6ee891a65ee99ae84ae27b55eef9`；运行前后内容稳定：`False`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T015153.269059Z\001.txt`；SHA256=`bd193128ace113a6da6eafda16543a810e1f0f93dac13162a1b050abd4ccb360`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T015153.269059Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T015153.269059Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.312秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T015153.269059Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T015153.269059Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T015153.269059Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\codex\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\20261022T015153.269059Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=748.843秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T015153.269059Z\007.txt`；SHA256=`ad722ace4c0a43a86a8497518ac7d385c3c01ef1ee27d38004f14f952ab1ead2`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.188秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T015153.269059Z\008.txt`；SHA256=`f2f26820f45d1db86574de23ec74ba087c4c3fb9e5534960a681a77fcdc2fc87`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=11.0秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T015153.269059Z\009.txt`；SHA256=`2c96e865e9277e8936d4d16aa9a793bac44d719dd9e5ea172eff23f276430819`。
- 报告 `D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T015153.269059Z\engine.txt` SHA256=`cff0962e68e7c7b2f03c6fad2475dfa431952eaeed00404bb62cb8d574ac2234`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
