# ENV-007 集成记录

日期：2026-10-22（America/Los_Angeles）｜集成者：Codex｜状态：已完成。

## 授权与固定提交

用户本轮明确授权：“ENV-007 与 SYS-009 审查均通过，无阻断项，请合入 master。”按要求两项合入后执行一次完整检查，非阻断建议不在本次处理。

- 合入前 master：`2f79b8311155826301509c0cb6c26691f4a1e2c9`，主目录工作区干净，game/project.godot 无未提交改动。
- 固定交付：`b9b6d1304347f8950f28b47909c79bda186805a0`。
- 固定审查：`2349e3c0872907bb7ce79b91bba5525c6c95b515`；核对审查提交仅比交付新增本任务 [review.md](review.md)，结论通过。
- 先以 git merge --ff-only 合入固定审查 SHA，master 快进至 2349e3c0872907bb7ce79b91bba5525c6c95b515。随后合入 SYS-009。
- 两项合入后的 master（被测合并 SHA）：`d253920175cc471f09239de38c6ea4c80a433cdc`；其父提交为 ENV-007 审查 `2349e3c0872907bb7ce79b91bba5525c6c95b515` 与 SYS-009 审查 `58d34c06438e386dec8ce33ba3b208b08e02e13f`。

全部使用固定 SHA，不合并可移动分支名；未采用 Claude 临时预演提交 14982a5。没有修改经审查的实现、测试或判定，也未使用预演结果替代本次 master 检查。

## master 检查与收尾

在主目录 `D:/31days`、master 固定被测 SHA、起始与结束均干净运行：

`python codexandclaude/tools/run_checks.py full --jobs 4`

退出0，G2 **89/89**，G3 **108/108 + 67/67**，**content_stable=True**；engine.txt 中 ObjectDB 泄漏 **0** 处，严格门禁未发现错误、泄漏或超时。ENV-007 两项 UID 入库后，本主目录导入不再生成未跟踪 UID。工具、命令、指纹和日志 SHA256 见下方自动摘要；原始运行目录为主目录 `codexandclaude/runs/20261022T074746.290445Z/`（不入库）。

本次仅补两份集成记录，将两项任务卡首部与 BOARD 对应两行改为已完成；BACKLOG、ROADMAP 和协作规范交规划维护者后续刷新。收尾修改后，提交前另跑 `python codexandclaude/tools/run_checks.py focused --python-all`，不得以完整检查前的记录版本代替文档关卡。

新增 GDScript 连同编辑器生成 .uid 提交的规范建议留给后续规划，本次不改协作规范。

content_stable=True 仅说明这次运行内容稳定，未来复用仍须按 ENV-005 比较具体目标、工具和命令；只改记录也必须重跑 G3。没有跳过本次用户要求的 master full。

## 自动证据（两项共享同一次 master full）

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`d253920175cc471f09239de38c6ea4c80a433cdc`；工作区：`D:\31days`。
工作区状态：**干净**。
开始：2026-10-22T07:47:46.290445+00:00；结束：2026-10-22T07:58:12.368520+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际89 / 预期89；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`d5c4b1172ae4ce21f52fbda2408b139295e53732`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`9e11481525110fc6a65b11b4ab0e401b73aa1a7266884f1b3da739bbf0991254`；工作区范围指纹（原始字节）：`fd86879416331bf629a5083bc1ec234ea972f7c9990a54f7f5da859ff5ec6f6d`。
全工作区指纹：`3d8e7b9014597425a1eb7348e108d895cf65fc45c568c19891988f5ffd271a1c`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261022T074746.290445Z\001.txt`；SHA256=`74eab6b8ada9dba6034a2753f2720e18d16553a64e52b6449dd57c270456f456`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261022T074746.290445Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261022T074746.290445Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.266秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261022T074746.290445Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261022T074746.290445Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261022T074746.290445Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\game", "--report", "D:\\31days\\codexandclaude\\runs\\20261022T074746.290445Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=610.391秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261022T074746.290445Z\007.txt`；SHA256=`fcdd60a844155c7bfc58b10613a215f11ea1adc1076cb2d256a012ac92086ec9`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.14秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261022T074746.290445Z\008.txt`；SHA256=`45c437ab8e733c4833946107c6383f27b2f4a5682de5b06c27b921b0f0f129b9`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=10.891秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261022T074746.290445Z\009.txt`；SHA256=`691fb65085ae756b613a97eeb1cf98c6f4363379406ea34a681a5015540ed679`。
- 报告 `D:\31days\codexandclaude\runs\20261022T074746.290445Z\engine.txt` SHA256=`91bdf457253d874b6d8f0c1bad7af62b11ab035c1d8db34889a4f0a9252f3f6c`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
