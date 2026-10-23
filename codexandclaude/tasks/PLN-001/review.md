# PLN-001 第1轮审查

审查者：Codex｜日期：2026-10-23｜结论：**需修改**（R1，P2；规划事实描述，不改游戏代码）。未合并 master。

## 固定对象与提交边界

- 基线：`519a7f66814b26ef3309184c3c1aa0f7d9bfc6a7`。
- 实现：`05ebf90a790f22fd636fecdaff70e4ffa10dd22b`。
- 原交付：`c4f52b508ea2971d3dd9db9c9676a76e59d731d6`。相对实现只有新增 delivery.md 与任务卡首部状态变化。
- 本轮固定对象：`418e6ece718305019c66ebd8693cecd4faeaa20f`，以 `git switch --detach` 固定。相对原交付只改 BOARD、ROADMAP、delivery.md、t7g_check.md；没有更改代码或验收入口。
- 总改动仅三份规划文档、本任务记录与状态、新验收适配及其 UID，在任务卡允许范围内。审查期间不修改 Claude 分支；本记录另建审查分支提交。

## R1（P2）：BL-118 的“四处同时过期”前提与实际规则不符

位置：`codexandclaude/BACKLOG.md:63`；同一描述还进入 `ROADMAP.md:158`、本任务 `delivery.md:42`。

新增待办写“第 3 日自然到期时四处救助同时过期”，据此提出合并四条提示。但 `game/systems/time/world_day_rules.gd:34-36` 明确区分两个时点：前三处在进入第 3 日时过期，`IDS[3]`（战场郊区）还必须满足 `day3_remaining <= 0`。完成、放弃或 legacy grace 还会排除相应机会。正常自然计时不会在第 3 日末首次同时产生四条过期信号。

**独立真实会话复现**：复用 `test_quest_notices.gd` 的隔离保存 / 加载与 cleanup，使用主线有效检查点、四处均未完成/放弃、规则已启用的第 2 日存档（剩余 1 秒）。监听真实 `quest_changed`，真实物理帧让时钟自然换日；再将夹具的第 3 日剩余设为 0.03 秒并由真实帧归零：

```text
ENTER_DAY3 day=3 expired=["TY_10002_1", "HD_20001_2", "HD_20001_3"]
END_DAY3 expired=["NSZC_10001_1"]
PLN001_EXPIRY_PROBE checks=3 failures=0
```

既有 `test_world_day_rules.gd` 的 `third-day boundary` 与 `outskirts still available before zero` 两条也验证了这一差别。探针没有修改正式代码、信号或期限。

UI-010 旧交付的“说明与未决”确有四处同时过期的说法，但本任务负责按现行代码刷新规划，不应将旧记录中的误述直接变为新待办的事实前提。否则后续会按不存在的自然场景设计消息合并，或把不同时点的独立事件错误地归并。

**建议修正**：仅更正文案，说明“进入第 3 日时，尚未处理的前三处可能同时过期；战场郊区到第 3 日余额归零才过期”，把候选议题写为“同一次状态更新产生多条过期提示时是否汇总”。同步 BACKLOG、ROADMAP 第 6 节与本任务交付表；是否汇总仍待用户裁决。不要改期限、消息队列或其他游戏规则，也无需回改 UI-010 历史交付来覆盖历史。修正文档后跑 G3 即可。

日志：`codexandclaude/runs/pln001-review-expiry.txt`，SHA256 `8d95d47324cb8b077071ae54d0b8e22fd7e8b713da853594a36fa52c333553f6`。审查临时探针在忽略的 runs 下，不入库。

## 已核对，成立的部分

