# DOC-010 第1轮审查

审查者：Codex｜日期：2026-10-25｜结论：**需修改：R1（P2，阶段顺序与相应回归）**。另有 N1 非阻断建议。未修改 Claude 实现、规格或测试，未合并 master。

## 固定对象与范围

- 基线：`68e8a9993e1327a96720ad506eada8d9184cf33a`；实现：`3bab3d52804d653269adb7662261753a82862de8`；交付：`3f3bd04767ebf0f8bdffd702bdc38cd999995fbf`。
- 在独立工作区先执行 `git switch --detach 3f3bd04767ebf0f8bdffd702bdc38cd999995fbf` 固定审查、G3 与变异，再从该点建立 `codex/DOC-010-review`，仅提交本记录。
- 基线到实现只改 T4 与 test_planning_documents.py 的 T4 断言；实现到交付只新增 delivery.md、更新任务卡首部（中间记录提交及计数更正的净效果一致）。没有夹带其他规格、代码或非 T4 测试变更。

## R1（P2）：§3.3 把协同战斗放在正式开战之前，且阶段错置未被测试拦下

位置：`Words/T4_3天倒计时系统.md:70`；回归位置：`tests/test_planning_documents.py:test_t4_is_current_spec_with_change_log`。

目前“临界流程”写成：

> 进入逆时战场 → 10救场与协同战斗（T2第10、11节）→ 最终战正式开战，进入末日临界阶段 → 在最终战预算内推进最终战

将“10救场与协同战斗”整体写在开始计算预算的节点之前，会读成先经过一段协同战斗，之后才进入计时的最终战。T2 §11 的“救场后依次为三波”就是最终大战的协同波次，不是额外的未计时前置战；同节紧接着规定正式开战时确定 min(15分钟, 第3日剩余)。T5.4 N004（第702～722行）在 N002 救场之后进入10共同作战并触发倒计时。旧 T4 的10-17修订也把救场后三波及正式开战预算写在同一最终战规则里，没有再定义一个协同战斗完成后的最终战起点。

**倒计时从“触发10剧情时”改为 N004 正式开战，本身有依据，成立。** R1 不要求恢复旧起点，而是要求流程行也遵守这个已澄清的边界：救场在正式开战之前，救场后的三波协同战属于正式开战后的预算窗口。可以将“协同战斗”放到正式开战节点后，或在同一节点明确“正式开战并开始三波协同最终战”；不增设新阶段，不改变现有波次。

独立探针只将第70行该片段改为：

`10救场与三波协同战斗全部完成（这三波不计入最终战预算）→ 最终战正式开战`

运行 `tests.test_planning_documents` 与 `tests.test_game_project`，**48/48 全通过**。说明当前回归只核对“正式开战时启动”等句子，不校验该流程与句子之间的一致性。请同时补充阶段顺序回归，使上述单点反写失败；原来的停表、不回补、保存、过期等检查继续保留。

## 修订去向核对

除 R1 外，逐项比对未发现其他阻断性改义：

- 顶部日期影响批次进入 §5 / §9；普通无色15/17、110%/120%、90%/80%、跨日不改已生成单位、高级敌人与 Boss 配置不变，以及 NPC 期限、已救助保留、旧已知未救且未放弃机会保护均保留。
- 10-14 配置更新及 §9 已解决的日期、Boss、临界计时、超时、存档边界进入 §2～§5；§9 保留日期敌人 / 地形及环境内容与阈值。未新增 Boss、地图或31天制作内容。
- 10-15 反复击杀收益、单死亡实例不重复结算、7完成后沟壑入口至少第2日；10-16 寄生同伴者通路至少第3日均保留，同次保存 / 失败回滚含时钟、防倒退 / 不重复补时未丢失。
- 10-17 的10数值、三波构成、普通死亡检查点归 T2 / T3，T4 引用其权威规则，不在此复写旧数值。时限 min、暂停、死亡 / 读档不回补、胜利停表、重试、保存失败不提前完成进入 §3.3 / §4。
- 10-18 自然计时的每日30分钟、物理时间、不计离线、停表范围、旧档字段兼容、已有第三日 / 最终战计时保留、每0.5秒等保存时机、探索超时与0余量保存失败、Esc不能绕过确认均保留。与 B-005 相反的 NPC 不失救旧句正确移除。
- 10-21 HUD 修订的地平线、06:00～24:00、换日 / 预告、A-016 视觉加速不改预算、读档不重播、关键色不变均保留。10章变更记录覆盖相应修订；§1～§9编号与标题保留。
- 旧测试仅将已经解决的六类 §9 边界改为现行规则和仍未决项，既有三条范围断言及其余 T4 测试保留；新增测试确实检查35条分节规则及正反方向，但尚缺 R1 的流程关系检查。

