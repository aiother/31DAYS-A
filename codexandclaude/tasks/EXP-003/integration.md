# EXP-003 集成记录

日期：2026-10-21（UTC）｜集成者：Codex。

## 授权与固定合入

用户原话：“同意合入 EXP-003。” 本轮明确要求固定合入复审 SHA，合入后 G3、原型冒烟、任务卡完成状态与本记录；遇冲突或失败停止。

- 合并前 master：`c6a8f937d504b80783b1d917764c3e5352cde4ca`。
- 固定目标 / 快进后的 master：`49fe5847c19613f144f0564c74f98f2917e18c0d`，它是交付 `d27c9d0c2ccaeac1028cb8ca12538290d202761e` 的直接后继，包含原型、R1修正、用户选择和两轮审查文字。
- 执行 `git merge --ff-only 49fe5847c19613f144f0564c74f98f2917e18c0d`，无冲突，没有合并可移动分支名，没有另造合并提交。
- 用户选定：主界面 A · 黄昏远景；存档选择1 · 书签，加方案2的天空条。组合供后续正式任务实现。

## 合入后检查

主目录存在用户未提交的 game/project.godot，与目标文件无重叠；未恢复、暂存或提交该文件。合并前后 SHA256 均为 `8246aab2ebfa4f7445c53e79d918f81943137fca37d75c36bed57e5855f77aa5`。Claude 工作区的未提交 run_preview.cmd 空行及其 stash 未操作。

为避免用户配置混入结果，在 Codex 自己工作区 `D:/31days/codexandclaude/worktrees/codex` 固定上述合入后 master SHA，使用干净的同提交内容运行检查，而非主目录的用户修改版本。

- 编辑器导入准备：Godot --headless --path game --editor --import，退出0，无 ERROR/WARNING。仅移除本次导入生成且未被跟踪的 capture.gd.uid、smoke_test.gd.uid；没有提交资源或源码变更。
- G3：`python codexandclaude/tools/run_checks.py focused --python-all`，102/102 + 67/67 完整通过，退出0；起止干净，content_stable=True。摘要 `worktrees/codex/codexandclaude/runs/20261021T130600.790914Z/summary.json`。
- 冒烟：`Godot --headless --path game --script res://prototypes/EXP-003/tests/smoke_test.gd`，预期/实际 `EXP003_SMOKE checks=45 failures=0`，退出0，无 ERROR/WARNING。原始日志在上述工作区的 runs/exp003-integration-smoke.txt。
- 本次按探索型原型矩阵执行，无需G2。未把审查时的检查当成本轮合入后证据。

收尾仅新增本记录并更新任务卡首部为已完成；BOARD/BACKLOG/ROADMAP 留给规划维护者刷新。记录写入后再跑G3通过才提交。未合并UI-003或SYS-007，也未开新任务。

## G3 自动证据

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`focused`。
被测SHA：`49fe5847c19613f144f0564c74f98f2917e18c0d`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-21T13:06:00.791437+00:00；结束：2026-10-21T13:06:18.788927+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "focused", "--python-all"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G3:tests：实际102 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`3e2f8bc3170d7ebd3b55c6ef9330a1ef999a00bf`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`2d1ac21642569f01d5d67425ed240e744001075a3d56599e00a64d511870e02d`；工作区范围指纹（原始字节）：`0bf00a28ef5147a4d871e12cc0e41502ad6b593f6afaa11717f084a624976a7c`。
全工作区指纹：`47a3bb608c7d5603f4f15bae91e971b603008b65d2f699bf4ad171346fcbb170`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T130600.790914Z\001.txt`；SHA256=`d0744824fa2b9a38f884af732d2f1d0c26aaf3b9f52be48c88997368a0d0e089`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T130600.790914Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.36秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T130600.790914Z\003.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T130600.790914Z\004.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T130600.790914Z\005.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.719秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T130600.790914Z\006.txt`；SHA256=`d5c5db3414e2e98cd91a1fd5765f9750754bebeee4f96d59bc65e09cdda57795`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=12.656秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261021T130600.790914Z\007.txt`；SHA256=`5476418c43d31ce7b855652f74575c5f3a70d0d603bca2a7cae693435d5a52ec`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
