# SYS-009 交付记录

日期：2026-10-22（America/Los_Angeles；自动摘要使用 UTC）。
分支：`codex/SYS-009`。
基线：`2f79b8311155826301509c0cb6c26691f4a1e2c9`。
实现 SHA：`ba6fae3ed1f129e6c89e2a70739b94901c57f755`（含初始实现 ef560f0 和继承链查询修正）。

## 批准依据与范围

按用户第六批已批准任务卡开工。两项实施中解释得到用户明确答复：

1. 无距离限制的 Boss 补领与 Area2D 介绍重试不能用一个圆形半径准确描述。用户选择“采用原始范围类型（推荐）”：普通圆保留半径，另外两种 radius=null，增加 range_kind、in_range，区域另有世界 bounds。
2. 现有 E/RB 路径未统一阻止普通对话期间的场景动作，用户选择“允许补齐对话门禁（推荐）”：普通场景动作与查询都阻止；对话推进、数值与剧情保存重试保持原状。

未改正式 UI、LifeUI、输入映射、project.godot、存档字段/格式、资源配置、数值、救助条件或计时规则。旧测试文件与断言完全未改。BOARD/BACKLOG/ROADMAP 留给规划维护者串行刷新。ENV-007 与本任务各自直接基于同一个指定 master，未把尚待 Claude 审查的 ENV 实现带入 SYS。

## 实施与接口

- CheckpointLab 增加三个数据出口及内存观察缓存；Field/Town/沟壑/深处/外围提取原目标文字，结构化状态读同一组永久事件和 WorldDayRules。四个救助的状态变化各自去重；目标文字变化可发进展，不重复完成。
- 恢复中及恢复完成后建立基准，不补发历史任务信号。界面初次连接、读档后先读 quest_state，再监听后续变化。查询返回独立值，不触发保存或信号。
- 获得通知比较成功写盘前后的永久来源，失败不更新基准；延后到外层成长同步完成后发信号。读档已有物品不重播，旧档首次成功补领照常发。恢复另一份会话会使旧 deferred 通知失效。
- 覆盖珍珠、配置拾取、药包、战斗/闪避强化、7 的注视和延后救助成长。资源击杀仍由既有 gained 负责。
- 各会话 interaction_targets 沿继承链追加本层对象。拾取、NPC、开关、检查点、介绍重试、补领等沿用原方法、原半径与原坐标基点；仅抽出共享谓词。补领截获低层输入只影响它下面的分支，不能遮掉其上层继续响应的 NPC。
- 只新增登记套件 test_quest_interactions.gd 及编辑器生成 UID；共享说明在 game/docs/ui_data_interface.md。全部源文件在卡允许的 game/debug、game/world、game/tests、game/docs 范围，任务卡只改首部。

## 需要审查者留意

1. 自动药包与自动检查点/遭遇不是 E/RB 对象，不虚构按键交互目标；药包仍发保存成功后的获得信号。已取得拾取移出查询，已操作开关和检查点可以保留不可用条目。
2. 普通对象 available 在暂停、对话或剧情控制锁中为假。但最终战启动/结局、10救场、尖刺挑战等锁定状态本来就以 E/RB 重试保存，不能用普通对话门禁把它们禁掉：这些条目 available=false、另有 retry_available，原输入重试保留。范围标记与这一例外在接口说明中列出。
3. 拾取/开关从身体中心测距，NPC/检查点从脚部测距；外围 near 还包含尖刺关闭条件；天人介绍以玩家矩形和原 Area2D 重叠。均按原始判定保留，没有近似或统一规则。
4. 任务状态“无”时仍可能有原有提示文字；仅目标变化且枚举不变时发进展。Room 切换不把旧任务重播为新任务。
5. 同一普通输入中，下层补领返回后，上层仍可开始 NPC 对话。实现中复查发现的错误统一遮罩已移除，单独回归及反向变异覆盖。

## 检查与过程记录

先写缺失 API 回归，基线 2 项失败；实施后扩为真实 FinalBattleSession、独立临时槽的 316 项。覆盖四个救助开始/完成/放弃/过期、未变不发、读档不重播、真实麦秆镇救助与7结算、各类获得失败回滚/重试/持久化先于信号、延后成长，以及各类圆形、无限、区域交互与实际输入。