1. **14 项关闭没有发现误关或漏记**：BL-040/041 → UI-004（系统 SYS-008/SYS-004）；BL-044 → UI-010/SYS-009；BL-045/049 → UI-007（数据 SYS-009）；BL-047 → UI-006/SYS-007；BL-048 → UI-008/EXP-004；BL-050/051 → UI-005；BL-054 → UI-009/EXP-004；BL-108/109/115 → ENV-007；BL-116 → CLN-001。逐行比对基线：只改变这些既有行的状态，没有删除编号或偷改需求；任务卡与集成记录均有完成依据。旧版死亡十二色手链演出明确留在后续，不算本版 UI-005 未完成。
2. **其他事项保留**：BL-022、BL-060、BL-065 仍是已立项；没有把 SYS-010 框架或 EXP-005 原型算作正式资源全部完成。BL-080/081、M3 正式资源、M5 日期内容、观察项保留。四个新增编号均唯一；BL-117 的 G-06 是可选建议，仍由用户决定，没有替用户采纳；BL-119/120 与 UI-007 原记录一致。
3. **汇总与快照**：三份汇总基线一致为 master@519a7f6；92 个专项加导入/主场景共 94 项，Python 为 108+67；现有 UI-001～010、CLN-001 路径和能力与代码一致。美术/音频仍为占位，台词与关键演出仍待 M3，不因界面正式化而误称正式素材完成。SYS-010“第1轮需修改”能由仓库审查提交 ff719c5 核对，未将其标为完成。
4. **T7-G**：直接读取工作簿“T7-G 最终验收”页，11 个项目和通过条件均与表一致。表中的英文断言原文能在所列测试中找到；抽查死亡恢复、分槽/永久事件、日期保存、同帧胜利/超时、WON 到结局等断言的实际条件，未发现把注释当作通过检查。体验判断单列，未声称第 11 项有自动测试。
5. **用户 G4 与 M2**：接受本轮用户转交的 2026-10-23 原话“完事了，没问题”、T7-G 11 项通过；其结果已在核对表与交付追加，M2 里程碑关闭有依据。R1 是新待办的事实修正，**不否定用户 G4，也不要求重开 M2 或重做游戏验收**。
6. **验收入口**：继承既有隔离 harness，三个槽按剧情顺序，夹具复用现有 UI-010/UI-002 路径；不改正式游戏规则或存档格式。独立自检 `PLN001_ACCEPTANCE_TESTS checks=15 failures=0`，临时目录由 harness 清理。自检证明入口可启动，不代替用户的体验验收。

## 非阻断建议

- **N1**：ROADMAP 首部仍写“待 T7-G 整体验收”，task.md 首部仍写“用户整体通关验收待进行”，与本轮追加结果相反。建议同步为 G4 已通过；任务整体仍待审查/合入，不能提前标已完成。历史变更记录里的“当时待验收”可以保留。
- **N2**：BL-048 的需求正文还写旧版“黑色半透明、角色名白色加粗”，与已批准方案 D 和 UI-008 后修订的 T7 表现不同。状态关闭有 UI-008 的实施与批准依据，因此不算误关；建议把待办正文也注明方案 D 的替代关系，避免今后按旧外观返工。

## 独立检查

固定对象上完整执行 `python codexandclaude/tools/run_checks.py full --jobs 4`，结果见下面自动摘要；没有沿用 Claude 的 full。G2 **94/94**、G3 **108/108 + 67/67**，起止干净、`content_stable=True`；引擎 ERROR、WARNING、ObjectDB 泄漏均 0。

另外执行：

```powershell
Godot --headless --path game --fixed-fps 60 --script res://tests/acceptance/run_acceptance.gd -- --adapter=res://tests/acceptance/pln001_campaign.gd --self-test
```

结果 **15/0**。日志 `codexandclaude/runs/pln001-review-acceptance.txt`，SHA256 `b6d855f2756dc743fac40ce3033a5668e28143e38913b5a8ef6098c9d81fb226`。

本轮无玩法修复或新规则，不对正式代码做无关变异；R1 以真实时钟/信号探针和既有边界测试交叉验证。现有 G3 结构检查能证明基线一致与分配完整，不能证明每条新待办的自然语言事实正确；所以检查全绿仍需修正 R1。

## full 自动摘要

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`full`。
被测SHA：`418e6ece718305019c66ebd8693cecd4faeaa20f`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-23T10:21:35.648586+00:00；结束：2026-10-23T10:32:09.134556+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "full", "--jobs", "4"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G2：实际94 / 预期94；完整=True；通过=True。
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- godot：`4.7.2.stable.official.ed1daf0bf`；`D:\DMyself\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`。
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`cdbb60293ae63c82cc34e474f73c86d8594cc686`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`9dec12ffca39555b0bf91f801bb17770791dbe521014d3a66f4667df113f7a76`；工作区范围指纹（原始字节）：`6a35ca265206ed60c24619f4b8ff8121560ac7e4315ad03fc44ea717b42e3189`。
全工作区指纹：`8e0d5ba942602a671e114d98eea0d5ac39362d02541b1c49e47b7925a18d6953`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T102135.648586Z\001.txt`；SHA256=`8571cefd3e560476ed18d6834d9e3e51fce7646e7d3d517ee4b0189abf117838`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T102135.648586Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T102135.648586Z\003.txt`；SHA256=`bf8803022b574250bb04dea65053a46b7c58570725316c1f7fe2aa6735706498`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.266秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T102135.648586Z\004.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T102135.648586Z\005.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T102135.648586Z\006.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\scripts\\verify_game.py", "--godot", "D:\\DMyself\\Godot_v4.7.2-stable_win64.exe\\Godot_v4.7.2-stable_win64_console.exe", "--project", "D:\\31days\\codexandclaude\\worktrees\\codex\\game", "--report", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\runs\\20261023T102135.648586Z\\engine.txt", "--jobs", "4"]`；退出=0；耗时=618.25秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T102135.648586Z\007.txt`；SHA256=`81b8bc5835618a0f52b6cc4b9b41c7035a5712a670ec78181833ce9112c50892`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.125秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T102135.648586Z\008.txt`；SHA256=`0ca9d0edab834bdf35620408c0db93f74f50a75f600f802056a6a0cd8937cd73`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=10.688秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T102135.648586Z\009.txt`；SHA256=`a3e3231b10cf439f36f17e01d854e364830aeeb708c0ca9537833b3b1d97ccda`。
- 报告 `D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T102135.648586Z\engine.txt` SHA256=`0f7ac848948f3ace7669d5d9934b0dd69da45b9d468a2ae0dd9382a1943933a5`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。


