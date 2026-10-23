# PLN-001 交付记录

实现者：Claude｜审查者：Codex｜分支：`claude/PLN-001`
基线：`519a7f66814b26ef3309184c3c1aa0f7d9bfc6a7`（第八批任务卡合入后的 master）
实现 SHA：`05ebf90a790f22fd636fecdaff70e4ffa10dd22b`
状态：规划刷新、T7-G 核对表与验收入口完成，待 Codex 审查；**用户整体通关验收（G4）待进行**，M2 在其通过后关闭。

## 改动

| 文件 | 内容 |
| --- | --- |
| `codexandclaude/ROADMAP.md` | 汇总基线改为 master@519a7f6；第 2 节快照 UI、测试、文本与演出、规格四行重写，结论更新；第 3 节 M2 标为“界面实现已完成、待 T7-G 验收”，M3、M4 注明第八批进行中的任务；工具线 BL-105 完成；P3 清单去掉已完成的 BL-108、BL-109、BL-113，加入 BL-117～BL-120；第 4 节 M2-a/b/c 标注完成任务，“可选”一行定论；第 5 节新增第七批进展与第八批表；第 6 节需要用户决定的事项更新；第 7 节变更记录两行 |
| `codexandclaude/BACKLOG.md` | 汇总基线改为 master@519a7f6；14 条状态改为已完成并写明任务 ID（见下表）；新增 BL-117～BL-120（P3） |
| `codexandclaude/BOARD.md` | 汇总基线改为 master@519a7f6；第八批四张卡状态；第八批说明一段 |
| `codexandclaude/tasks/PLN-001/t7g_check.md`（新） | T7-G 11 项逐项核对：实现、套件与断言原文、结论；整体通关验收要点 |
| `game/tests/acceptance/pln001_campaign.gd`（新） | 整体通关验收入口，三个按剧情顺序的独立存档槽（自检 15/0） |

## 状态改动清单

| 编号 | 原状态 | 新状态 |
| --- | --- | --- |
| BL-040 | 已立项 UI-004（系统部分 SYS-008；方案 A · 黄昏远景） | 已完成（UI-004；系统部分 SYS-008） |
| BL-041 | 已立项 UI-004（系统部分 SYS-008；书签 + 天空条） | 已完成（UI-004；系统部分 SYS-008、SYS-004） |
| BL-044 | 已立项 UI-010（数据见 SYS-009） | 已完成（UI-010；数据 SYS-009） |
| BL-045 | 已立项 UI-007 | 已完成（UI-007） |
| BL-047 | 已立项 SYS-007（数据部分）、UI-006（正式界面） | 已完成（UI-006；数据 SYS-007） |
| BL-048 | 已立项 UI-008（原型 EXP-004 选定方案 D） | 已完成（UI-008；原型 EXP-004） |
| BL-049 | 已立项 UI-007（数据见 SYS-009） | 已完成（UI-007；数据 SYS-009） |
| BL-050 | 已立项 UI-005 | 已完成（UI-005；十二色手链演出仍属后续） |
| BL-051 | 已立项 UI-005 | 已完成（UI-005） |
| BL-054 | 已立项 UI-009（原型 EXP-004 选定方案 2） | 已完成（UI-009；原型 EXP-004） |
| BL-108 | 已立项 ENV-007 | 已完成（ENV-007） |
| BL-109 | 已立项 ENV-007 | 已完成（ENV-007） |
| BL-115 | 已立项 ENV-007 | 已完成（ENV-007） |
| BL-116 | 已立项 CLN-001 | 已完成（CLN-001） |

新增条目（均为 P3，依据各任务交付记录中的“说明与未决”）：

| 编号 | 事项 | 来源 |
| --- | --- | --- |
| BL-117 | 保底实体外观（T7 核对表 G-06），做不做由用户决定 | 路线图 M2“可选”一行 |
| BL-118 | 第 3 日四处救助同时过期时，四条“救助已过期”提示是否合并 | UI-010 交付记录 |
| BL-119 | 部分 Room 的 `display_name` 仍为灰盒名（如“瓦砾塔Room2 / Room3”） | UI-007 交付记录 |
| BL-120 | 按最近输入设备只显示一种按键图示（需先补输入设备信号） | UI-007 交付记录 |

未删除任何条目；BL-022、BL-060、BL-065 保持“已立项（第八批）”；路线图引用的 BL 编号都在待办中，P1 / P2 未完成项都已归入某个里程碑或分批（`test_collaboration.py` 的覆盖检查通过）。

## T7-G 核对结论

详见 [t7g_check.md](t7g_check.md)。11 项中：

- **已覆盖** 8 项：主界面、HUD、任务反馈、菜单、死亡恢复、存档、时间状态、最终结算——正式实现已合入，自动测试用真实会话 / 真实输入验证通过条件，对应界面任务已有用户 G4。
- **需实机确认** 3 项：资源反馈（“清楚理解”是体验判断）、对话交互（7、10、救助 NPC 需在一次通关里连起来走）、V0.1 范围一致（规格级，文档已核对）。
- **未覆盖** 0 项。

