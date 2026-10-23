# UI-009 集成记录

日期：2026-10-22（America/Los_Angeles）｜集成者：Codex｜状态：已完成。

## 授权与固定合入

用户本轮明确要求“以审查 SHA 35ef16c9d05d7e87202e5c182acf9c2f2ac1fb72 为准……合入 master 并留集成记录”，并要求核对CLN-001是否已集成。

- 合入前master：`5c745d076d2cbc2c5ae7f1d4a1de12a7cff6e773`。完整Git执行环境工作区干净，game/project.godot无未提交改动，没有与待合入文件重叠的用户改动。
- UI-009修复实现：`def1a9f89eda32cf10f8e1f2019a1c441a0273f8`；修复交付：`da577cc6c4d65eb279070de171dd4ff01800c81b`。
- 固定审查：`35ef16c9d05d7e87202e5c182acf9c2f2ac1fb72`，含实现、G4通过记录、两轮 [review.md](review.md)；复审通过、无阻断项。
- 合入前执行 `git merge-tree --write-tree HEAD 35ef16c9d05d7e87202e5c182acf9c2f2ac1fb72`，无冲突；实际以 `git merge --no-ff 35ef16c9d05d7e87202e5c182acf9c2f2ac1fb72` 合入，无冲突，没有合并可移动分支名。
- 合并提交／本次固定被测SHA：`670c831d7c46cd0b2d10504627fd2bb6485a510e`；父提交为合入前master与固定审查提交。

没有在集成阶段修改经审查的代码、测试、接口、数值、存档或输入。R1绘制记录、R2滑入/滑出途中暂停回归、N1真实在场布局用例与UI-008遗留几何断言完整保留。

G4：用户原话“G4验收完成，没问题”，两个入口都看过，见4a28f2e与 [delivery.md](delivery.md)；实现者记录日期为2026-10-23。修订只重构底色记录来源并补测试，不改变正常外观与操作，复审已接受不重做G4的理由。本次没有把自动检查称为新用户验收。

## CLN-001 集成状态复核

固定审查 `3eb00e82d49494040474877af83fc78e21423abc` 已是合入前master的祖先。它此前由合并提交 `784061769d98c615acda106c7f526f5bdd39a4ad` 合入，收尾证据提交为 `5c745d076d2cbc2c5ae7f1d4a1de12a7cff6e773`；任务卡和BOARD已完成，见 [CLN-001集成记录](../CLN-001/integration.md)。因此本次不重复合并、不重写既有历史。

本次预演和实际合并均确认UI-009与CLN-001无冲突，CLN-001提示Label清理、状态文字、查询夹具与旧断言适配保留；master全量也覆盖两项共同存在的结果。

## master 回归与收尾

在主目录D:/31days、master合并提交上执行：

`python codexandclaude/tools/run_checks.py full --jobs 4`

退出码0，G2 **93/93**，G3 **108/108 + 67/67**，全部通过；起止工作区干净、content_stable=True，ERROR / WARNING / ObjectDB泄漏均0。UI-009专项42/0，CLN-001清理专项112/0。摘要：codexandclaude/runs/20261023T050852.441628Z/summary.json。

UI-009审查分支G2为92项，合入前master还包含CLN-001独立清理套件；执行集合与计数以下方自动摘要为准，没有修改手工计数。

收尾只新增本integration.md，将UI-009任务卡首部与BOARD对应行标为已完成；CLN-001已完成状态保留。BOARD汇总基线、BACKLOG、ROADMAP与UI-010状态不改，后续规划刷新仍交Claude处理。

## master full 自动证据

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`670c831d7c46cd0b2d10504627fd2bb6485a510e`；工作区：`D:\31days`。
工作区状态：**干净**。
开始：2026-10-23T05:08:52.441628+00:00；结束：2026-10-23T05:19:20.700363+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际93 / 预期93；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`886fe311c4bb7df2f7db2528a93994fdd1041f74`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`5400e9f872e13df601e3c8d26506826b1e6aeb450ece15ccf96b6de9a5279361`；工作区范围指纹（原始字节）：`994baee9e279d2f6ad7e5d0decf850d16bea849df0839aa2cfa6ad4d2e810d35`。
全工作区指纹：`331d87718b36c1340169f66089272159e00ed8e217e6fb4b7addbda217ccac4b`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T050852.441628Z\001.txt`；SHA256=`46ac1393aa53c0b82698861e6d2d019e42d91f9d1add4519b70e7e02687b16f9`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T050852.441628Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T050852.441628Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.281秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T050852.441628Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T050852.441628Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T050852.441628Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\game", "--report", "D:\\31days\\codexandclaude\\runs\\20261023T050852.441628Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=609.906秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T050852.441628Z\007.txt`；SHA256=`210f70cc0d8d66a3134ddcac57345212cd98fb0c61a198196c1fc626227cbd32`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.234秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T050852.441628Z\008.txt`；SHA256=`a0e4395b8bbd4325c809d4d89e05fa272f4ec7ff872b6da41e2afe872832c28a`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=13.438秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T050852.441628Z\009.txt`；SHA256=`aa482837ab821249d4f92c0ba76529b8154ad59fb3a41ec5da996c49cee57ef6`。
- 报告 `D:\31days\codexandclaude\runs\20261023T050852.441628Z\engine.txt` SHA256=`cfb092f872c43b2877d061e318b8ab2b5b0784e9aa1dc9a3481407c30de62afa`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

## 收尾文档 G3

收尾文档写入后执行 python codexandclaude/tools/run_checks.py focused --python-all：退出0，G3 108/108 + 67/67。摘要：codexandclaude/runs/20261023T051952.141900Z/summary.json；本次仅验证收尾文档，G2证据使用上方干净、稳定的master full。
