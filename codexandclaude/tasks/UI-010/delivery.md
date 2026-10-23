# UI-010 交付记录

实现者：Claude｜审查者：Codex｜分支：`claude/UI-010`
基线：`96f0400b08f770ee86d8385db2c0f9c29e5e31a1`（UI-009、CLN-001 合入后的 master）
实现 SHA：`6522d5a56abe8d0f064dec766041ae8345f8a57b`（`bbfe707` 实现与测试 + `6522d5a` 验收适配与文档）
状态：第2轮复审（`review.md`“第2轮复审”，R2 剩余一项）已修复；Codex 第3轮复审通过（`cc0df6d`）；G4 用户 2026-10-23 通过。待 Codex 集成。
修复后实现 SHA：`a9569d99c47ad79a242a5c821d6344c70dcf6681`（第1轮修复 `8109596` + 本轮 `a9569d9`）；第1轮审查 `be9682c` 与第2轮复审 `ca802e7` 均已快进合入本分支。

## 第2轮复审修复（2026-10-23）

复审记录见 [review.md](review.md)“第2轮复审”（Codex，`ca802e75`）。R1 已确认解决；R2 剩余的一项成立。

| 问题 | 修复 | 回归 |
| --- | --- | --- |
| 信号先到、文字并入后，同一段文字再到仍成第二条；文字先到则只有一条，结果依赖到达顺序 | 文字并入信号的提示时，把原文记在该条目的 `text` 上；重复文字判断改为查窗口内**任何**持有同一原文的条目，不再只看来源为文字的条目 | 文字→信号→同文、信号→文字→同文，各只一条（合成、标题取信号、下行取文字）；窗口外同一段文字仍是新的一条。原有回归保留：两次独立同名获得仍两条，一个信号配两段不同文字仍一条合成、一条单独 |

没有改信号的处理：信号从不因文字相同而丢弃，一对一合成保护不变。文档去重规则第 2 条已补充“与到达顺序无关”。

`QUEST_NOTICES_TESTS` 68 → **74/0**。

**变异**（逐项只改一处，跑新套件，按原字节恢复并核对）：

| 变异 | 结果 |
| --- | --- |
| 并入时不记原文 | 2 项失败 |
| 重复文字只查来源为文字的条目（第1轮修复的写法） | 2 项失败 |
| 重复文字从不丢弃 | 6 项失败 |
| 忽略窗口（同一段文字永远不再显示） | 5 项失败 |
| 一段文字可并入多个信号 | 1 项失败 |
| 文字与其信号不合成 | 9 项失败 |

**full**（修复后实现 SHA、起点干净，记录草稿在临时目录）：**通过**，G2 **94/94**，G3 **108/108 + 67/67**，**content_stable=True**，ObjectDB 泄漏 0 处，引擎报告 WARNING 行 0 处。摘要 `codexandclaude/runs/20261023T075050.248686Z/`（不入库）。外观未变，G4 仍按原入口进行。

<!-- 第2轮修复后 full 自动摘要 -->
<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`a9569d99c47ad79a242a5c821d6344c70dcf6681`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-23T07:50:50.249687+00:00；结束：2026-10-23T08:01:44.383731+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际94 / 预期94；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`d773dbc32cce49dd32191c9e1ba2393fa5973d4b`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`b0b5cc688fab6469dca2e0b047bf16f6f21677796f17c0673465b39fd67ef6da`；工作区范围指纹（原始字节）：`3e531d466be1168c2523184212dee811e23207964046755ec7ca6e5422b2a3aa`。
全工作区指纹：`4320078bbb11f6763205ebf556f855a75ac717ed9015284884ba35b2b1cbe270`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T075050.248686Z\001.txt`；SHA256=`11907754109f78ad77b0014217f718eba3af6c92c8f1234e1d625b39542f1686`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T075050.248686Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T075050.248686Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.297秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T075050.248686Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T075050.248686Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T075050.248686Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\claude\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\runs\\20261023T075050.248686Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=630.266秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T075050.248686Z\007.txt`；SHA256=`8f83e3974b5de6a4a7fbd17d367236551eed80e90f6246d898d9ee18f2750dec`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.296秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T075050.248686Z\008.txt`；SHA256=`14dc2b30c561485160086c22b6a549d07328f77f2c299baff9e2cb215564ea18`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=18.657秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T075050.248686Z\009.txt`；SHA256=`6eba78be806ec6aec5a1e00c16c8f67510a6f50dbcc7bbc0df4afc0fad4eac70`。
- 报告 `D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T075050.248686Z\engine.txt` SHA256=`07979ccc090e9f70ff9a5a2189e12ec8412b3705edb1fea953e41f1a5db1af48`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

