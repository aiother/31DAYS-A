# UI-010 集成记录

日期：2026-10-23（America/Los_Angeles）｜集成者：Codex｜状态：已完成。

## 用户授权、G4与固定合入

用户本轮要求“以455bad87f53d420a9b23673d8c6be38a6ec88b74为准……合入master并留集成记录”，并要求第七批全部完成、M2-c收尾后一并更新BOARD。

- 合入前master：`96f0400b08f770ee86d8385db2c0f9c29e5e31a1`；完整Git执行环境工作区干净，game/project.godot没有未提交改动，没有与待合入文件重叠的用户改动。
- 最终实现：`a9569d99c47ad79a242a5c821d6344c70dcf6681`；修复交付：`85c03928b157f1c9d123ca90cd5a3d9b75eb29eb`。
- 最终复审：`cc0df6d3e8e054f5e9f6087ac9b16f0a5744489a`，通过、无阻断项，含三轮 [review.md](review.md) 历史。
- 固定合入目标：`455bad87f53d420a9b23673d8c6be38a6ec88b74`。核对相对上述最终复审只改delivery.md的两处G4/状态文字，没有代码、测试或其他文件变化。
- G4：用户2026-10-23在第2轮修复和第3轮复审通过后验收，原话“G4测完了，没问题”，记录见 [delivery.md](delivery.md)。本次不是沿用旧修复前的验收，也没有把入口自检算作用户G4。
- 合入前 `git merge-tree --write-tree HEAD 455bad87f53d420a9b23673d8c6be38a6ec88b74` 无冲突；实际执行 `git merge --no-ff 455bad87f53d420a9b23673d8c6be38a6ec88b74`，无冲突，没有合并可移动分支名。
- 合并提交／本次固定被测SHA：`95effa2a943162921f124b09c280bac0df292477`；父提交为合入前master与固定合入目标。

没有在集成时修改经审查的代码、测试、存档、输入或数值；R1当前任务查询、R2独立获得事件与两种顺序的重复文字去重、一对一合成及窗口外重显的修复与74项回归完整保留。

## master 全量检查与收尾

在主目录D:/31days、master合并提交上执行：

`python codexandclaude/tools/run_checks.py full --jobs 4`

退出码0；G2 **94/94**，G3 **108/108 + 67/67**，全部通过；UI-010专项74/0。起止工作区干净、content_stable=True，ERROR / WARNING / ObjectDB泄漏均0。摘要：codexandclaude/runs/20261023T082503.852027Z/summary.json。

没有以Claude交付或Codex审查工作区的检查替代本次master集成回归；下方附本次自动证据。

收尾只新增本integration.md，将UI-010任务卡首部改为已完成，BOARD中UI-010标为已完成并记录用户G4通过；更新BOARD日期、增加第七批与M2-c收尾说明。UI-008、UI-009、CLN-001的完成状态与既有集成记录保留，四项均已完成。

BOARD更新时保留其与ROADMAP/BACKLOG一致的规划汇总基线master@6591165，并明确后续批次规划统一刷新；本次不改ROADMAP、BACKLOG或开新任务。任务状态以各自任务卡首部为权威。

## master full 自动证据

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`95effa2a943162921f124b09c280bac0df292477`；工作区：`D:\31days`。
工作区状态：**干净**。
开始：2026-10-23T08:25:03.852027+00:00；结束：2026-10-23T08:35:54.304559+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际94 / 预期94；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`d845e147664dfc29ff7ec7771122236af6f39859`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`23dff8f819a9156fae948849223b87c9d4d372a11e63e1f21849bbd4900f0efe`；工作区范围指纹（原始字节）：`527d5db9961e238dcf9b8d9bd5a1d655a20a8afd44922239ecbb56aafc86c5d8`。
全工作区指纹：`90324ed09e4306e84fac9eddae024ed02d44f1e9d09f276fe837d1fb8c3a3ec9`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T082503.852027Z\001.txt`；SHA256=`6bf017b6167501ea5d426f0b02a644d508ca9010ecfff76d9e015ebab813e340`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T082503.852027Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T082503.852027Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.281秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T082503.852027Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T082503.852027Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T082503.852027Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\game", "--report", "D:\\31days\\codexandclaude\\runs\\20261023T082503.852027Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=633.921秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T082503.852027Z\007.txt`；SHA256=`f7a965ac45803fc4af98e487ca8744154815d1b1a5f7d51e947222295482e683`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.422秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T082503.852027Z\008.txt`；SHA256=`48072b25e14121fe84f9ad8c032c656cc5ce471c935b0027b3e42832f75027ba`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=11.375秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T082503.852027Z\009.txt`；SHA256=`835e8ed4787ad8a0dca3ffd7a77f53f7b09978a668d17cbc8b0f413694537a64`。
- 报告 `D:\31days\codexandclaude\runs\20261023T082503.852027Z\engine.txt` SHA256=`7b157ced00a31ed636a60a88093793f438569c524c10d22bf274279ca4082deb`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

## 收尾文档 G3

收尾文档写入后执行 python codexandclaude/tools/run_checks.py focused --python-all：G3 108/108 + 67/67，退出0。摘要：codexandclaude/runs/20261023T083651.103965Z/summary.json；本次验证集成记录、完成状态与BOARD链接及共同规划基线，G2证据使用上方干净、稳定的master full。
