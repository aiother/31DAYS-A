# EXP-004 交付记录

实现者：Claude｜审查者：Codex｜分支：`claude/EXP-004`
基线：`5c73dfcef60efe0a14e6e126ab2af940cf6968ad`（第六批规划批准提交，`claude/batch6-cards`；其下为 master `2183e77`）。规划尚待 Codex 合入；本任务只新增 `game/prototypes/EXP-004/`，与规划合入方式无关，如需要可原样变基到合入后的 master。
实现 SHA：`b5f4a6a6fd0c8e4d08d6f17f32a337af6cd380d5（原型 `60c32a8`，加截图目录 `.gdignore`）`
状态：原型与检查完成，待 Codex 审查；G4 待用户挑选。

## 改动

只新增 `game/prototypes/EXP-004/`：

| 文件 | 内容 |
| --- | --- |
| `preview.gd` / `preview.tscn` / `run_preview.cmd` | 模拟场地（第2日黄昏）、模拟 HUD、按键切换方案、G-08 短提示、战场波次横幅、暂停层 |
| `dialogue_view.gd` | 对话框三方案 A / B / C：逐字、单击补全 / 下一句、长按加速、自动关闭、强制剧情隐藏 HUD、暂停保持、救助离开确认（默认“留下”） |
| `intro_card.gd` | 介绍卡两方案 1 / 2：右上滑入、停留、滑出，暂停停住；普通敌人小卡、Boss 名片大卡 |
| `tests/smoke_test.gd`、`tests/capture.gd`（含 `.uid`） | 冒烟测试 64 项；截图脚本 |
| `screenshots/*.png` | 13 张截图 |
| `README.md` | 启动、按键、三张中立对比表 |

测试脚本的 `.uid` 已一并入库，避免重复 BL-115 的问题。

## 要求对照

| 要求 | 结果 |
| --- | --- |
| 1 对话 2～3 方案，均满足 T7-C | 三个方案；差别在底（黑框 / 纸笺 / 黑纱纸边）、名牌、继续与加速标记。B 的纸笺不是“黑色半透明”，选 B 需同步修订 T7-C（README 已注明） |
| 2 救助离开确认 | 对话最后出现“留下 / 确认离开并放弃救助”，默认“留下”，焦点只在两项间；A-020 确认后才放弃 |
| 3 G-08 两种呈现 | 1 对话旁白一句（无角色名、字色较灰）；2 原地短纸签，约 4 秒淡出，不锁操作 |
| 4 介绍卡 2 方案、与 Boss 名片统一、进入 / 停留 / 离开 | 两个方案，各有普通与 Boss 版；战场波次提示改为独立短横幅，不再借用介绍卡（建议） |
| 5 对话中暂停 | Esc / Start 暂停时逐字与介绍卡计时都停住，返回后同一句继续 |
| 6 只用模拟数据、只改原型目录 | 是；未改正式代码、场景、`project.godot`、输入映射、存档 |

## 完成标准

1. **冒烟测试** `EXP004_SMOKE checks=64 failures=0`（`--fixed-fps 60`，真实 E / RB、Esc、方向键、Enter、手柄 A 事件，断言读 `drawn`，记录都取自绘制调用）：三个对话方案各自的逐字、单击补全、继续标记、RB 长按加速、暂停保持与返回、自动关闭、强制剧情隐藏并恢复 HUD、离开确认默认“留下”且 A 留下 / 右移 Enter 离开；G-08 两种呈现；两个介绍卡方案的滑入、停留、暂停停住、滑出与 Boss 大卡。
2. **防重叠**：1920×1080 与 1280×720 下、三个对话方案各一次，同时打开对话框（含底下按键提示）、Boss 名片（最大的卡）、G-08 短提示、波次横幅，与模拟 HUD 区域两两不相交且都在窗口内（6 项）。布局曾因 Boss 名片与对话框相交而调整：对话框改为 840 宽居中、Boss 名片 480 宽、波次横幅下移。
3. **截图与对比表**：`screenshots/`（每个对话方案的普通句与离开确认、G-08 两种、两种卡的普通与 Boss、B 方案与卡和横幅同屏），对比表见 README；截图人工看过。
4. **现有测试**：见 G2 + G3。
5. **G4**：待用户挑选（见下）。