## 第1轮审查修复（2026-10-23）

审查记录 [review.md](review.md)（Codex，`be9682c7`）。两项均成立，按建议修复。

| 编号 | 问题 | 修复 | 回归 |
| --- | --- | --- | --- |
| R1 | 纸签直接采用任意 `quest_changed` 的任务，一次保存发出多项任务变化时停在最后一项 | `quest_changed` 是所有任务的事件流；纸签收到事件时重新读 `quest_state()`，只显示查询给出的当前任务（中央提示仍逐条显示所有事件） | 田野中开始 7 的救助，同一 Room、同一 data 下把日期改为第 3 日并真实 `save_current()`：确认一次保存发出 3 条“救助已过期”，纸签的 id、objective、state 与 `quest_state()` 相同，objective 与暂停菜单所读 `quest_status_text()` 相同，绘制的也是它 |
| R2 | 1.5 秒同文去重吞掉独立、保存成功的同名获得 | 信号（`quest_changed` / `item_obtained`）每条都是独立事件，**从不因文字相同而丢弃**；只丢弃 1.5 秒内重复的同一段 `show_notice()` 文字；文字与信号合成改为一对一（一段文字只并入一个信号，一个信号只并入一段文字） | 两件不同持久化 key、同名“测试拾取”的拾取先后写盘成功 → 两条提示，并逐帧确认两条都作为队首依次画出；同名拾取与自己的“获得测试拾取 · 第三件”文字仍合成一条；一个信号与两段不同的“获得测试拾取”文字 → 一条合成、一条单独 |

文档 `quest_notices_ui.md` 的去重定义与纸签数据来源已同步更正（不是缩小窗口）。

`QUEST_NOTICES_TESTS` 53 → **68/0**。

**变异**（逐项只改一处，跑新套件，按原字节恢复并核对）：

| 变异 | 结果 |
| --- | --- |
| R1：纸签采用事件里的任务（原实现） | 3 项失败 |
| R2：任何来源同标题同下行都丢弃（原实现） | 2 项失败 |
| R2：一段文字可并入多个信号 | 1 项失败（在 68 项版本上；66 项版本时存活，补“一个信号两段文字”用例后杀死） |
| 同一段文字两次都保留 | 2 项失败 |
| 读档补发当前任务为“救助开始” | 3 项失败 |
| 文字与其信号不合成 | 4 项失败 |
| 保存失败仍发获得 | 4 项失败 |
| 提示不避让保存失败提示 | 2 项失败 |
| 排队时多条同时推进 | 2 项失败 |
| 对话中提示照常显示 | 1 项失败 |
| 纸签结束状态不收起 | 1 项失败 |
| 纸签只在换 Room 时刷新 | 2 项失败 |
| 剧情（HUD 隐藏）时纸签仍显示 | 1 项失败 |
| 灰盒 `notice` Label 重新显示 | 1 项失败 |
| 放弃按墨色显示 | 2 项失败 |

除标明者外均在 66 项版本上运行（最后一次改动只新增断言）。

**full**（修复后实现 SHA、起点干净，修复记录草稿在临时目录，运行中未改工作区）：**通过**，G2 **94/94**，G3 **108/108 + 67/67**，**content_stable=True**，ObjectDB 泄漏 0 处，引擎报告 WARNING 行 0 处。摘要 `codexandclaude/runs/20261023T061217.876036Z/`（不入库）。修复不改纸签与提示的外观，G4 仍按原入口进行。

