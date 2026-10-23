# CLN-001 第1轮审查

审查者：Claude｜日期：2026-10-22｜结论：**通过**，无阻断项。不合并 master（由 Codex 集成）。

## 固定对象与范围

- 基线：`1f0cd6a5735ae07f16c1e270fc0a2cf7620735a0`（第七批规划合入后的 master）。
- 实现：`adfbc6f73e1b5b8dd446401a30a8a1acf999df4c`；交付：`2764624d456addc84a31097606944726ba940e02`。审查分支 `claude/CLN-001-review` 从交付 SHA 建立，审查期间只新增本记录。
- 改动文件 21 个，全部在卡上“允许修改的文件”内：10 个 `game/world/` 提示脚本与场景（只改提示 Label 的文字与可见性）、6 个旧测试各一处断言、新套件与 `.uid`、基线查询夹具、任务卡首部、交付记录。未改会话脚本、交互范围与判定、SYS-009、存档、输入、UI-007 正式提示。
- 与最新 master `412933f6`（UI-008 已合入）做 `git merge-tree`：无冲突。

## 要求对照

| 要求 | 核对 |
| --- | --- |
| 1 去掉只表达“按 E / RB 做某事”的灰盒文字 | 拾取物、落石开关（未关闭）、连接机关（清敌未开）、7、三处幸存者（含四个场景初始文字）均已去掉。在交付 SHA 上 `git grep "E / RB" game/world game/systems`，剩余的只有 `$Instructions` 说明、保存失败的“E / RB 重试”通知与碎石堆状态，均属卡上“不在范围内”或是保存失败信息，不是重复按键提示 |
| 2 保留状态文字 | “落石已永久关闭”“需要先清敌”“已开启”、幸存者状态名、药包“靠近自动拾取 · 应急药包”与“药包已满 · n / 3”都保留并有断言。药包是自动拾取、本来就没有 E / RB 文字，脚本不改的判断成立 |
| 3 不改规则 | 世界脚本的改动只落在 `prompt.text` / `prompt.visible` 两类赋值；`can_collect()`、范围计算、会话判定未动。见下方独立基线比对 |
| 4 旧断言改写 | 六处逐条核对：每处由“灰盒 Label 可见”改为“灰盒 Label 隐藏（或空）+ 同一对象的 SYS-009 查询 available / in_range”，保留了原断言“靠近可交互”的含义；药包一处改为更严格的精确文字与真实可见。test_field_room 用 `in_range` 而非 `available` 的理由（交互冷却）成立 |

## 独立核对

**基线查询独立重采**：在临时工作树检出基线 `1f0cd6a`（未改任何文件），把交付 SHA 中的新测试脚本放到临时目录，用绝对路径执行 `--fixed-fps 60 --script <临时脚本> -- --query-only`，取 `CLN001_QUERY_TRACE` 与入库的 `game/tests/fixtures/cln001_interaction_queries.json` 逐例比较：**47 例键集合相同、0 例不同**（共 62 条目标记录）。夹具确实来自基线，修改前后 `interaction_targets()` 结果一致。临时工作树已移除。

**G1**（交付 SHA，各套件按首行登记的 fixed_fps；退出诊断无 SCRIPT ERROR、无 ObjectDB 泄漏）：

| 套件 | 结果 |
| --- | --- |
| test_world_prompt_cleanup（60） | 112/0 |
| test_exploration_room（实时） | 33/0 |
| test_environment_batch（60） | 116/0 |
| test_medkit_session（实时） | 68/0 |
| test_connection_room（实时） | 34/0 |
| test_field_room（实时） | 50/0 |
| test_town_rescue（实时） | 47/0 |
| test_ravine_rescue（实时） | 58/0 |
| test_outskirts（实时） | 24/0 |
| test_area_prompts（60） | 60/0 |

test_quest_interactions 与其余套件见 full。

**审查方变异**（与交付记录的 13 项不同，侧重“规则不变”的守护；逐项改源文件跑新套件，按原字节恢复并核对）：

| 变异 | 结果 |
| --- | --- |
| 拾取范围默认 80 → 81（只改规则，不改提示） | 杀死，12 项失败（查询比对） |
| 拾取可用性不再看暂停 / 可控（`not consumed and _can_pickup` → `not consumed`） | 杀死，4 项失败 |
| 外围幸存者救助后恢复“E / RB · 交谈” | 杀死，1 项失败 |
| 落石关闭后状态文字不显示 | 杀死，4 项失败 |
| 连接机关开启后丢掉“已开启” | 杀死，1 项失败 |
| 拾取物旧 Label 恢复“靠近即可见”但文字仍为空 | 存活 |

最后一项存活是预期的：空文字的 Label 可见与否在画面上没有区别，`no_key()` 有意允许“空文字或不可见”。不构成问题，记录在此供参考。

## 非阻断说明

- **N1**：被清空的 Label 节点仍保留在场景与脚本中（空文字、隐藏）。这是“只改文字与可见性”的最小改法，合理；正式美术替换这些 Room 时可一并删除节点。
- **N2**：`room_pickup.gd` 的 `can_collect()` 现在只被 SYS-009 查询与拾取判定使用，`refresh()` 中的 `prompt` 已固定隐藏；后续如果不再需要该 Label，可在美术整理时去掉。无需本任务处理。

## 独立 full

在交付 SHA、起点干净执行 `python codexandclaude/tools/run_checks.py full --jobs 4`：**通过**，G2 **91/91**，G3 **108/108 + 67/67**，**content_stable=True**，ObjectDB 泄漏 0 处，引擎报告 WARNING 行 0 处。摘要 `codexandclaude/runs/20261023T033111.856626Z/`（不入库）。审查记录写入前未改任何被测文件。

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`2764624d456addc84a31097606944726ba940e02`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-23T03:31:11.856626+00:00；结束：2026-10-23T03:41:53.537728+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际91 / 预期91；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`b9b888ea98715104877b2d27c90d65faecca5c65`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`5c0db13b50109d4cfd55f5e2dfc1127b551ef1a8aac2ba33540ccfc2384ef96e`；工作区范围指纹（原始字节）：`bb6da160bcd3966c894b74c767c76ecbe41724b06b222aa3012798b898a52611`。
全工作区指纹：`9ee319c55f6aae8d52615ba825ebe44368ef8deacc9b6810867f10692eb1a489`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T033111.856626Z\001.txt`；SHA256=`10cb71dfef0ec2d2abb518894c91fc05692297436faae358511274ea251cb529`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T033111.856626Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T033111.856626Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.297秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T033111.856626Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T033111.856626Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T033111.856626Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\claude\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\runs\\20261023T033111.856626Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=617.734秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T033111.856626Z\007.txt`；SHA256=`461f4ff46c44b3abf03378f124cb3e354dfecbcf6fc488319d9669ce67c04539`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.313秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T033111.856626Z\008.txt`；SHA256=`ae967875c6d072f4a338a7fd0a5ff7f485952eefaf69f8c27da6d0ee065c31ba`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=18.75秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T033111.856626Z\009.txt`；SHA256=`6be48bd57d96db13c9909cfbfd3254fbbc55c2b9e9c94fdee2a6fbd322300846`。
- 报告 `D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261023T033111.856626Z\engine.txt` SHA256=`598f8c5c779ce889fda8b6eaeece7c36e4312688f9ac7bae45335c21ed8b8416`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
