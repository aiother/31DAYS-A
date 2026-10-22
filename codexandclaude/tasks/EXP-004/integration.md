# EXP-004 集成记录：检查失败，收尾阻塞

日期：2026-10-21（America/Los_Angeles）｜集成者：Codex｜状态：**已合入，但集成检查失败，未完成收尾**。

## 授权与固定提交

用户本轮要求“复审通过后合入目标为4018d73加审查记录”。本次先固定交付独立复审，通过后才合入；用户选定仍为对话D、G-08短提示、介绍卡2。没有接入正式对话界面或改T7-C。

- 合入前master：`ac23a8a1525f9f62bebb47de19f1daac18b72b24`。
- 修正实现：`77cedf47b52129f1a18618ff223d31f80e049af8`。
- 固定交付：`4018d73b80b6d0cedf9e3cb6f2453e7906fd122b`。
- 首轮审查：`24a2d63c16e72c2309c0f4d046a8ebe1a5ec2a50`；通过的复审：`a9399fa66c24696da138c19ed990b8251ebd10ea`，包含两轮记录，见[review.md](review.md)。
- 主目录执行git merge --no-ff --no-commit合入固定复审SHA，无冲突，再用说明文件提交。合并SHA：`0fabb7a32c7f75949f8c5e3a37cbb5092c7c9334`。未合并可移动分支名。
- 合入前主目录无暂存/已跟踪改动。源分支带入已批准的第六批规划5c73dfc；保留master已有UI-005及其完成记录。相对合入前，game/除prototypes/EXP-004外没有任何变化。

## 复审证据与合并后的冒烟

复审固定4018d73：冒烟108/0，额外暂停/焦点/布局探针64/0；四项变异分别失败4、8、8、12项，恢复108/0。独立full **G2 87/87，G3 102/102 + 67/67，退出0**。原始摘要见Codex工作区runs/20261022T041328.861097Z/summary.json，完整自动证据见review.md第2轮。

合入master后重新运行 `Godot --headless --path game --fixed-fps 60 --script res://prototypes/EXP-004/tests/smoke_test.gd`：**108/0，退出0**，无ERROR/WARNING。日志主目录codexandclaude/runs/exp004-integration-smoke.txt。

## master full失败

在主目录master固定0fabb7a、起点dirty=false运行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**退出1，整体失败**。摘要主目录codexandclaude/runs/20261022T042814.700335Z/summary.json；原始Godot报告engine.txt；验证器输出007.txt；完整入口输出runs/exp004-integration-full.txt。

验证器实际输出87个PASS、1个FAIL；失败的是UI-005套件 `res://tests/test_outcome_sheets.gd`：

```text
OUTCOME_SHEETS_TESTS checks=67 failures=0
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
```

该子进程退出0，但泄漏命中verify_game.py的严格错误标记，故套件不通过，verify_game.py退出1。run_checks.py在此短路，summary.checks为空，**本次full没有继续执行G3，不能报告集成G3通过或整体88/88通过**。没有重跑失败套件或full来替换这次结果。

已核对test_outcome_sheets.gd、life_ui.gd、pause_menu.gd及全部正式game文件相对ac23a8a均无变化；同一合入前master此前集成full曾通过。仍未定位这次ObjectDB泄漏的具体对象或原因，**不归因为环境问题，也不宣称已证明属于旧失败**。本记录不扩大EXP-004范围修复UI-005或测试框架。

结束另生成EXP-003两个缺失UID，content_stable=False，已跟踪diff为空。两条Missing .uid导入警告对应BL-115，与本次导致失败的ObjectDB泄漏分开记录。原始摘要与日志全部保留、不改写；结束后核对路径与哈希，仅删除这两个运行生成的UID，未动用户文件。

## 停止状态

按协作规范§5.8，停止后续集成和完成状态更新；没有撤销合并、重写历史或修改游戏代码。master停在上述合并SHA，任务卡未标已完成，BOARD/BACKLOG/ROADMAP未作收尾刷新。

仅在codex/EXP-004-integration分支新增本失败记录，另跑G3验证记录后提交；此文档检查不抵消master full失败，也不作为失败full中G3已运行的证据。该记录提交不继续合入master，留待用户处理集成失败后决定。

## 失败full自动证据

<!-- run_checks evidence v1 -->
总结果：**不通过**；模式：`full`。
被测SHA：`0fabb7a32c7f75949f8c5e3a37cbb5092c7c9334`；工作区：`D:\31days`。
工作区状态：**干净**。
开始：2026-10-22T04:28:14.701339+00:00；结束：2026-10-22T04:40:44.269562+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：未完成，**不通过**。
- G3:tests：未完成，**不通过**。
- G3:codexandclaude/tests：未完成，**不通过**。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`9e0299c1ace0db4abb67b3b913bb2eae8f129fbb`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`cd4378925afa40bc619c20f6675206d8cbd94dffd60312122d0899156baf4b30`；工作区范围指纹（原始字节）：`e5b04616104fc718687f7d9e7f56f573b23fcf6d50ef9da56ce96e3daef60581`。
全工作区指纹：`4b87b932277ae4ff9a55a92e048f6cabd658fd79e8d76812feadecbc0bea705f`；运行前后内容稳定：`False`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261022T042814.700335Z\001.txt`；SHA256=`33b9e8ad86e7f075dbb6e0ab621d12910532cfd7d011986a3915f20e789a8235`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.235秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261022T042814.700335Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261022T042814.700335Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.297秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261022T042814.700335Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261022T042814.700335Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261022T042814.700335Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\game", "--report", "D:\\31days\\codexandclaude\\runs\\20261022T042814.700335Z\\engine.txt", "--jobs", "4"]`；退出=1；耗时=747.75秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261022T042814.700335Z\007.txt`；SHA256=`6ae07b1a7de1ea7b695a9f8698d1d0e002967d0f6f7795d840e35984b29ea1b0`。

失败清单：Command failed (exit=1, timeout=False): ['C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe', 'D:\\31days\\scripts\\verify_game.py', '--godot', 'D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe', '--project', 'D:\\31days\\game', '--report', 'D:\\31days\\codexandclaude\\runs\\20261022T042814.700335Z\\engine.txt', '--jobs', '4']; log: D:\31days\codexandclaude\runs\20261022T042814.700335Z\007.txt；关卡未全部完成或执行集合不匹配；子命令失败或超时：["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\game", "--report", "D:\\31days\\codexandclaude\\runs\\20261022T042814.700335Z\\engine.txt", "--jobs", "4"]
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