核对中没有发现需要另立修复任务的实现缺漏；发现的遗留事项已登记为 BL-117～BL-120。

## 完成标准

1. 三份规划文档汇总基线一致（master@519a7f6），状态与 master 一致；状态改动清单见上。✓
2. `t7g_check.md` 覆盖 T7-G 全部 11 项，每项有结论与依据，“已覆盖”项给出可复跑的套件与断言原文。✓
3. 用户整体通关验收：**待进行**（见下）。通过后在路线图中把 M2 标为完成；如有问题，登记待办并列出关闭前必须补的事项。
4. G3 通过；新增验收适配自检通过，full 见下。

## G2 + G3

在实现 SHA、起点干净执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**通过**，G2 **94/94**（验收适配不登记为套件，套件数不变），G3 **108/108 + 67/67**（含 `test_collaboration.py` 的三份文档汇总基线一致、路线图覆盖全部未完成 P1 / P2 待办等检查），**content_stable=True**，ObjectDB 泄漏 0 处，引擎报告 WARNING 行 0 处。摘要 `codexandclaude/runs/20261023T095052.688508Z/`（不入库）。交付记录草稿在临时目录，运行中未改工作区。

验收入口自检：`Godot --headless --path game --fixed-fps 60 --script res://tests/acceptance/run_acceptance.gd -- --adapter=res://tests/acceptance/pln001_campaign.gd --self-test` → `PLN001_ACCEPTANCE_TESTS checks=15 failures=0`。三个槽的夹具分别与 UI-010（槽 1、槽 2）和 UI-009 / UI-002（槽 3）已由用户 G4 走过的夹具一致。

## G4（用户整体通关验收）

**第一部分：真实启动游戏**（主场景，用你自己的存档槽也可以）

```powershell
& "D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path "D:\31days\codexandclaude\worktrees\claude\game"
```

- 主界面：新游戏、继续游戏、设置、退出（对应 T7-G 第 1 项）。
- 暂停菜单：继续、设置、返回标题、保存并退出（第 6 项）。
- 故意死一次：死亡界面、从检查点继续（第 7 项）。
- 返回标题后用“继续游戏”回到存档。

**第二部分：验收入口的三个存档槽**（独立临时存档，关闭窗口自动清理）

```powershell
& "D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path "D:\31days\codexandclaude\worktrees\claude\game" --script res://tests/acceptance/run_acceptance.gd '--' --adapter=res://tests/acceptance/pln001_campaign.gd
```

- 槽 1 第 1 日·渴望俯视之后：田野 7 的剧情 → 麦秆镇救助 → 回 7 获得注视（第 3、4、5 项）。
- 槽 2 第 2 日·巢都沟壑入口：沟壑救助、珍珠、换日（第 3、5、9 项）。
- 槽 3 第 3 日·中心战场前（已救 10）：最终战打到胜利与结局画面（第 4、9、10 项）。
- 最后对照第 11 项：有没有感到 T0 之外的新系统。

请逐项告诉我结果（或“都没问题”），我记入本记录并在路线图中关闭 M2。

## full 自动摘要

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`05ebf90a790f22fd636fecdaff70e4ffa10dd22b`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-23T09:50:52.688508+00:00；结束：2026-10-23T10:01:40.327803+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际94 / 预期94；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`98db24d1ce7b71d1678ab814a86f86f2a024fab3`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`3540417e101478fe15a095fa100707064ef584d57a23a2b11be86c9d52f72363`；工作区范围指纹（原始字节）：`c2d997f32a925e9ed0822bb32c445ee59a76f31419de6f982497130f13735b93`。
全工作区指纹：`02aa4d7211834bf18d4b6ffb746ce38d5ff889f0f911e0dee468ec2c08972652`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T095052.688508Z\001.txt`；SHA256=`4f5cf59250cff0f246f892abd2733308932ae2f6c13c76acffd158f79e67331e`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T095052.688508Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T095052.688508Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.281秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T095052.688508Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T095052.688508Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T095052.688508Z\006.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\claude\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\runs\\20261023T095052.688508Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=623.813秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T095052.688508Z\007.txt`；SHA256=`a429f73d5f10b7c328778912c969d12e134ecfa3ab730452cc9b373c58e498cd`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.343秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T095052.688508Z\008.txt`；SHA256=`0f7c2ec174fcb5c214aec0b8b42555521437518875f03b7057eb0161298903c6`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=18.688秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T095052.688508Z\009.txt`；SHA256=`a4ef77a3422b4604c29af816e7a622390ce4011ef9477fd07e9918849b84a433`。
- 报告 `D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T095052.688508Z\engine.txt` SHA256=`6b52f3dc612201f471a7592c65eceed6abbfabe2cee5ba0651e96c40beaa016a`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

