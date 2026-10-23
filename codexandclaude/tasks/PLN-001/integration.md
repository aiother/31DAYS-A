# PLN-001 集成记录

日期：2026-10-23（America/Los_Angeles）｜集成者：Codex｜状态：已完成。

## 授权与固定合入

用户本轮明确授权：“请以复审 SHA a492cb464a8157b9a879d8a70e3bf0a824f69109 为准……合入 master，留集成记录。”本次合入在该授权之后执行。

- 合入前 master：`519a7f66814b26ef3309184c3c1aa0f7d9bfc6a7`。完整 Git 执行环境确认没有与待合入文件重叠的未提交改动，未修改或清理用户的其他文件。
- 固定合入目标／快进后的 master：`a492cb464a8157b9a879d8a70e3bf0a824f69109`；执行 `git merge --ff-only a492cb464a8157b9a879d8a70e3bf0a824f69109`，成功快进，无冲突；未合并可移动分支名。快进没有另建 merge commit，本 SHA 即集成检查的被测 SHA。
- 包含实现 `05ebf90a790f22fd636fecdaff70e4ffa10dd22b`、用户验收与 M2 关闭 `418e6ece718305019c66ebd8693cecd4faeaa20f`、首轮审查 `6236d74d835bb208271080f0addf07b86975b4cb`、R1 修复 `f222bd60061208059165e12fc548fbf6a84e595d` 与通过复审记录。
- 用户 2026-10-23 整体通关验收原话“完事了，没问题”：T7-G 的三项实机项通过，其余八项复查无异常；共 11 项通过，M2 已关闭，见 [核对表](t7g_check.md) 与 [交付记录](delivery.md)。本次入口自检不替代用户验收。
- R1 的正确前提保留：第 3 日开始时三处救助同时过期；战场郊区在第 3 日余额归零时另行过期。不改 UI-010 历史交付记录。

## master 检查

任务虽以规划文档为主，但新增了 `game/tests/acceptance/pln001_campaign.gd`，按任务卡“新增验收适配时跑全量”执行，没有只跑 G3。

- 验收入口：`Godot --headless --path game --fixed-fps 60 --script res://tests/acceptance/run_acceptance.gd -- --adapter=res://tests/acceptance/pln001_campaign.gd --self-test`，**PLN001_ACCEPTANCE_TESTS 15/0**，退出 0。使用临时目录，不读写正式存档。日志：`codexandclaude/runs/pln001-integration-adapter.txt`。
- 在 master 固定被测 SHA 上执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**G2 94/94，G3 108/108 + 67/67** 全部通过，退出 0；起止工作区干净，content_stable=True，ERROR / WARNING / ObjectDB 泄漏均 0。摘要：`codexandclaude/runs/20261023T190814.037801Z/summary.json`。未沿用实现或审查工作区的结果。

## 收尾范围

本次证据提交只新增 integration.md、将任务卡首部改为已完成，并同步 BOARD 的 PLN-001 行。ROADMAP、BOARD、BACKLOG 的汇总基线仍为 **master@519a7f6**（规划刷新时核对的基线）；不按集成证据提交 SHA 重新刷新，不改变其他任务状态或新增任务。

## 自动 full 证据

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`a492cb464a8157b9a879d8a70e3bf0a824f69109`；工作区：`D:\31days`。
工作区状态：**干净**。
开始：2026-10-23T19:08:14.038801+00:00；结束：2026-10-23T19:18:52.843462+00:00。

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

提交树：`71ad7a80e2868a7809658761e96d16bedea0413c`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`ecaf653439216c08cb9db53e9a96fa6658010858859b45341e628b80ba3c6bbc`；工作区范围指纹（原始字节）：`72e549d6d47c97fd91987e98d7edd31ec25dab48b84de22ca325a21c0ddc2b5a`。
全工作区指纹：`d5b4b484430a4783e9306207479cf856f83486653effe9fccd02c77b75c8d39a`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T190814.037801Z\001.txt`；SHA256=`754dde83244c9b0384b5b215482751a8d90453623e248441d124a7a5f2aaa95b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T190814.037801Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T190814.037801Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.265秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T190814.037801Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T190814.037801Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T190814.037801Z\006.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\game", "--report", "D:\\31days\\codexandclaude\\runs\\20261023T190814.037801Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=623.015秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T190814.037801Z\007.txt`；SHA256=`4c0cba13744662ced1ecf47c784185f307d17ec9e60864ba1d1fd03ddcb39891`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.141秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T190814.037801Z\008.txt`；SHA256=`4a7a9af3b269c80a23e792e3d58fb5b448bd8bd770123f65403195fcef3b1162`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=11.0秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T190814.037801Z\009.txt`；SHA256=`112f1aaf6df27e10f8d821eb309e94f2fb29ea193ba3c4caceb45507456878a8`。
- 报告 `D:\31days\codexandclaude\runs\20261023T190814.037801Z\engine.txt` SHA256=`26352ef7e0470442479db34da59c0f2d062fee04b60fed60d804a808cbb4e297`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
