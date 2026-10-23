# CLN-001 交付记录

实现者：Codex｜日期：2026-10-22（America/Los_Angeles）｜级别：S｜状态：待 Claude 审查。不合并 master。

## 批准、基线与提交

用户批准第七批四张卡，并要求先完成 UI-007 收尾、合入第七批规划，再开工 CLN-001。UI-007 已在上一轮以 fd40f74 完成 master full、集成证据与状态收尾，本轮核对后没有重复执行。

- 第七批固定规划：`164cd977bcf8496fe217d223c39a42e3ad6ea89e`。
- 规划合并：`1f0cd6a5735ae07f16c1e270fc0a2cf7620735a0`；BOARD 唯一冲突按用户要求保留 UI-007 已完成与四张新卡。master G3 108/108 + 67/67 通过，摘要 codexandclaude/runs/20261022T150850.591496Z/summary.json。
- 本任务基线（完整 SHA）：`1f0cd6a5735ae07f16c1e270fc0a2cf7620735a0`。
- 分支：`codex/CLN-001`；工作区：D:/31days/codexandclaude/worktrees/codex。
- 实现 SHA：`adfbc6f73e1b5b8dd446401a30a8a1acf999df4c`（首个实现提交 6e70090，随后只修正新增测试的资源路径）（10 个约定 world 文件、6 个旧测试、新套件及 UID、基线查询夹具、任务卡首部）。交付提交只增加本记录并将任务卡首部改为待审查。

## 逐项清理与保留

| 对象 | 去掉的重复文字 | 保留的信息 |
| --- | --- | --- |
| RoomPickup | `E / RB · 拾取××`；原 Label 留空并隐藏 | 拾取物本身、关键物品高亮、拾取后隐藏照旧 |
| RoomRockfall | 未关闭时 `E / RB · 关闭本间落石` | 已关闭且原范围内显示“落石已永久关闭” |
| ConnectionRoom Switch | 清敌但未开启时 `E / RB · 开启前路` | 原范围内“需要先清敌”“已开启”；ReturnLabel、ExitLabel 照旧 |
| Seven：ty_10001_1.tscn | 场景初始“E / RB · 交谈” | NPC 名字“7”；会话仍按原条件控制空 Label，不改会话脚本 |
| TownRoom：ty_10002_1.tscn 与脚本 | 初始及刷新中的“E / RB · 救助 / 交谈” | 幸存者名字及已救助／失去机会等状态名 |
| RavineRescueRoom：hd_20001_2.tscn 与脚本 | 初始及刷新中的“E / RB · 救助 / 交谈” | 沟壑幸存者状态名 |
| OutskirtsRoom：nszc_10001_1.tscn 与脚本 | 初始及刷新中的“E / RB · 免费救助 / 交谈” | 外围幸存者状态名、尖刺与通路状态文字 |
| MedkitSupply | 无需删除：它是自动拾取，不是 E/RB 对象 | 完整保留“靠近自动拾取 · 应急药包”“药包已满 · n / 3”，脚本未改；加强状态回归 |

只改提示 Label 的文字与可见性。没有改会话、交互范围、判定、SYS-009、存档、输入或 UI-007 正式提示；`$Instructions`、碎石堆、最终战 StageLabel、NPC 名字等卡外内容未清理。未改其他规划文档或 BOARD 状态。

## 旧断言适配（共六处）

| 套件 | 原检查 → 新检查与保留含义 |
| --- | --- |
| test_exploration_room | 附近未领取珍珠及灰盒 Label 可见 → 物体可见、灰盒 Label 隐藏，真实查询中同一物品 available；领取、写盘、回滚等断言保留 |
| test_environment_batch | 附近落石开关 Label 可见 → 灰盒 Label 隐藏、真实查询中同一开关 available；四房间实际 E 关闭、永久保存、回滚等照旧 |
| test_connection_room | 清敌后附近开关 Label 可见 → Label 隐藏、同一机关查询 available；清敌、激活、写盘等断言不变 |
| test_field_room | 附近 Seven 的 Label 可见 → Label 文字为空、同一 Seven 查询 in_range；这与原断言的靠近含义一致，不额外要求对话冷却结束 |
| test_town_rescue | 附近救助 Label 可见 → Label 隐藏、同一幸存者查询 available；实际救助输入、资源、回滚等保留 |
| test_medkit_session | 物体可见、文字含“已满”、未领取 → 额外要求 Label 真正可见且文字精确为“药包已满 · 3 / 3”；其他条件保留，未改自动拾取规则 |

## 新回归与修改前后查询比对

新登记 `game/tests/test_world_prompt_cleanup.gd`（UID 一并入库），复用 test_quest_interactions 的真实 FinalBattleSession、Room 与隔离存档夹具，没有替换或模拟 interaction_targets()。

在 world 源码仍为基线时，先运行新套件 `--query-only`，采集 47 个同一用例的完整查询数组到 `game/tests/fixtures/cln001_interaction_queries.json`；修改后由套件逐个精确比对所有字段（含对象 ID、动作、位置、radius/range_kind、in_range、available、key_item 及数组顺序）。覆盖普通／关键拾取物靠近、超距、暂停、领取后，四个落石开关关闭前后，连接机关未清敌／可开／已开，四个 NPC 的展示状态，以及四处药包未满／已满。Vector2/Rect2 只转为数值数组供 JSON 保存，不删查询字段。

另查四个场景初始 Label，避免只测试刷新后的空文字而漏掉初始残留；保留状态的断言读取真实 Label 文字和可见性。新套件最终 **112/0**。原始采集日志 codexandclaude/runs/cln001-baseline-queries.txt，47 例均执行。