## 第2轮复审：第1轮 R1 修复（2026-10-23）

结论：**通过，无阻断项**。首轮 R1 已解决；首轮记录完整保留，本节为最新结论。未合并 master，待用户授权。

### 固定对象与范围

- 用 `git switch --detach f222bd60061208059165e12fc548fbf6a84e595d` 固定本轮修复提交。
- 它是首轮审查 `6236d74d835bb208271080f0addf07b86975b4cb` 的直接后继，修复与交付说明同一提交；仅修改 BACKLOG、ROADMAP、本任务 delivery.md（三个文档，9 行新增、3 行删除）。
- `git diff 6236d74 f222bd6 -- game Words codexandclaude/tasks/UI-010` 为空；没有修改游戏规则、测试、验收入口或 UI-010 历史记录。14 项状态关闭、G4 记录和 M2 完成结论未改。

### R1 核对

| 位置 | 结果 |
| --- | --- |
| BACKLOG BL-118 | 已区分麦秆镇、沟壑救助、沟壑深处在进入第 3 日时过期，以及战场郊区在第 3 日余额归零时过期；引用 `WorldDayRules.expired()`，来源列明确旧交付的“四处同时过期”表述有误 |
| ROADMAP 第 6、7 节 | 对应事项同步为三处同时提示，第四处另行过期；新增变更记录，没有替用户决定合并提示 |
| delivery.md 新增条目表与修复节 | 同步两个时点，承认照抄旧记录未核对的原因，说明不改历史交付与其余状态 |

重新对照 `game/systems/time/world_day_rules.gd` 的 `expired()`：前三处以 `day >= 3` 判定，`IDS[3]` 另需 `day3_remaining <= 0`；完成、放弃或 legacy grace 仍按代码排除。本轮修正文案与首轮真实会话探针的“3 条 + 1 条”结果一致，没有反向修改规则。汇总建议仍限同一时刻的多条过期提示，状态保持待用户决定。

首轮 N1（首部待验收文字）与 N2（BL-048 旧外观正文）本轮没有处理，仍为非阻断建议，不影响通过；本轮未发现新增阻断项。

### 独立检查

固定修复提交、干净工作区执行 `python codexandclaude/tools/run_checks.py focused --python-all`：**G3 108/108 + 67/67 通过，content_stable=True**。本轮只有规划文档变化，按矩阵无需重跑 G2；首轮 full 与 15/0 入口自检保留为历史证据，不冒称本轮重跑。没有新玩法或代码变更需要新增变异。

以下为本轮 G3 自动摘要：

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`focused`。
被测SHA：`f222bd60061208059165e12fc548fbf6a84e595d`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-23T17:01:27.183880+00:00；结束：2026-10-23T17:01:43.006684+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "focused", "--python-all"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G3:tests：实际108 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`fdf447647dda0e9c077f8d2a7bd813181dd64ddb`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`ecaf653439216c08cb9db53e9a96fa6658010858859b45341e628b80ba3c6bbc`；工作区范围指纹（原始字节）：`dabc558668fd8e4de017bf861eb129ed940c0c477d101030c6c67ef5acb2c9c1`。
全工作区指纹：`8932d05e610bf30c82b4e357dd10c5cf829ea267d6c7cabb66a4bfdc96aa0182`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T170127.183880Z\001.txt`；SHA256=`998d094d2c62c919eb6cc6f1406e703140439fd73d512a22698d93641ab33bf2`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T170127.183880Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.312秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T170127.183880Z\003.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T170127.183880Z\004.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T170127.183880Z\005.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.344秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T170127.183880Z\006.txt`；SHA256=`4d24910fc12294f986620d4964ec5c344343f5a4ae4f0d393dab45b05172a3e8`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=10.953秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T170127.183880Z\007.txt`；SHA256=`6f5456425ccda7c0ba732bcce6c41f9ca3937c2267c43a168e30625abdbe4687`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