## G2 + G3

在实现 SHA、起点 dirty=false 执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**通过**，G2 **87/87**（原型不登记，套件数不变），G3 **102/102 + 67/67**。content_stable=False 只因 EXP-003 的两个未入库 `.uid`（BL-115，ENV-007 修复）；本任务新增的截图已用 `.gdignore` 排除导入，测试脚本的 `.uid` 已入库，不新增不稳定来源。摘要 `codexandclaude/runs/20261022T025406.338040Z/`（不入库）。

## G4（用户挑选）

```powershell
& "D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path "D:\31days\codexandclaude\worktrees\claude\game" res://prototypes/EXP-004/preview.tscn
```

请选定：对话方案（A / B / C）、G-08 呈现（1 / 2）、介绍卡方案（1 / 2）；也可以混搭或提出修改。

## Claude 的推荐（不属于中立对比）

- **对话：C · 黑纱纸边**。保留 T7 的“黑色半透明”与亮场景下的可读性，不用改规格；纸边又把它和已正式化的纸面界面（暂停、主界面、死亡）连在一起。A 最稳但和其他界面风格割裂；B 最统一但要改 T7，且在亮场景里纸笺与背景对比偏弱。
- **G-08：2 · 短提示**。T4 §6 的意思是“到了那里就会知道”，路过就能看到更符合；不打断操作。正式实现时可以用 SYS-009 的交互对象查询判断“靠近”，不需要另写一套距离判断。
- **介绍卡：1 · 纸签名片**。和 HUD、暂停菜单同一套纸面语言，黑底场景上最醒目；墨条横幅更有气势，但和黑纱对话框同在上方时，画面上方的黑色会偏多。
- 战场波次提示不再借用介绍卡，改为独立的短横幅。

## 说明与未决

- 原型的模拟 HUD 只是示意，正式实现时强制剧情隐藏的是 UI-002 的 `FormalHud`。
- “E / RB 继续 · 长按加速”的提示行在框下方；正式版是否保留，可在 G4 时一并决定。

## full 自动摘要

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`b5f4a6a6fd0c8e4d08d6f17f32a337af6cd380d5`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-22T02:54:06.338040+00:00；结束：2026-10-22T03:07:18.996008+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际87 / 预期87；完整=True；通过=True。
- G3:tests：实际102 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`0b0e1061270416f294c81d61942b45d1b0532d1a`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`fe62beb34a2a49b39f95de99e7177547513b84da6750dca77fd4bb216a2b2b99`；工作区范围指纹（原始字节）：`db83c6f4af6c7a063a829bb706a55d807fac255d20edbb36868a65e8c6fada34`。
全工作区指纹：`a0d391fa94e3873489c032d2eea6d3fd3c4a162b13cd34d32559a7d83a3fc5ff`；运行前后内容稳定：`False`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.046秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T025406.338040Z\001.txt`；SHA256=`7d30f7d45c1803b71ebaba3cbe9c31e2d7855d1749addd1d2d4a098205f6f9cf`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T025406.338040Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T025406.338040Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.375秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T025406.338040Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T025406.338040Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T025406.338040Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\claude\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\runs\\20261022T025406.338040Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=765.969秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T025406.338040Z\007.txt`；SHA256=`337a45395dd732c4a9e4b3297278f02ab13afc09f6d4493d9ed005a993d9f395`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.375秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T025406.338040Z\008.txt`；SHA256=`2a75bf6bda7e7a7ea255f5299ce58e05472cbb176677d38df84cbbcad6e6e671`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=21.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T025406.338040Z\009.txt`；SHA256=`9081652b05579cd6928bc4e2b21d0e6c7a3a095ee0cad41584613a9f50b97ce2`。
- 报告 `D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261022T025406.338040Z\engine.txt` SHA256=`0855acd02db79ebcd14774e25de9fbb4f1e69d4e8edd00045b5a4eb344b7b65e`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
