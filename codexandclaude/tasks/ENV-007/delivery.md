# ENV-007 交付记录

日期：2026-10-21（America/Los_Angeles；自动摘要使用 UTC）。
基线：`2f79b8311155826301509c0cb6c26691f4a1e2c9`。
分支：`codex/ENV-007`；实现 SHA：`e431492b3d50be19cfc2192a12a7107cacd72252`。

## 改动与边界

- 编辑器生成并入库 EXP-003 的 `tests/capture.gd.uid`、`tests/smoke_test.gd.uid`。逐项比较 Git 跟踪的全部 `game/**/*.gd` 与 `.gd.uid`：缺失只有这两项；新增回归检查要求 UID 本身也入库，不能被本地导入生成的未跟踪文件掩盖。
- G2 在扫描登记前检查 `game/tests/` 下非 `test_*.gd` 文件：有登记头或直接 `extends SceneTree` 的套件报告原始路径并失败；接受 BOM、注释和子目录。`tests/acceptance/` 启动器与合法辅助类保持豁免；现有 pursuit_survey 辅助基类不误报。不能静默丢掉改名后仍带登记头或 SceneTree 入口的套件。
- 提交顺序按 timeout 降序、同 timeout 按路径；报告仍按路径，编辑器导入与主场景检查仍先行。未改 timeout、判定、证据格式、复用规则或游戏代码。
- 只修改 verify_game.py、test_verification_runner.py、两项 UID 与本任务首部；交付另增本记录。未刷新并行维护的 BOARD/BACKLOG。

## 测试与变异

`python -m unittest discover -s tests -p test_verification_runner.py -v`：先写回归，旧实现 24 项中失败 6 项（含子用例）；实现后 24/24。六项新增测试覆盖改名登记、SceneTree/BOM/注释、全部改名无剩余标准套件、辅助与验收豁免、真实执行器提交顺序与路径报告、全部跟踪脚本的跟踪 UID。

- 去掉改名拒绝：24 项中失败 4 项，退出 1。
- 改回路径调度：24 项中失败 1 项，退出 1。
- 两项变异均在检查后恢复原始字节。
- 实现前 G3 108/108 + 67/67；新增的六项使第一组从 102 增为 108。
- 同一干净实现提交连续两次 `python codexandclaude/tools/run_checks.py full --jobs 4`，均 G2 88/88、G3 108/108 + 67/67、起止干净、content_stable=True。两次之间未改被测内容；耗时分别 652.527 秒与 658.140 秒。无错误、泄漏、超时。
- 原始日志在忽略目录 runs/env007-{red,green,mutant-rename_guard,mutant-path_schedule}.txt 与两个完整运行目录。

两次运行可作为 ENV-005 保守比较的来源；后续仍须比较目标内容、工具与命令。只改记录时也必须重跑 G3，不能直接宣称任何工作区均可复用。本任务无 G4；交 Claude 审查，尚未合入 master。交付记录和首部修改后另跑 G3。

## 自动摘要：第一次 full

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`e431492b3d50be19cfc2192a12a7107cacd72252`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-22T06:13:37.964431+00:00；结束：2026-10-22T06:24:30.490990+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际88 / 预期88；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`e09ffdd12dd464b5d8216ec898280356db9ee0bb`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`790c84bfceb290340b63b91ed33974cd8aa1fecb381c81c6ad76935bec29a660`；工作区范围指纹（原始字节）：`425853256a5a4667bf0fb5e6121dd6374ccea3f8f02324fc7c35b90d3454aa73`。
全工作区指纹：`491608cb88480b90c8bf8825f0b384bb059f87767fba3910ab44384a1269b3b2`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T061337.964431Z\001.txt`；SHA256=`5dbd604bd210cef89d7aa567b95ae15860f60edd84799d2611a45dfab63e531a`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T061337.964431Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T061337.964431Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.281秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T061337.964431Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T061337.964431Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T061337.964431Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\codex\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\20261022T061337.964431Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=635.422秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T061337.964431Z\007.txt`；SHA256=`043ace6c4c57031ebfba12ad6aaf7d09fe895befd79765c038e9faa9b1df76c4`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.563秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T061337.964431Z\008.txt`；SHA256=`270b4bd0cf68767e30fb1985df91ff9c5620e4196c8e34b0f278f9a8a841d88b`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=12.078秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T061337.964431Z\009.txt`；SHA256=`3235ade17df39410b251a77e854fde62622f41b44620337c583eafe4ff46bd60`。
- 报告 `D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T061337.964431Z\engine.txt` SHA256=`cf8cb7c44ce573927731d9fc261d46f5dc7424c848ece90a5e599b76edf12b09`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。


## 自动摘要：第二次 full

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`e431492b3d50be19cfc2192a12a7107cacd72252`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-22T06:25:46.195857+00:00；结束：2026-10-22T06:36:44.334901+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际88 / 预期88；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`e09ffdd12dd464b5d8216ec898280356db9ee0bb`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`790c84bfceb290340b63b91ed33974cd8aa1fecb381c81c6ad76935bec29a660`；工作区范围指纹（原始字节）：`425853256a5a4667bf0fb5e6121dd6374ccea3f8f02324fc7c35b90d3454aa73`。
全工作区指纹：`491608cb88480b90c8bf8825f0b384bb059f87767fba3910ab44384a1269b3b2`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T062546.194818Z\001.txt`；SHA256=`5dbd604bd210cef89d7aa567b95ae15860f60edd84799d2611a45dfab63e531a`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T062546.194818Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T062546.194818Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.328秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T062546.194818Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T062546.194818Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T062546.194818Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\codex\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\20261022T062546.194818Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=642.266秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T062546.194818Z\007.txt`；SHA256=`9b061ea944348636676e48c3537858c834b55c2110332cbb92cb6f577ca91821`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.281秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T062546.194818Z\008.txt`；SHA256=`cb1cc7b79ec558daa87157eedf080167a5bbd7fd2d4c26cd5ec27af51ec06d30`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=11.0秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T062546.194818Z\009.txt`；SHA256=`590fa3a84ab7bad0ee3491b713110cce57e78fbdb55f5f2d8e8a44e9df7a4aff`。
- 报告 `D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T062546.194818Z\engine.txt` SHA256=`48091ce0db442fa5266cc53231eb28836e48e9ca429d22614e5eddeee80487cc`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

