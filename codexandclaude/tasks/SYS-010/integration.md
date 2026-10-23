# SYS-010 集成记录

日期：2026-10-23（America/Los_Angeles）｜集成者：Codex｜状态：已完成。

## 用户授权与固定合入

用户本轮明确“用户 G4 通过，授权合入 SYS-010”，并指定 Claude 固定复审 SHA `0db83543e52ce57d903039b3a465e6bb9ba8062f`。本次合入在该授权之后执行。

- 合入前 master：`c60f2aeb9af10539bfd829d98207a683630a7e31`，工作区干净，无与待合入文件重叠的用户改动。PLN-001、EXP-005 已完成，状态与记录保留。
- 固定合入目标：`0db83543e52ce57d903039b3a465e6bb9ba8062f`，包括修订实现 `bee6026ecfe46d8997421670c894af50112bf389`、交付 `72899f021df32dda96b1075fe24ad49afa8a9690`、两轮审查和用户 G4 记录。
- 预演 `git merge-tree --write-tree HEAD 0db83543e52ce57d903039b3a465e6bb9ba8062f` 无冲突；实际执行 `git merge --no-ff 0db83543e52ce57d903039b3a465e6bb9ba8062f`，说明通过文件传入，未合并可移动分支名。
- 合并提交／本次被测 SHA：`e6d47c289a10ccb6e05e78d3097ea3f71aa8d234`；父提交为上述合入前 master 与固定复审目标。
- 不在集成时改动画框架、游戏规则、数值、输入、存档或验收入口；映射细分优先、轻/重对应、按进度 seek、还原视觉、属性/路径白名单等修复回归随审查目标保留。

## 用户 G4 与非阻断观察

G4 已于 2026-10-23 通过。用户原话：“这两点不影响动画验收，SYS-010 的 G4 算通过。”详细记录见 [review.md](review.md) 的 G4 节，本次不以自检替代用户验收。

两处均限于无存档验收入口 `sys010_animation.gd`，用户接受为非阻断：

1. 开局/F6 直写余额为 10，不发 balance_changed，旧占位视觉缓存仍为默认 3，首次闪避到 9 被误看成余额增加，出现绿色获得光圈。
2. 使用的 movement_lab 没有打开玩家 Hurtbox，敌人打不到玩家；F4 直接调用受击可工作。审查已确认 master 原实验室同样，不是动画框架引入。

本次按用户决定原样记录，不顺手修入口；后续复用时可采用会发信号的余额接口并打开受击区，另行处理。

## master 独立检查

- 验收入口自检：`Godot --headless --path game --fixed-fps 60 --script res://tests/acceptance/sys010_animation.gd -- --self-test`，**SYS010_ACCEPTANCE_TESTS 4/0**，退出 0；无存档实验室，不读写正式玩家存档。日志 `codexandclaude/runs/sys010-integration-acceptance.txt`，SHA256 `1a6428379dac42b5815fba63fa5dddce6803ae76365776f858b7e3a25d071505`。
- master 合并提交执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**G2 95/95，G3 108/108 + 67/67** 全部通过，退出 0；动画专项 **100/0**。起止工作区干净、content_stable=True，ERROR / WARNING / ObjectDB 泄漏均 0。摘要 `codexandclaude/runs/20261023T195052.857098Z/summary.json`。未沿用交付或复审工作区的结果。

## 收尾范围

证据提交只新增本 integration.md、把 SYS-010 任务卡首部与 BOARD 的 SYS-010 行改为已完成。交付中当时“G4 待进行”的过程记录保留，本记录与审查 G4 节给出最终状态。不修改其他任务，DOC-008 仍在修订审查流程，不合入其分支。三份规划文档的汇总基线仍为 master@519a7f6，后续 ROADMAP/BACKLOG 批次刷新留给规划维护者。

## 自动 full 证据

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`e6d47c289a10ccb6e05e78d3097ea3f71aa8d234`；工作区：`D:\31days`。
工作区状态：**干净**。
开始：2026-10-23T19:50:52.857098+00:00；结束：2026-10-23T20:01:49.559395+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际95 / 预期95；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`77c41c494f728a998a0a5548465656cc4250d29d`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`19f956266a7ab95f5dd37eb59ed7ca0620c6a10cbc95a67982e129377a849593`；工作区范围指纹（原始字节）：`8eee2087d8370331946a864ff913b63d3ff7178bc2fa2831d0c61140f0a59e9b`。
全工作区指纹：`0559a48be5d437db6d8f7047c8e73fc0657da1781d65c5b29aeae2c6dd8b44a1`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T195052.857098Z\001.txt`；SHA256=`3003e93c996efa77ca90d0b46d9eb8774644111fc505cea87eb0fe53ff1ad915`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T195052.857098Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T195052.857098Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.281秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T195052.857098Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T195052.857098Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T195052.857098Z\006.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\game", "--report", "D:\\31days\\codexandclaude\\runs\\20261023T195052.857098Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=641.235秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T195052.857098Z\007.txt`；SHA256=`7255e4d7ca294a45c53152af38e6879b51d4065b8fe6aa4066eaef7fb895af09`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.125秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T195052.857098Z\008.txt`；SHA256=`68416e53f1955c7cc04e1c27cdddf334c5afda38616956a3d4a740e4a6d97aca`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=10.719秒；超时=False；日志=`D:\31days\codexandclaude\runs\20261023T195052.857098Z\009.txt`；SHA256=`04f338ee8e6d3c717686530921e27498b7bdbc2fd8df135144b66c4ec6aa9838`。
- 报告 `D:\31days\codexandclaude\runs\20261023T195052.857098Z\engine.txt` SHA256=`4797e3a84a5901e5dba4f4356d442860790336b72d6d4c5439da6bf78aa011b5`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
