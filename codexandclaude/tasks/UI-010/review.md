# UI-010 第1轮审查

审查者：Codex｜日期：2026-10-22（America/Los_Angeles）｜结论：**需修改，两项P2**。

## 固定对象与范围

- 基线：`96f0400b08f770ee86d8385db2c0f9c29e5e31a1`。
- 实现：`6522d5a56abe8d0f064dec766041ae8345f8a57b`。
- 使用 `git switch --detach 95820e587d2fadde54f50300ba8264af482deb6d` 固定交付，起点工作区干净；实现到交付只新增 delivery.md、更新任务卡首部。
- 实现相对基线只改任务卡允许的新增HUD、LifeUI接线、FieldDialogue显示去向、文档、新套件与验收适配；旧测试和旧断言没有修改，未改会话规则、存档或输入。
- 隐藏GrayboxModels保留原quest/notice数据，show_notice()仍可调用并发noticed；绘制记录使用_paper/_bar/_ink返回值。正常排队、暂停/对话/剧情隐藏及等待有相应用例，以下问题发生在这些现有测试未覆盖的真实事件组合中。

## 阻断问题

### R1（P2）：任意任务信号都会覆盖左侧纸签，偏离当前quest_state与暂停菜单

位置：`game/ui/hud/quest_slip.gd:42–43`；关联 `game/world/field_session.gd` 的quest_state()与全局_quest_records()。

`quest_changed`是全局事件流，可在一次保存中发布多个任务的变化；`quest_state()`则根据当前Room选择当前任务。纸签收到任何信号都直接 `_take(value)`，把最后一个信号的任务当成当前任务，而且在Room和data字典身份未变时不会纠正。

在**未变异实现**上，用真实FinalBattleSession、独立临时存档、真实record_event()/save_current()复现：

1. 进入田野，真实保存HEAL_GUIDE，开始7的麦秆镇救助。
2. 将测试时钟日数置为第3日，再通过save_current()执行现有换日规则并发布实际SYS-009信号；不直接emit伪造UI信号。
3. 等4帧后，query为 `id=TY_10002_1`、`objective=麦秆镇救助已过期 · 更早抵达可帮助这里的人`，纸签却为 `id=HD_20001_3`、`objective=沟壑深处救助已过期 · 清敌仍可开启通路`。

这同时违反要求1“显示quest_state当前任务”和要求5“与暂停菜单同源”，不是中央队列依次显示多条过期事件的问题。请在事件到来时重新读当前query，或可靠过滤事件并刷新当前任务；中央提示仍可保留全局各事件，不修改SYS-009的范围或任务规则。新增回归须在Room/data身份不变、一次保存发布多个任务变化时比较纸签的id与objective同query/暂停菜单一致，不能只比较大家都相同的“已过期”状态文字。

### R2（P2）：1.5秒同文去重吞掉独立、保存成功的同名获得事件

位置：`game/ui/hud/center_notice.gd:81–87`；交付记录与game/docs/quest_notices_ui.md的去重规则1。

`push()`只按标题与下行相等就丢弃，不区分来源和真实事件身份。两个独立item_obtained信号完全可以有同样的名称与类别，这不代表同一事件重发。SYS-009已经只为新增、成功落盘的获得发信号，UI不应再次把相邻的独立获得合并掉。

在**未变异实现**上，真实探索会话中加入两件与既有测试相同方式构建的RoomPickup夹具：独立persistence_key `item:ui010:review_a`、`item:ui010:review_b`，同名“测试拾取”，逐次调用实际collect_pickup()，相隔2帧。两次均保存成功；独立监听观察到两个 `拾取:测试拾取` 信号，但history只增加1、队列只有1。不是重复emit，也不是保存失败或再次收集同一物品。

任务要求“同一事件不重复”，并不授权把不同事件因同文而吞掉。请区分权威事件与show_notice兼容文字：独立的获得/任务事件应保留，只有确实描述同一事件的文字与信号合成；仍满足同一事件不重复的要求。补回归：两个不同持久化key、同名、均写盘成功的拾取在1.5秒内得到两条并依次显示；同时保持同一事件的文字+信号只一条、保存失败无提示。同步更正文档中的去重定义，不能只把窗口调小。

## 独立复现证据

探针位于忽略的 `codexandclaude/runs/ui010_review_probe.gd`，继承现有真实会话测试夹具，使用唯一缓存目录并在退出前清理；没有读取或改写正式存档。实际命令：

`Godot --headless --path game --fixed-fps 60 --script D:/31days/codexandclaude/worktrees/codex/codexandclaude/runs/ui010_review_probe.gd`