<!-- 修复后 full 自动摘要 -->
<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`81095965a442d8ca9b032522f4d49f7a200eef9a`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-23T06:12:17.876036+00:00；结束：2026-10-23T06:23:07.153325+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际94 / 预期94；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`e0c32cd979b98e82978e99d4c852fa1963b1bc7b`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`44d0e5320c6213cbeb858f7928ccbd7f327e8a0bb18b054e8d93e9ae4bbd2aa9`；工作区范围指纹（原始字节）：`7c2532105284206968b82ddf4907fe2965908225dbf549abfdd7500bdda11050`。
全工作区指纹：`8f2cea3ecd0c95006adbd96c022cff0d4965a190b66060ee87e1815a8b267d2d`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T061217.876036Z\001.txt`；SHA256=`caa761aeb0c33dd52604f94134f4c0daf696199c1e415c86ccc637710141d214`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T061217.876036Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T061217.876036Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.313秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T061217.876036Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T061217.876036Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T061217.876036Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\claude\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\runs\\20261023T061217.876036Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=623.89秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T061217.876036Z\007.txt`；SHA256=`169bc2dd60946ce63ffd06c58c213875c8eaa6c4e200fa3fb770f58b4fc60600`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.313秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T061217.876036Z\008.txt`；SHA256=`b65e21291e82582f84867f84595056e4cf4ee490d72b10d5568167113c74ab03`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=20.172秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T061217.876036Z\009.txt`；SHA256=`9d91961522c5364aac52d8004d5f167fbb882c1b2015c3e8f804337886d3ad31`。
- 报告 `D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T061217.876036Z\engine.txt` SHA256=`956f52acdcc08b5563745338a52b671a1aad51b96a67d5f4637e6a92ee3314ae`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

## 改动（首次交付）

| 文件 | 内容 |
| --- | --- |
| `game/ui/hud/quest_slip.gd`（新） | `QuestSlip`：左侧任务纸签（“救助”、目标、结束状态着色）；读档 / 换 Room 读 `quest_state()`，之后随 `quest_changed`；结束状态约 6 秒收起；对话、剧情、暂停、死亡隐藏 |
| `game/ui/hud/center_notice.gd`（新） | `CenterNotice`：中央提示队列，来源为 `quest_changed`、`item_obtained`、`show_notice()`；一次一条、2.5 秒、排队；隐藏或无空位时等待；同一事件去重与合成 |
| `game/ui/dialogue/field_dialogue.gd` | 只改 `quest` 与 `notice` 的显示去向：两个 Label 放到隐藏的 `GrayboxModels` 下（仍是会话写入、旧测试读取的数据）；`show_notice()` 另发 `noticed(message)` |
| `game/ui/menus/life_ui.gd` | 挂载两个节点；`_error_rects()`、`_notice_avoided()`；纸签与提示加入 `_protected_rects()`；横幅避让提示 |
| `game/tests/test_quest_notices.gd`（新） | 登记套件 `QUEST_NOTICES_TESTS`，53 项 |
| `game/tests/acceptance/ui010_quest_notices.gd`（新） | G4 入口（自检 13/0） |
| `game/docs/quest_notices_ui.md`（新） | 位置、来源、颜色、排队与等待、去重规则、避让、测试 |

新脚本 `.uid` 一并入库。未改会话脚本、SYS-009、暂停菜单、存档与输入；**旧测试与旧断言一处未改**。

## 要求对照

| 要求 | 结果 |
| --- | --- |
| 1 左侧任务纸签 | 左侧中部偏上 (40, 450)，在操作提示之下，保存失败提示可见且相交时下移；“救助”标题 + 目标；进行中常显，已完成 / 已放弃 / 已过期显示状态约 6 秒后收起；无任务不显示；读档、换房先读 `quest_state()`，之后随 `quest_changed`；对话、剧情、暂停隐藏 |
| 2 中央提示 | 开始 / 进展 / 完成 / 放弃 / 过期与珍珠 / 拾取 / 药包 / 成长各一条，中上纸签“标题 + 一句”，2.5 秒淡出；排队不重叠；同一事件不重复；颜色：完成与获得成长金、放弃与过期朱红、其余墨色 |
| 3 接管灰盒 | `quest`、`notice` Label 不再显示，方法照常可调；`show_notice()` 文字作为一条中央提示，与信号去重（规则见下） |
| 4 避让 | 纸签与提示不压 HUD（含地平线）、对话纸笺、区域名称、交互提示、介绍卡、横幅、可见保存失败提示；放不下时等待（提示试四档高度，纸签下移），不覆盖 |
| 5 暂停菜单 | “当前任务”未改，仍读 `quest_status_text()`，与纸签的 `objective` 同源 |

