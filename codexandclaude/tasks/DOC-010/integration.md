# DOC-010 集成记录

日期：2026-10-25（America/Los_Angeles）｜集成者：Codex｜状态：已完成。

## 授权与固定合入

用户本轮明确授权：“授权 Codex 把 DOC-010 合入 master（复审通过的审查提交 `206d6d7`，分支 `codex/DOC-010-review-r2`）”。本次合入在该授权之后执行。

- 合入前 master：`68e8a9993e1327a96720ad506eada8d9184cf33a`，主目录工作区干净，无未提交改动。
- 固定目标：`206d6d7ba620038b2f984b4cd8b78b4aa662b6ae`，包含实现 `3bab3d52804d653269adb7662261753a82862de8`、首次交付、首轮审查、修复 `9cfba694fbb260fee183ac4ce7791ff7cf30f240` 与记录 `91769211c752268006ada534b45c5ee84b031691`、两轮审查记录。
- 实际执行：`git merge --ff-only 206d6d7ba620038b2f984b4cd8b78b4aa662b6ae`。无冲突，master 从原 SHA 快进至固定目标；无额外合并提交，未以可移动分支名为目标。
- 合入范围为 T4 现行版、T4 对应回归断言及 DOC-010 任务记录，不涉及游戏代码。R1 的阶段顺序保留为“10救场 → 正式开战 → 最终战预算内三波协同战斗”。

## master 独立 G3

在快进后的干净 master 执行 `python codexandclaude/tools/run_checks.py focused --python-all`：G3 **111/111 + 67/67**，全部通过；起止干净，content_stable=True。按纯文档矩阵不触发 G2。摘要：`codexandclaude/runs/20261025T144457.198354Z/summary.json`。

## 收尾范围

证据提交只新增本 integration.md、更新 DOC-010 任务卡首部状态和 BOARD 的 DOC-010 行为已完成。收尾提交后另跑 G3，结果随最终回报。

BACKLOG / ROADMAP 留给规划维护者刷新，既有汇总基线保持 master@d8fb7b9；没有借本次集成修改其他规格。复审保留的非阻断 N1（预算与剩余时限用语进一步澄清）及跨文档后续事项仍见交付 / 审查记录，本次不扩范围。

## G3 自动证据

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`focused`。
被测SHA：`206d6d7ba620038b2f984b4cd8b78b4aa662b6ae`；工作区：`D:\31days`。
工作区状态：**干净**。
开始：2026-10-25T14:44:57.198354+00:00；结束：2026-10-25T14:45:14.162620+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\tools\\run_checks.py", "focused", "--python-all"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G3:tests：实际111 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`3f53ee475dd446c807ba9f8debc09aea6a37211a`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`bea448339a65fd5f70075f6bb1f9d423e7c29afda42022bcc741c3e77e8345ef`；工作区范围指纹（原始字节）：`bca2ef2191f1c59b00bf7e2c0082abb27d403374e9b07881fbbc68ec34b61792`。
全工作区指纹：`ec73a991d7aea0478b6f6d885b01cc6e3ee8eacce31c6e574668ed159300cb9e`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T144457.198354Z\001.txt`；SHA256=`41f1ec435a30378a065982296bb26cd7f69e3ad04a3113cd19b60fb308b26a70`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T144457.198354Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.328秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T144457.198354Z\003.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T144457.198354Z\004.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.0秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T144457.198354Z\005.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.266秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T144457.198354Z\006.txt`；SHA256=`e0e8875a7e817de0ea976c999be053ac232c660305197ecf6f4fecc1553b1dd6`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=11.984秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T144457.198354Z\007.txt`；SHA256=`2904141b67fe920fe69acf08cd34a0bc0b5c47799b7714cc58dacf58a42e3d3f`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
