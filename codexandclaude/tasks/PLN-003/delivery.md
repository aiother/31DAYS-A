# PLN-003 交付记录：规划刷新（第十批收尾）与 M3 素材决定入库

状态：已交付，待审查｜实现：Claude｜日期：2026-10-25

## 固定对象

- 基线：master `ebcad522519bb2bc06780e65379a19bbe33c1bc8`（第十一批规划合入后）。
- 实现提交：`a86edcce58761898d298f49d725865d8fca33118`（分支 `claude/PLN-003`）。本记录与任务卡首部状态另行提交。
- 三份规划文档的汇总基线统一为 `master@ebcad52`。

## 改动

| 文件 | 改动 |
| --- | --- |
| `Words/T6_素材来源与规格决定.md`（新增） | 取自 `claude/M3-asset-sources` 的 `6e9910f`，**与原文逐字节相同**（`git diff 6e9910f a86edcce58761898d298f49d725865d8fca33118 -- <文件>` 为空）。核对：基准分辨率 1920×1080、瓦片 64 px（`graybox_tileset.tres`）、玩家碰撞胶囊高 96 px 与当前 master 一致；文中引用的 `game/` 路径除建议新建的 `game/assets/CREDITS.md`（ART-001、ENV-008 建立）外都存在，因此不需要修正 |
| `codexandclaude/ROADMAP.md` | 首部与快照说明加第十批刷新；快照：美术行改写（素材来源已决定）、**新增特效行**（FX-001、FX-002 全部正式化，含用户 G4 后的外观）、音频行写明“获得 / 消耗 / 不足音留空，恢复音暂用占位”（PLN-002 审查 N1）并写来源、文本与演出行（SYS-012 已完成，台词来源已决定）、测试行（97 套件 / 99 项，Python 111 + 67）、规格行（T0～T4 现行，新增 T6 决定文件）；M3 依赖栏：已完成项更新、第十一批、**补 BL-063**（PLN-002 审查 N2）；M4：BL-024 已完成，BL-025 建议第十二批；P3 列表补 BL-126；第 6 节美术、音频、台词三行改为“已决定（2026-10-25）”；变更记录加一行 |
| `codexandclaude/BACKLOG.md` | 首部；状态变更与新增见下表；BL-062 说明加入用户的敌人特性要求 |
| `codexandclaude/BOARD.md` | 首部（第十批收尾，第十一批进行中，新基线）；任务行只核对，未改 |
| `tests/test_planning_documents.py` | 新增 `test_t6_asset_source_decisions_are_recorded`：决定文件存在、无乱码、日期、章节连续，九条关键决定逐条存在 |

## 状态变更表

| 待办 | 原状态 | 新状态 | 依据 |
| --- | --- | --- | --- |
| BL-024 | 已立项 DOC-010（第十批） | 已完成（DOC-010） | DOC-010 集成记录，master `94aba34` |
| BL-065 | 已立项 FX-002（第十批；其余部分） | 已完成（FX-001 战斗反馈，FX-002 其余部分） | FX-002 集成记录，master `3200dcf`；用户 G4 第 2 次通过 |
| BL-081 | 已立项 SYS-012（第十批；流程衔接部分） | 待立项（流程衔接部分已完成：SYS-012；正式演出表现待素材） | SYS-012 集成记录，master `300d5d9` |
| BL-062 | 待立项 | 待立项（说明补充：敌人与 Boss 要体现各自特性，不复用玩家表现语言） | 用户 2026-10-25 FX-002 G4 意见 |

BL-061、BL-063 已由第十一批起草立项（ART-002），本任务只核对。BL-066 仍为“待立项（系统部分已完成）”，正式音频未到，不改。

## 新增事项表

| 编号 | 优先级 | 事项 | 来源 |
| --- | --- | --- | --- |
| BL-126 | P3 | T4 预算措辞区分“本次开战的初始预算”与“当前剩余预算”，不改规则；可随 BL-025 或下次 T4 修订处理 | DOC-010 第1轮审查 N1 |

## 检查

- `codexandclaude/tests` 67/0（含基线一致、路线图覆盖全部未完成 P1/P2、链接只指向 `codexandclaude/` 内——第 6 节对决定文件改用路径文字而非链接）；`tests/` 全部通过。
- 新断言的变异（各自只改决定文件一处，按原始字节恢复）：“允许直接作为成品”改为“仅作参考”、“不用 NC 与 ND”改为“可用”、Skeleton2D 改 Spine，均使新测试失败。

G3（实现提交上）：

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`focused`。
被测SHA：`a86edcce58761898d298f49d725865d8fca33118`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-26T02:42:57.251613+00:00；结束：2026-10-26T02:43:21.278113+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "focused", "--python-all"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G3:tests：实际112 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`28d5b8b30b52b3eee11ae0f2baef438d4005d93d`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`9be36b7c3eafbae11254d579d8e2c399c4df3d3c2aa48a7536607258db273ae5`；工作区范围指纹（原始字节）：`ac01bc070e95bb94596d9022bfce6895b14b7612f803e87ccdd379327a758510`。
全工作区指纹：`b24591e760a7e8f9cbfd19951fdac92c77319dc803e9a0b5e780ef64ee0dc597`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261026T024257.250609Z\001.txt`；SHA256=`9a945325a5c3c840598d8ff83320c20a3fa09cb7ba106791dde812bea7024e6f`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261026T024257.250609Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.344秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261026T024257.250609Z\003.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261026T024257.250609Z\004.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261026T024257.250609Z\005.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.203秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261026T024257.250609Z\006.txt`；SHA256=`06a8d62d6fba520aca3b5f7d98986eb0e4ab9764b43175f438a174430190c9d8`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=18.985秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261026T024257.250609Z\007.txt`；SHA256=`cc8ea4bd008773b66becd2a3755448b31fa58e3ae19f157c1021d61794900ce7`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