**去重规则**（首次交付版本，已由上面的审查修复更正，现行规则见 `quest_notices_ui.md`）：①1.5 秒内标题与下行都相同的第二条丢弃；②1.5 秒内 `show_notice()` 文字与描述同一事件的信号合成一条——任务结束信号（完成 / 放弃 / 过期）与含同一个词的文字，获得信号与以“获得”开头且含该名称的文字；标题与颜色取信号，下行取文字的细节；③其余各自成条。实例：麦秆镇救助完成时“救助完成 · 可能性 +N · 返回7”与 `quest_changed(完成)` 合成一条“救助完成 / 可能性 +N · 返回7”；回 7 结算得到“救助进展”和“获得 · 泥粪中的理想家的注视 / 可能性上限12”两条（后者由获得信号与结算文字合成）。

**三处补充判断**：
1. 纸签的“剧情”判断用 HUD 是否被隐藏与 `intro_active`，不用 `scripted_control_locked`——后者在读档后等非剧情场合也会短暂为真，会让纸签误隐藏。
2. 结束状态的 6 秒只在纸签可见时计时，对话或暂停中不会悄悄耗完。
3. 中央提示在 1.5 秒窗口外的同样文字视为新事件（如两次不同时间的“第 2 日”）。

## 完成标准

1. **自动测试** `QUEST_NOTICES_TESTS` 53/0（`--fixed-fps 60`，真实 FinalBattleSession 与 SYS-009 信号，断言读 `drawn`，顺序与合成读提示历史）：
   - 7 的救助：真实事件开始 → 中央“救助开始”（墨色）+ 纸签“救助 / 目标”；进行中常显；真实麦秆镇对话与提交完成 → 只有一条金色“救助完成”（与会话文字合成、保留“可能性”细节），纸签“已完成”，约 6 秒后收起；回 7 真实结算 → “救助进展”与“获得 · 泥粪中的理想家的注视”两条；另起存档的放弃、过期各一条朱红提示，纸签状态朱红。
   - 获得：珍珠保存失败时无提示，重试成功出“获得 · 珍珠”（金色）；普通拾取、药包、成长（攻击范围强化）各一条，按顺序；逐帧观察只依次出现、从不同屏；之后的自动保存不重复。
   - `show_notice()` 单独文字成墨色提示；灰盒 `notice` / `quest` Label 不可见、文字仍在；1.5 秒内重复只一条，过后再来是新的一条。
   - 对话、剧情（会话真实的 `_story_hud`）、暂停：纸签与提示都不画，提示计时停住；结束后两者回来、计时继续。
   - 读档：结束状态与进行中各一份存档，读档后没有任何提示、纸签显示当前任务。
2. **防重叠**（同套件）：1920×1080 与 1280×720 下，7 旁同时有区域名称、交互提示、首领卡（已停靠）、战场横幅、保存失败提示与一条中央提示，先断言六者都真的画出，再核对纸签与提示在窗口内，且与 HUD 各绘制矩形、区域名称、交互提示、介绍卡、横幅、保存失败提示都不相交（此时提示落到第四档高度）。
3. **现有测试**：旧断言未改；单跑 quest_interactions 316/0、campaign 166/0、pause_menu 53/0、field_room 50/0、town_rescue 47/0、ravine_rescue 58/0、ravine_depth 71/0、outskirts 24/0、day_clock_session 43/0、world_day_session 38/0、dialogue_ui 52/0、enemy_cards 42/0、area_prompts 60/0、hud_layout 268/0、exploration_room 33/0、medkit_session 68/0、completed_slots 73/0；其余见 G2。
4. **变异**（逐项只改一处，跑新套件，按原字节恢复并核对）：

