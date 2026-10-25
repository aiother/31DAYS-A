# DOC-009 集成记录

日期：2026-10-24（America/Los_Angeles）｜集成者：Codex｜状态：已完成。

## 用户授权与固定合入

用户本轮明确“用户授权合入 DOC-009”，指定固定复审 SHA `752f5af5f72d9d77a41ee41c9fa4b12e9ccfbf99`，并要求 BOARD 标注第九批完成。本次合入在该授权之后执行。

- 合入前 master：`be316606abca06a33d87bcf7d324eeeabacce585`，主目录工作区干净，无待合入文件重叠的未提交改动。FX-001 与 SYS-011 已完成联合 full 与收尾。
- 固定目标：`752f5af5f72d9d77a41ee41c9fa4b12e9ccfbf99`，包括实现 `4c685be7021554009c31ae081b2ba948ca5430cf`、首次交付、首轮审查 `03120dd3e718fd03b4c5de214b1fa61de1f5b63b`、修复 `e62365ba86e99d7a60032e94a73d92d0ac8cbe7a` 与记录 `c7a99610f062bf9fca1cacdac4c8a5d33cc22bdc`、两轮审查记录。
- `git merge-tree --write-tree be316606abca06a33d87bcf7d324eeeabacce585 752f5af5f72d9d77a41ee41c9fa4b12e9ccfbf99` 无冲突（树 `841a8c57186fc4317c9fca5122de8adf0e84676b`）。实际执行 `git merge --no-ff 752f5af5f72d9d77a41ee41c9fa4b12e9ccfbf99 -F <说明文件>`，未合并可移动分支名。
- 合并提交／被测 SHA：`e163e587e14a1d964a2c2f0af685d95b7e555553`；父提交为上述原 master 和固定复审目标。
- Git 自动合并 `tests/test_planning_documents.py`，确认 FX-001 的 T2 §14 顿帧/震屏断言与 DOC-009 的 T3 现行版/注视时点断言均保留；无手工修改实现或断言。

## 集成内容与边界

本次新增改动范围为 T3 现行版、T1 两处 T2 引用、相应文档回归断言与任务记录。首见 N002 只补满可能性，麦秆镇救助后返7在 N005 获得注视的澄清随 R1 修复保留；数值、旧槽保护、救助互斥、事务回滚、药包、死亡与超时等条款以两轮审查记录为据。

交付列出的跨文档不一致（T4/T5.4 仍写“自然日期不会判NPC失救”等，以及其他后续改写事项）保留给后续文档任务，本次不修改对应文件。首轮非阻断 N1（T1 历史引用的定点测试建议）继续作为建议保留，不影响复审通过。

## master 独立 G3

在合并提交的干净主目录执行 `python codexandclaude/tools/run_checks.py focused --python-all`：**tests 110/110、codexandclaude/tests 67/67，全部通过**，退出 0，起止干净，**content_stable=True**。摘要 `codexandclaude/runs/20261025T062509.586115Z/summary.json`。本次按纯文档矩阵执行 G3。

## 第九批收尾

证据提交只新增本 integration.md、把 DOC-009 任务卡首部和 BOARD 的 DOC-009 行改为已完成，并在 BOARD 明确第九批 FX-001、SYS-011、DOC-009 三张卡全部完成。已有 FX-001 / SYS-011 的状态和证据保留。

BOARD 的汇总基线仍为 master@519a7f6；本次是集成收尾，BACKLOG / ROADMAP 的全面刷新留给规划维护者。收尾文件另跑 G3，通过后提交。

## G3 自动证据

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`focused`。
被测SHA：`e163e587e14a1d964a2c2f0af685d95b7e555553`；工作区：`D:\31days`。
工作区状态：**干净**。
开始：2026-10-25T06:25:09.586115+00:00；结束：2026-10-25T06:25:25.251787+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\tools\\run_checks.py", "focused", "--python-all"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G3:tests：实际110 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`841a8c57186fc4317c9fca5122de8adf0e84676b`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`921ec463fb73f6a7bf3eba2f57886d6a834047c2041f7948c334c7b6078110f3`；工作区范围指纹（原始字节）：`e42f810c37a6bcc96c7439325e99326336d9e8e0c9b0fea7a572021aa46f59c6`。
全工作区指纹：`46e71fa8a36be8678501816f27049c84fb7dd4f3d2fd68be2114becbd797e280`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T062509.586115Z\001.txt`；SHA256=`5b1c3a268f310dd0d928a4c27e34fcd9504684d6ccd53968db0aa4d5e5c84382`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T062509.586115Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.329秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T062509.586115Z\003.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T062509.586115Z\004.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T062509.586115Z\005.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.297秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T062509.586115Z\006.txt`；SHA256=`bc877409c3c0b834a2f0e6692dc0fe15f30135d307a53d006378a31bcca53d81`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=10.734秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261025T062509.586115Z\007.txt`；SHA256=`342dc630c57f31af4bd40632b0bc598c5cca9e9c363839afd02ee8b28e4920a4`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