复现基线采集时，可先将实现 SHA 中的新测试脚本复制到忽略的 runs 路径，在基线 1f0cd6a 的独立工作区用绝对脚本路径执行 `Godot --headless --path game --fixed-fps 60 --script <脚本绝对路径> -- --query-only`；取 CLN001_QUERY_TRACE 行，与入库 JSON 比较。基线无需修改正式源文件，也不读取玩家正式存档。

## G1 与变异检查

G1 按各套件首行登记的 fixed_fps 参数运行，全部通过，退出诊断无 ERROR、WARNING、ObjectDB 泄漏：

- test_world_prompt_cleanup：WORLD_PROMPT_CLEANUP_TESTS checks=112 failures=0。
- test_exploration_room：EXPLORATION_ROOM_TESTS checks=33 failures=0。
- test_environment_batch：ENVIRONMENT_BATCH_TESTS checks=116 failures=0。
- test_medkit_session：MEDKIT_SESSION_TESTS checks=68 failures=0。
- test_quest_interactions：QUEST_INTERACTIONS_TESTS checks=316 failures=0。
- test_area_prompts：AREA_PROMPTS_TESTS checks=60 failures=0。
- test_connection_room：CONNECTION_ROOM_TESTS checks=34 failures=0。
- test_field_room：FIELD_ROOM_TESTS checks=50 failures=0。
- test_town_rescue：TOWN_RESCUE_TESTS checks=47 failures=0。
- test_ravine_rescue：RAVINE_RESCUE_TESTS checks=58 failures=0。
- test_outskirts：OUTSKIRTS_TESTS checks=24 failures=0。

13 项变异逐项修改、运行新套件后按原字节恢复；均跑满112项、退出1，不是编译失败：

| 变异 | 失败项数 |
| --- | --- |
| pickup_key | 4 |
| rockfall_key | 4 |
| connection_key | 1 |
| town_key | 3 |
| ravine_key | 3 |
| outskirts_key | 3 |
| rockfall_state | 4 |
| connection_state | 1 |
| medkit_full | 4 |
| ty_10001_1_initial | 4 |
| ty_10002_1_initial | 1 |
| hd_20001_2_initial | 1 |
| nszc_10001_1_initial | 1 |

本地明细：codexandclaude/runs/cln001-g1-registered-results.json、cln001-mutations.json 与对应日志（runs 不入库）。

## 过程中的问题

- 首次适配 Seven 旧断言错误要求 available，忽略旧 Label 只证明靠近、会话还可能有未结束的交互冷却。已改为同源 in_range + 空文字，恢复原检查含义；最终 FIELD_ROOM 50/0，查询套件另覆盖冷却、对话等可用性。
- 临时 G1 命令曾给所有套件强制 --fixed-fps 60，偏离旧套件登记的 null／实时参数；探索与外围套件断言通过但退出各有2个 ObjectDB 泄漏，不能把该轮记为通过。--verbose 捕获外围泄漏为 AudioStreamWAV 与 AudioStreamPlaybackWAV。没有据此改游戏或收尾时序；按原登记参数完整重跑11套件均无退出诊断，随后以正式 full 继续验证。原日志保留：cln001-g1-results.json、cln001-exploration-verbose.txt、cln001-outskirts-verbose.txt。此处仅报告观察，不宣称证明音频释放的根因。

- 首轮干净 full（6e70090，摘要 codexandclaude/runs/20261022T152306.156952Z/summary.json）G2 91/91 通过、无退出泄漏，但 G3 的 test_all_resource_references_resolve 将新测试动态拼接的 res 路径前缀当成文件而失败，协作 G3 未执行，整轮不通过。已在任务允许的新测试内改为四个完整 preload 路径，未改检查器；修正后专项112/0、G3 108/108 + 67/67 通过，四个初始场景恢复文字变异再次失败4/1/1/1项。修正提交 adfbc6f 后从干净工作区重跑 full，下面只粘贴最终运行证据。

## 实现 SHA 上独立 full 自动证据

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`adfbc6f73e1b5b8dd446401a30a8a1acf999df4c`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-22T15:36:32.127131+00:00；结束：2026-10-22T15:47:00.029139+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际91 / 预期91；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`96efaba61f054571051311721797e5dc627b8723`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`fbdf083639fa9562f2d33b0e04220cb712406eb7457ae3cae903356774a096fc`；工作区范围指纹（原始字节）：`b2543e7a8ab900e04328e38877ad381ef7c18c93513d6062904dffac3ba9e648`。
全工作区指纹：`e4e36bb5f7a7278ae61300de2e95bcfd4bb60ed4ae59a6324f550743326ba62c`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T153632.127131Z\001.txt`；SHA256=`9515dd63c054727f704dc50bd0098372e750c44bf041e12840390b0a1982e568`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T153632.127131Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T153632.127131Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.281秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T153632.127131Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T153632.127131Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T153632.127131Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\codex\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\20261022T153632.127131Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=609.859秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T153632.127131Z\007.txt`；SHA256=`c37ebbdb95c20eb3e70936a2de42143d613e938c7c11ba28e3bef24e00801a93`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.141秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T153632.127131Z\008.txt`；SHA256=`0ca9d0edab834bdf35620408c0db93f74f50a75f600f802056a6a0cd8937cd73`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=13.312秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T153632.127131Z\009.txt`；SHA256=`0accdcdac8d81290dc8bc924615c450b441504fe51b1a95b19ddb00792b43778`。
- 报告 `D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T153632.127131Z\engine.txt` SHA256=`eef6dc0fa4232773fd1abb971ed07dc80ed170905213b5f310899ac95fe2f323`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

## 交付文档 G3

交付文档提交前 focused --python-all 通过：G3 108/108 + 67/67，退出0。摘要 codexandclaude/runs/20261022T154749.549640Z/summary.json；此次仅任务卡首部与本记录待提交，不作为干净 G2 复用来源。