夹具首轮曾失败：外围缺少尖刺/强化前置记录、对话仅改 active 未建立配置、尖刺影响后续控制状态、最终战启动缺少10救场前置。都修正为满足既有规则的真实夹具，未放宽断言、未改游戏规则；失败日志 sys009-quest1/2/3/7.txt 留在 runs。

G1 命令均为 `Godot --headless --path game [--fixed-fps 60（登记要求时）] --script res://tests/<suite>.gd`，按登记 timeout、4并发执行，退出0、无错误/泄漏。新套件与 ui_data 使用 fixed-fps=60，其余沿登记不加。各套件结果：

| 套件 | checks / failures |
| --- | --- |
| quest_interactions（最终修正后） | 316 / 0 |
| campaign | 166 / 0 |
| town_rescue | 47 / 0 |
| ravine_rescue | 58 / 0 |
| ravine_depth | 71 / 0 |
| outskirts_rescue | 41 / 0 |
| pearl_growth | 212 / 0 |
| medkit_session | 68 / 0 |
| combat_growth | 67 / 0 |
| dodge_growth | 45 / 0 |
| ui_data | 54 / 0 |

前四项变异在311项版本上执行，相关被改源在最终提交未变化：

| 变异 | 失败项 / 退出码 |
| --- | --- |
| 任务未变化仍发信号 | 12 / 1 |
| 保存失败仍发获得信号 | 13 / 1 |
| 拾取查询忽略实际范围 | 1 / 1 |
| 剧情锁定仍报可用 | 7 / 1 |
| 恢复错误继承链统一遮罩（316项） | 1 / 1 |

所有变异检查后恢复原始字节。原日志 sys009-mutant-*.txt、G1明细 sys009-g1.json 在 runs。

首个 full（ef560f0，runs/20261022T070027.772843Z）在实现者复查发现继承链查询错误后主动中止，不作完整通过证据。修正提交 ba6fae3 后重新从干净工作区执行完整 full，结果见下方自动摘要。未以重试掩盖失败或引用中止运行。

本任务不需 G4；尚未合入 master，交 Claude 独立审查。交付首部与本记录写入后再跑 G3。

## 内容稳定性与复用

最终 full：content_stable=False，起始 dirty=False，结束 dirty=True（两项编辑器生成 UID 未跟踪）。

本基线的编辑器导入会生成 EXP-003 两项未跟踪 UID（BL-115），所以本次 full 不能作复用来源；检查通过结论照实保留。相同两项 UID 已在独立 ENV-007 交付中修正，并有同一干净 SHA 连续两次 content_stable=True 的 full。此处不越范围重复纳入，待审查合入后按 ENV-005 对实际集成内容重新建立证据。

## 自动摘要：完整 G2+G3

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`ba6fae3ed1f129e6c89e2a70739b94901c57f755`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-22T07:04:30.954628+00:00；结束：2026-10-22T07:17:21.613504+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际89 / 预期89；完整=True；通过=True。
- G3:tests：实际102 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`51f95fc59f8ff9e7760df083527c2a8dd8b4a9ab`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`845a8709b4d96e7bc74fa283b15bb3a508e1e81faf8d314bbfc033246741067e`；工作区范围指纹（原始字节）：`aaa13adcc09f095c48b7dfc96611f81f189e2872ef850fd3d0b248a0f929ca68`。
全工作区指纹：`8443b792738bd16f8ca5ff012044b08af6627bf568152ad2b58032d9123d84d0`；运行前后内容稳定：`False`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T070430.954628Z\001.txt`；SHA256=`b3a5678f0f2d5dcdaaef152c882b1ddc729c3251368002899a27422a0604be8b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T070430.954628Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T070430.954628Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.297秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T070430.954628Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T070430.954628Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T070430.954628Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\codex\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\20261022T070430.954628Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=754.375秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T070430.954628Z\007.txt`；SHA256=`8ebf23cf12f0c4516c5c5b27615106537596ed7be2ba49b34dc88f93c99c304d`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.36秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T070430.954628Z\008.txt`；SHA256=`713cff708a95f94feec8b2ca64eb6d21aef5dbcd84c12070914d7f4e7dd08314`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=11.39秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T070430.954628Z\009.txt`；SHA256=`d4b38f0b03bc2c478d9a68b4beb4ecd759f37dcbc80eef612b3546790552ca8a`。
- 报告 `D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261022T070430.954628Z\engine.txt` SHA256=`5c5a43c551b2b65d50575bf4fcad08b47d740c77207174ce152d3aa21f7cbdf0`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
