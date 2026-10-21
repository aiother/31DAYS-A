# EXP-002 集成记录

日期：2026-10-20（America/Los_Angeles）｜集成者：Codex

- 用户在本会话明确授权合并固定审查 SHA `b52c50f66050dfc93b15cb1e3413287ff8f61815`；复审通过，无阻断项。
- 合并前 master 为 `c5c520a3256b7c23f6b05a58e67045ee64f29b1f`。没有已跟踪文件的未提交改动；初次非提升权限查询显示的本地 .claude/ 未跟踪目录未触碰、不纳入本次提交，与合并文件无重叠。
- 授权后执行 `git merge --no-ff b52c50f66050dfc93b15cb1e3413287ff8f61815`，得到普通合并提交 `c26853a1889795e72a0160f0d0e2757ce55f7250`。没有合并可移动分支名，无冲突；ENV-005 与 EXP-002 在 test_collaboration.py 中的改动均保留，证据工具也保留。
- 在上述 master 合并提交运行 `python codexandclaude/tools/run_checks.py full --jobs 4`，重新执行编辑器导入、主场景及全部游戏套件，没有复用旧 G2：G2 76/76，G3 102/102 + 65/65，完整且通过。原始汇总 runs/20261021T011534.577470Z/summary.json，自动证据原文见下。
- 编辑器导入后原型字体 LXGWWenKai-Regular.ttf.import 出现纯换行差异；逐文件检查 ignore-space-at-eol 差异为空后恢复。没有修改字体内容、原型实现或正式游戏。full 起始干净，但 content_stable=False，因此这次结果可作本次检查证据，不可作为未来复用来源；未掩盖或改写该标志。
- 另在同一 master 运行两个原型的真实冒烟入口：EXP-002 89/89、EXP-001 105/105，均退出0，无 ERROR/WARNING。运行命令分别为 `Godot --headless --path game --script res://prototypes/EXP-002/tests/smoke_test.gd` 和 `Godot --headless --path game --script res://prototypes/EXP-001/tests/smoke_test.gd`。Godot 路径、版本与 full 一致。
- 用户选定结果沿用交付记录：样张二，保留随天数变化和手写字体，最终战光晕减弱30%。指定字体的下载已有用户同意，来源记录仍在 fonts/README.md；合并文件 SHA256 为 `2D73EEA94AD808999D90C0000C239A84A33B09D4BC6AB6C5B8BBF1EDA8A7FC8B`，大小 25,928,940 字节，与审查一致。
- 收尾只新增本集成记录，更新任务卡首部、任务板 EXP-002 和待办 BL-110 为已完成。BL-042、BL-043、BL-046 的整行保持不变；规划汇总基线保留 master@07cb0cc，未刷新路线图或起新任务。收尾纯文档改动再运行 G3 后提交。

## full 自动证据

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`c26853a1889795e72a0160f0d0e2757ce55f7250`；工作区：`D:\31days`。
工作区状态：**干净**。
开始：2026-10-21T01:15:34.577470+00:00；结束：2026-10-21T01:28:12.563167+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际76 / 预期76；完整=True；通过=True。
- G3:tests：实际102 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际65 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`3435a1537c758ea4b55f07db9856a01184b35363`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`b91b01830ccb6b7abe374be59fc49c48d36bc196e14ce1d05604463c12f59c0a`；工作区范围指纹（原始字节）：`6715b5a86d225c278e995e955caf7bea2e4c1510b7b0d87ee955803c50bf421a`。
全工作区指纹：`6bafe7d8fe187a4f8caae92a47d6e1b88686056671f4157c8cac7821af6f236b`；运行前后内容稳定：`False`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261021T011534.577470Z\001.txt`；SHA256=`649aba660b2294d7f23d47ed77a74639f69113e7f3ef92e91c2a173a0fcb5e0d`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261021T011534.577470Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261021T011534.577470Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.297秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261021T011534.577470Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261021T011534.577470Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261021T011534.577470Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\game", "--report", "D:\\31days\\codexandclaude\\runs\\20261021T011534.577470Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=742.593秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261021T011534.577470Z\007.txt`；SHA256=`4af2fbc53bf88f31289a786edbb7feda8898ae85bd10d04d025a83025a8b4bce`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.329秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261021T011534.577470Z\008.txt`；SHA256=`1dc668de13140860da0d70ff841b19e8e93124db93e4032e1c2961d558c43bf6`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=10.656秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261021T011534.577470Z\009.txt`；SHA256=`07064a9a8cbdf3ef1fadc9e4e655974ce9e169c8b5368c711f4e41ba10e1cb0c`。
- 报告 `D:\31days\codexandclaude\runs\20261021T011534.577470Z\engine.txt` SHA256=`a1cfa92813e48bdd28e5ccd372814d4c7de131ca1379379a05513eb642c18c9e`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。


## 原型冒烟日志身份

- runs/exp002-integration-smoke.txt SHA256：`986c29ee0b022a626e46cdc479f1d1c8a3270a337c0bbcb68f9a7f4d78380bf6`。
- runs/exp002-integration-exp001-smoke.txt SHA256：`eb5ee4c71fde9eacf8af6a81913c564c208e61a7580a5b704d28fed38b4d8e68`。

## 收尾文档检查

完成状态及本集成记录写入后，在 master 重跑 `python codexandclaude/tools/run_checks.py focused --python-all`：102/102 + 65/65，完整且通过；原始汇总 runs/20261021T012909.906557Z/summary.json。被测 HEAD 仍为 c26853a，未提交改动仅为本次三处状态与 integration.md，未变更游戏或测试实现。