结果 `UI010_REVIEW_PROBE checks=7 failures=2`、退出1，两个失败分别对应R1/R2；准备步骤（两次会话加载、任务保存、两件独立拾取）均通过。日志：runs/ui010-review-probe.txt。这些是原实现的新功能缺陷，不能因已有full或53项套件全绿而忽略。

另核对实际start_slot()/return_to_title()会重建场景，排除了最初的跨槽队列残留疑虑，没有将其列为问题。本轮不新增非阻断建议；发现上述问题后不扩展功能审查、不替实现者修复、不修改Claude分支，也不合并master。

## 独立检查与变异

固定交付SHA上独立执行 python codexandclaude/tools/run_checks.py full --jobs 4：退出0，G2 **94/94**，G3 **108/108 + 67/67**；现有新套件53/0。起止工作区干净、content_stable=True，ERROR / WARNING / ObjectDB泄漏均0。摘要：codexandclaude/runs/20261023T055140.644632Z/summary.json。

验收入口自检：

`Godot --headless --path game --fixed-fps 60 --script res://tests/acceptance/run_acceptance.gd -- --adapter=res://tests/acceptance/ui010_quest_notices.gd --self-test`

`UI010_ACCEPTANCE_TESTS checks=13 failures=0`，退出0，日志runs/ui010-review-acceptance.txt。这不是用户G4；交付阶段G4仍待用户。

为保持full干净，在full结束后才临时执行卡上四类门禁变异。统一命令：`Godot --headless --path game --fixed-fps 60 --script res://tests/test_quest_notices.gd`；逐项单独改、运行、finally按原字节还原并核对。

| 单点变异 | 独立结果（checks=53） |
| --- | --- |
| 读档refresh补发历史开始提示 | 3项失败，退出1 |
| 同文提示两次都保留 | 2项失败，退出1 |
| 写盘失败分支仍发获得信号 | 1项失败，退出1 |
| 中央提示不避让保存失败Label | 2项失败，退出1 |

日志与临时驱动：忽略目录runs/ui010-review-mutations/（含results.json）和runs/ui010_review_mutations.py。四类变异能被拦住，并不代表R1/R2的相邻事件组合已覆盖；没有将变异预期失败计为未变异full的失败。

后续：先合入本审查提交，保留记录，再修订实现、回归、文档并交复审。用户G4仍按流程验收，不能提前合并。

## 独立 full 自动证据

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`95820e587d2fadde54f50300ba8264af482deb6d`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-23T05:51:40.645632+00:00；结束：2026-10-23T06:02:15.079827+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际94 / 预期94；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.19.0`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`d16a1d52b729ada67e4082565d02b026ce6f3ae8`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`03c5e88a2d712673ae05c3800f192ac3a9361d3b19412ede68e05c9d95d7e9fb`；工作区范围指纹（原始字节）：`c944dfb8f2b20d1f21fc78d5a390e1165793d60852c05bac4cab1f5da726ffaf`。
全工作区指纹：`43e6d46b046fbe869cf8ac659741eb5c7d3c9fe0d94bb0a27040546a09afbc2c`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T055140.644632Z\001.txt`；SHA256=`e995087b751224ac245de5adf937bb878180227aa109ea43fa13263ae5e928c4`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T055140.644632Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T055140.644632Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.281秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T055140.644632Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T055140.644632Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T055140.644632Z\006.txt`；SHA256=`bc697de995dc791df53d688ef69c08994cdffc8ce30c906b1ffc65b131ccd0eb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\codex\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\20261023T055140.644632Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=614.766秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T055140.644632Z\007.txt`；SHA256=`b98c99d5998bdea61f3c92fc6cd719d222380e77995d238e43c2ae808ec1dfb4`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.39秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T055140.644632Z\008.txt`；SHA256=`f1949869f02c8839f7a4952317ee9c5617416443c540ee8c94d4bd6a94cf0835`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=14.656秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T055140.644632Z\009.txt`；SHA256=`b8e5dde2744691f246e87c39cc7ed9453029cb067f3305cfc1b6c016f1747cc9`。
- 报告 `D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T055140.644632Z\engine.txt` SHA256=`74b3804c79a48329ba838ece306f8c2ce6228929d87a84f1d49f9ea0763184ab`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。

## 审查记录 G3

审查记录写入后执行 python codexandclaude/tools/run_checks.py focused --python-all：G3 108/108 + 67/67，退出0。摘要：codexandclaude/runs/20261023T060341.739658Z/summary.json；仅review.md待提交，不作为干净G2复用来源。
