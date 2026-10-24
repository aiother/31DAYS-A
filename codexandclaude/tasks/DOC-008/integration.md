# DOC-008 集成记录

日期：2026-10-23（America/Los_Angeles）｜集成者：Codex｜状态：已完成。

## 用户授权与固定合入

用户本轮明确授权“请以复审 SHA ff791c9b2c15b6f3115686da603fe2b1d73609a9 为准……合入 master，留集成记录”。本次合并在该授权后执行。

- 合入前 master：`31ca0e98d3286ccb46cd251e77c81e82a0c20168`，工作区干净，没有与待合入文件重叠的用户改动。
- 固定合入目标：`ff791c9b2c15b6f3115686da603fe2b1d73609a9`。包含实现 `7abae7a6673fa220fd3ea4dc05444f167cc63822`、首次交付 `8726ab4e3b5fad1b26a881f1933a607376c9251b`、首轮审查 `74d3887897bc0585af446e6e5f275bc865f0daf1`、修复 `6aed673302425a252437f267833968c953854fb1`、记录 `5823fe51567326eee672ed9c9d8705fbca238dd0` 与两轮审查历史，最新结论通过。
- 预演 `git merge-tree --write-tree HEAD ff791c9b2c15b6f3115686da603fe2b1d73609a9` 无冲突；实际执行 `git merge --no-ff ff791c9b2c15b6f3115686da603fe2b1d73609a9`，说明由文件传入，未合并可移动分支名。
- 合并提交／本次被测 SHA：`1a88afc203a7fccce1e5febb667aba2ad85b3686`；父提交分别为上述合入前 master 与固定复审目标。
- 合并增量仅 T2、tests/test_planning_documents.py 的 T2 断言与本任务记录。`git diff 31ca0e9 1a88afc -- game` 为空；SYS-010 的实现、测试、G4 与集成记录完整保留，没有改动其他规格或游戏代码。

## 复审结论与范围

R1 的旧档成长兼容及领取状态约束、R2 的追击活动路线暂停/超时规则均已补齐；自查补回的三处约束也已通过复审。现行数值不变，未改变玩法、存档或输入。详细核对与七项独立变异见 [review.md](review.md)。

用户要求留给后续文档任务的清单仍保存在 [delivery.md](delivery.md)“跨文档不一致清单”，本次明确交接：

- T1 §4.2 / §9 按旧标题引用 T2，后续改成现行章节引用时同步适配依赖旧措辞的测试。
- T5.4 §7 的救场未决旧话、§6.3 的“威胁单位”旧对比，留 T5 系列现行化处理。
- T5.3 重复旧 10 数值与阶段协同战记录，后续依较新已确认修订整理。

这些并非本次改变规则或扩大修改范围的依据。既有待办 BL-025 已覆盖 T5 系列现行化；其余清单继续由本任务交付和本集成记录交接，未新建重复 BACKLOG 条目，未在本次修改 T1/T5 或其他任务。

## master 检查与收尾

按纯文档矩阵，在 master 合并提交执行：

`python codexandclaude/tools/run_checks.py focused --python-all`

**G3 109/109 + 67/67 通过**，退出 0；起止工作区干净、content_stable=True。摘要 `codexandclaude/runs/20261024T062033.291365Z/summary.json`（UTC 日期 10-24，对应 America/Los_Angeles 为 10-23）。未复用实现方或复审工作区摘要，未要求 G2。

收尾只新增本 integration.md，任务卡首部与 BOARD 的 DOC-008 行标为已完成。PLN-001、EXP-005、SYS-010 的完成状态保留。第八批四张任务卡至此均已完成；ROADMAP / BACKLOG 的批次刷新留给规划维护者，三份规划文档汇总基线仍为 master@519a7f6。

## 自动 G3 证据

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`focused`。
被测SHA：`1a88afc203a7fccce1e5febb667aba2ad85b3686`；工作区：`D:\31days`。
工作区状态：**干净**。
开始：2026-10-24T06:20:33.291365+00:00；结束：2026-10-24T06:20:49.195323+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\tools\\run_checks.py", "focused", "--python-all"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G3:tests：实际109 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`21138e915b94d414732f0b6a9bff60a84bbaa37c`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`6c31950128c348154061a4a99f00a8e2c80cfade24de85564cd3a802cbbc5cce`；工作区范围指纹（原始字节）：`6e1aab6e6ceebb0a73a491b17f480536532d925aed127c7308a9e1c34242265c`。
全工作区指纹：`cb86a71a72ab84e7cc326f940d420abcbe355468713e6f994ceb0b78c993c8bc`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261024T062033.291365Z\001.txt`；SHA256=`1368475b27d87255373ef9d348b7422ef4aa0d5bba465c5aeefc9e97f3eb411b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261024T062033.291365Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.281秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261024T062033.291365Z\003.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261024T062033.291365Z\004.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261024T062033.291365Z\005.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.204秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261024T062033.291365Z\006.txt`；SHA256=`204483de6ec13e38ecef8e6c44eabd8ba39f79ba1057935b42aa747c4175d4a8`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=11.0秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261024T062033.291365Z\007.txt`；SHA256=`b2abfe43798c7f48a68eb3eafaa1e9cc3b91c5a9bdbe82d4f970910cdcfca179`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