| 变异 | 结果 |
| --- | --- |
| 读档时把当前任务补发为“救助开始” | 3 项失败 |
| 同一提示两次都保留 | 2 项失败 |
| 文字与其信号不合成 | 3 项失败 |
| 保存失败仍发获得（在 `save_current` 写盘失败分支发 `item_obtained`） | 1 项失败 |
| 提示不避让保存失败提示 | 2 项失败 |
| 排队时多条同时推进 | 1 项失败 |
| 对话中提示照常显示 | 1 项失败 |
| 纸签结束状态不收起 | 1 项失败 |
| 纸签只在换 Room 时刷新（读档不刷新） | 2 项失败 |
| 剧情（HUD 隐藏）时纸签仍显示 | 1 项失败 |
| 灰盒 `notice` Label 重新显示 | 1 项失败 |
| 放弃按墨色显示 | 2 项失败 |

前四项对应完成标准 4 列出的变异。

5. **G4**：用户 2026-10-23 按下方入口验收（在第2轮修复与第3轮复审通过之后），回复“G4测完了，没问题”，通过。

开发中按渲染截图核对了纸签与提示的样子；纸签去掉了目标文字开头与标题重复的“救助：”。验收槽 1 另用临时脚本确认：从渴望俯视检查点走进田野、看完 7 的第一段剧情后出现“救助开始”。

## G2 + G3

在实现 SHA、起点干净执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**通过**，G2 **94/94**（新增套件 +1），G3 **108/108 + 67/67**，**content_stable=True**，ObjectDB 泄漏 0 处，引擎报告 WARNING 行 0 处。摘要 `codexandclaude/runs/20261023T053618.540761Z/`（不入库）。交付记录草稿在临时目录，运行中未改工作区。

## G4（用户）

```powershell
& "D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path "D:\31days\codexandclaude\worktrees\claude\game" --script res://tests/acceptance/run_acceptance.gd '--' --adapter=res://tests/acceptance/ui010_quest_notices.gd
```

- 槽1 渴望俯视之后：向右到田野，看完与 7 的第一段剧情 → 中上“救助开始”、左侧任务纸签；再向右到麦秆镇救下幸存者 → 金色“救助完成”；回 7 → “救助进展”“获得 · 泥粪中的理想家的注视”。
- 槽2 瓦砾塔检查点：附近房间拾取珍珠 → “获得 · 珍珠”。
- 槽3 巢都沟壑入口（第 2 日）：向前找到幸存者 → 沟壑救助开始 / 完成。
- 请看：提示一条接一条、不重叠；对话、暂停时隐藏；完成后纸签约 6 秒收起。

## 说明与未决

- 第 3 日自然到期时，四处救助会同时过期，SYS-009 各发一次“过期”，中央会依次出现四条“救助已过期”（目标文字各不同）。这是数据层的实际事件；若希望合并，可另议。
- 正式任务文本属 M3；“救助”以外的任务类型尚不存在。
- 本任务完成后 M2-c 收尾。

## full 自动摘要

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`6522d5a56abe8d0f064dec766041ae8345f8a57b`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-23T05:36:18.541762+00:00；结束：2026-10-23T05:47:07.200312+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际94 / 预期94；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`33e1b45dd6765ede887dbeb376e38b652b3d9f63`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`e589de16c925f41c89d777324d1f1c1a52f889524d2aec50f3d6e8272be36a38`；工作区范围指纹（原始字节）：`af91c48acf987fb5b0823fd464145bae79dbf7df2a106779a953f4eb81068095`。
全工作区指纹：`5390862ae22df232935c1b23ac747f70ad9acd4a56a50d7d3ebbb85eea8fbd83`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T053618.540761Z\001.txt`；SHA256=`2041d2caa2ecd322d611c39a050479a3d71ddf67bd2a6fac006683fed9086d87`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.046秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T053618.540761Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T053618.540761Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.312秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T053618.540761Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T053618.540761Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T053618.540761Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\claude\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\runs\\20261023T053618.540761Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=623.094秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T053618.540761Z\007.txt`；SHA256=`01102e18688b83d658fede0fbc98047a17677b77877582f899344f2c2dbe4d6f`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.266秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T053618.540761Z\008.txt`；SHA256=`14dc2b30c561485160086c22b6a549d07328f77f2c299baff9e2cb215564ea18`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=20.328秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T053618.540761Z\009.txt`；SHA256=`9aaada896a1a85d751824544788b79ad944d85c3a82869c3c73971ea9dd58267`。
- 报告 `D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T053618.540761Z\engine.txt` SHA256=`1f73d363eab453c15051b373cf80ed747ff74cab6ba7145402c41c58e746b6c8`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

