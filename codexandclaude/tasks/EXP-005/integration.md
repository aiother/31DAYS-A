# EXP-005 集成记录

日期：2026-10-23（America/Los_Angeles）｜集成者：Codex｜状态：已完成。

## 用户授权与固定合入

用户本轮明确授权“请以复审 SHA 96badc20691ee8949d565625f4c27f3c7faa6112 为准……合入 master，留集成记录”。本次合并在该授权之后执行。

- 合入前 master：`5ad17cfd62ccdac37d101361b218c7503d6844d4`，PLN-001 已集成并完成，未重复合并。完整 Git 执行环境确认工作区干净，没有与待合入文件重叠的用户改动。
- 固定复审目标：`96badc20691ee8949d565625f4c27f3c7faa6112`，含首次交付、用户三轮反馈与定稿 `88b7da4`、修复 `5963898`、证据与更正 `93dc4d2`、两轮审查记录。
- `git merge-tree --write-tree HEAD 96badc20691ee8949d565625f4c27f3c7faa6112` 无冲突；执行 `git merge --no-ff 96badc20691ee8949d565625f4c27f3c7faa6112`（提交说明通过文件传入），没有合并可移动分支名。
- 合并提交／本次被测 SHA：`bcb03c011688c792193c29d7f355a514f27c16a3`；两个父提交分别为合入前 master 与固定复审目标。
- 核对合入前 master 到该合并提交的增量：仅 `game/prototypes/EXP-005/` 和本任务 task/delivery/review；排除两目录后 diff 为空。没有覆盖 PLN-001 的 ROADMAP、BOARD、BACKLOG、验收适配或集成记录，也未改正式场景、输入映射、存档、共享脚本或验证流水线。

## 用户定稿与审查

用户 2026-10-23 选定风格 **D 融合**、普通攻击顿帧 **0.10 秒**、普通命中不震、受击轻震 5 像素。三轮反馈原话与定稿见 [delivery.md](delivery.md)；两轮审查见 [review.md](review.md)，R1～R3 复审通过，无阻断项。

本次不修改已选外观、手感、按键与特效规则；原型的模拟顿帧不等同于正式玩法变更，正式化仍须另立任务并评估时钟与判定。

## master 独立检查

新增 Godot 原型脚本会进入编辑器导入，按任务卡跑 full，不只跑 G3。

- 冒烟：`Godot --headless --path game --fixed-fps 60 --script res://prototypes/EXP-005/tests/smoke_test.gd`，**EXP005_SMOKE_TESTS 297/0**，退出 0。日志 `codexandclaude/runs/exp005-integration-smoke.txt`，SHA256 `a0effd0dbe268851f132a93a9213c356ae8457ea7d488c327d6ca3a5c1c92d50`。不把 headless 帧时间当作渲染性能。
- 在 master 合并提交执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**G2 94/94，G3 108/108 + 67/67** 全部通过，退出 0；起止工作区干净、content_stable=True，ERROR / WARNING / ObjectDB 泄漏均 0。摘要 `codexandclaude/runs/20261023T192206.729934Z/summary.json`。没有沿用实现方或审查工作区证据。

## 收尾范围

新增本集成记录，任务卡首部与 BOARD 的 EXP-005 行改为已完成（用户定稿、审查与 master 检查通过）。PLN-001 已完成状态完整保留；ROADMAP、BOARD、BACKLOG 的规划汇总基线保留 master@519a7f6；不刷新其他任务状态、不将 BL-065 的正式特效工作误标完成，不开新任务。

## 自动 full 证据

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`bcb03c011688c792193c29d7f355a514f27c16a3`；工作区：`D:\31days`。
工作区状态：**干净**。
开始：2026-10-23T19:22:06.729934+00:00；结束：2026-10-23T19:32:43.676394+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际94 / 预期94；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`efba40e3945ce62a548da24207c6bea19585472b`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`63536f7363a1d0e76e9680facd5de74381ea63405640b917910f8a8ff6f8b615`；工作区范围指纹（原始字节）：`3fb5ae4f434393f3390dff20b72765af1c6f05d5214c3c5899c5fcbfd3df5b9c`。
全工作区指纹：`4055e6116c00de070e64d1bc79a7a9ae148eecf416da857f313ec90bf86178ae`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T192206.729934Z\001.txt`；SHA256=`5536fe5dd90b61985765d8c1cd7eebce6a59b4a625951a8c3d606e76bb114574`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.297秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T192206.729934Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T192206.729934Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.281秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T192206.729934Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T192206.729934Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T192206.729934Z\006.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\game", "--report", "D:\\31days\\codexandclaude\\runs\\20261023T192206.729934Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=620.687秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T192206.729934Z\007.txt`；SHA256=`c16fb4a6fd385b28c78738efa03a161bd4fc332e71129f548deba57e8a56cc4b`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.25秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T192206.729934Z\008.txt`；SHA256=`14dc2b30c561485160086c22b6a549d07328f77f2c299baff9e2cb215564ea18`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=11.156秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T192206.729934Z\009.txt`；SHA256=`90a0300c8c9ff1e6e37d728393102a5a9324aaa59e4f5b1a8547ba77a24badf1`。
- 报告 `D:\31days\codexandclaude\runs\20261023T192206.729934Z\engine.txt` SHA256=`7194953dfe636883007c8ea78ade09293bc0ef3e0e3550bb3d42720437921275`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