## 五条解释依据

1. **起点**：B-009、10-17修订和 T5.4 N004 支持正式开战，不是进入逆时战场 / 触发10救场；解释依据成立，但正文流程顺序仍须修 R1。
2. **不新增或强化敌人**：旧自然计时交付的阶段边界不是当前日期批次的最终规则，删去该过时概括、保留 §5 的明确日期变化与仍待设计项合理，不以代码反推规格。
3. **保存失败总括**：原10-17文本确有“保存失败均保留重试，不提前宣告完成”，覆盖开战、胜利、对话、结束保存；归并为一条合理，未改保存结果。
4. **旧档初始化**：缺少字段时初始化与已有字段原样保留是不同条件，可以并列；新版 §2 没有把已有计时重置成30分钟。
5. **过期 / 放弃**：独立触发且过期无奖励的原意保留，“两种独立情况”不引入多结局，成立。

## 非阻断 N1：预算术语可进一步区分初始值与当前余量

首部“正式开战时确定的倒计时”与后文“预算流逝 / 不回补 / 恢复本次开战预算”目前可按上下文理解；后续可明确“本次开战的初始预算”和“当前剩余预算”，避免把不变的重试基准与不断减少的剩余值当成同一个量。此条不要求新增字段或改规则，不阻断本轮。

## 独立检查与变异

固定交付上独立 G3 **111/111 + 67/67 通过**，起止干净、content_stable=True；摘要 `codexandclaude/runs/20261025T125931.607700Z/summary.json`。纯文档按矩阵不需要 G2。通过门禁不替代 R1 的语义核对。

每项仅改一处（换回旧全文除外），运行两个相关 Python 模块共48个测试，之后按原始字节恢复。下表“失败”按 unittest 失败 / 子测试条目计数，不与作者的不同反写措辞强求同一数字。无运行错误。

| 单点变异 | 失败条目 | 结论 |
| --- | --- | --- |
| 换回旧 T4 全文 | 2 | 拦下 |
| 同帧改回超时优先 | 4 | 拦下 |
| 写回自然日期不会自动判NPC死亡/失救 | 1 | 拦下 |
| 删除普通对话 / 放弃确认 / 死亡停表 | 1 | 拦下 |
| 删除死亡与正常读档不回补 | 1 | 拦下 |
| 删除 Esc / 继续不能绕过明确重试 | 1 | 拦下 |
| 起点改回触发10剧情 | 3 | 拦下 |
| 改成重复补时 / 倒退 | 1 | 拦下 |
| 删除旧槽已知未救 NPC 机会保护 | 1 | 拦下 |
| 三波协同战全部完成后才开始最终战预算 | 0 | **存活，见 R1** |

日志 `codexandclaude/runs/doc010-review-mutant-<name>.txt`，汇总 `doc010-review-mutations.json`（本工作区忽略文件）。固定交付已恢复且 Git 状态干净后，仅新增本审查记录；提交后另跑 G3，结果随最终回报。等待实现者修订，不合并 master。

## G3 自动摘要

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`focused`。
被测SHA：`3f3bd04767ebf0f8bdffd702bdc38cd999995fbf`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-25T12:59:31.607700+00:00；结束：2026-10-25T12:59:48.204934+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "focused", "--python-all"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G3:tests：实际111 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`75d9d62c5bd758cde697758a0decf4aae245d218`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`cc9566cb5fc48def36598156c25ae8f770817996d4e2ce04d7f46d54cf6dd4cf`；工作区范围指纹（原始字节）：`04d6d01f59dfb15987e042dd95de9bdf85a7a9e3fe1fac4c8609282990de043e`。
全工作区指纹：`307f371428c61861e7c688eb5df00e6aa1cebd013776f0c27642d3a080d03aaa`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T125931.607700Z\001.txt`；SHA256=`3c13062f2bbb5f32f15168e3771dd15c721aed2521c89431c6877be4e083a249`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T125931.607700Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.328秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T125931.607700Z\003.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T125931.607700Z\004.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T125931.607700Z\005.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.313秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T125931.607700Z\006.txt`；SHA256=`2bb0357e40ca9166a9ffbf32dd8acb6ecf7c58da58310702d954fd9412d8fe48`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=11.406秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261025T125931.607700Z\007.txt`；SHA256=`c9328297a60d33582d269bc103baaed52da5e7bd0018d187eee39bec77ce7760`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
