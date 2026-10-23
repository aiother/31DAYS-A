# DOC-008 第1轮审查

审查者：Codex｜日期：2026-10-23｜结论：**需修改：R1、R2，均 P2**。八条解释依据基本成立，但两类仍有效约束在改写中遗漏。G3 通过不代表规则迁移完整。未修改 Claude 实现分支，不合并 master。

## 固定对象与边界

- 基线 `c60f2aeb9af10539bfd829d98207a683630a7e31`，实现 `7abae7a6673fa220fd3ea4dc05444f167cc63822`。
- 用 `git switch --detach 8726ab4e3b5fad1b26a881f1933a607376c9251b` 固定交付；实现仅 T2 与 tests/test_planning_documents.py，交付仅新增 delivery.md 与任务卡首部。没有改正式游戏代码、其他规格或协作工具。
- 原 §1～§15 编号与标题保留，补丁/追加段已收进正文和 §16 表；有效的单次伤害、奖励、六项收束、实现后运行验证等既有断言保留。T3 引用的 1/2/3 成本、1.3 秒、-9、恢复 3→2 / 2.8 秒、环境伤害 1～2 均与原冻结条目相符。

## R1（P2）：攻击范围成长的持久化/旧档兼容约束没有完整并入正文

位置：`Words/T2_战斗系统.md:34`，以及 delivery.md 对照表“追加 6”“追加 9 附记·珍珠范围强化”。

基线 T2 第 266 行的用户确认珍珠修订明确写“仅按当前槽四个旧永久拾取键重建，不新增存档字段；旧档自动生效”。新 §2 虽保留四个地点、5%/20%/140%、保存成功授予和分槽，却删除了这三个约束。当前“已有……旧档自动补发”只修饰渴望俯视，不能替代珍珠的旧档自动生效。这样只读现行 T2 的后续实现者可以误认为需要新领取标记、数量字段或旧档迁移，改变已批准的存档兼容契约。

同段合写渴望俯视时，基线第 241 行“消费原 combat_growth_pending”“claimed 与 pending 互斥”也未保留。这是旧领取状态转换和防重复约束，不能与测试项数、历史阶段描述一起删去。可用易读的现行表述，不必把字段说明扩成长篇实现细节。

**请修复**：§2 的保存规则补齐珍珠按四个旧永久来源重建、无新增字段、旧档自动生效，以及 Boss 旧待领取被消费、已领取与待领取不并存；在对照表中核对说明，补相关回归。无需改 T3、game/docs 或存档实现。

独立在内存中把当前珍珠保存句改成“需新增专用存档字段记录数量，旧档不自动生效”，PlanningDocumentsTests 仍 **35/0**；当前测试没有拦住相反兼容规则。这个探针只说明缺口，不是声称当前文档已经主动要求新增字段。

## R2（P2）：下行追击活动路线的暂停与超时失效规则丢失

位置：`Words/T2_战斗系统.md:90-96`，delivery.md 对照表“追加 5”。

基线第 234 行的 2026-10-17 下行追击修订明确“活动路线支持暂停、既有打断及超时重规划”。现行 §7.1 迁入下行的地形与落差条件，却没有迁入活动路线暂停与超时重规划；“无进展时退出并重新规划”不等于路线按超时失效，末尾“既有打断规则”也不描述暂停时路线计时如何处理。第 10/11 节的暂停仅针对救场/最终战，不能作为敌人追击路线的现行定义。

这里无需从代码反推规则：原已确认的 T2 本身就有上述要求，所引用的平台追击说明也明确暂停冻结移动与超时、路线超时退出。删测试统计合理，删这句有效行为约束不符合任务卡“全部追击修订并入正文”。

**请修复**：§7.1 补回活动路线支持暂停（含路线超时冻结）、既有打断及超时退出重规划的现行文字，并补正文回归；不用新增/冻结原 T2 未列出的超时秒数，也不改实现。

## 修订去向逐项复核

| 原条目 | 核对结果 |
| --- | --- |
| 顶部日期批次 | §8.1 的对象、15/17、110%/120%、90%/80% 与排除范围保留 |
| 顶部 10-15 标记 | 取消减速，跑攻倍率与 0.5 秒保留，下攻击 50%；与原 §2 及后续修订一致 |
| 顶部 10-14 配置 | §10/11 按较新三条件与全部清除覆盖旧段，合理 |
| 行内：2 段 / 0.5 秒 | §2 保留按键时刻、含边界、缓冲不延长及打断重置 |
| 行内：取消减速 / 跑攻 | §2 拆条，倍率锁定、活跃时间与灰盒数值保留 |
| 行内：闪避取消攻击 | §2 地面/空中、使用条件、跳跃不打断均保留 |
| 行内：下攻击弹起 | §2 的最大跳高 50%、离散补偿和跳跃键限制保留 |
| 行内：正常移动 / 跳跃 / 转向 | §2 分条，没有解除单次方向锁定 |
| 行内：滑步用途 | §5 地空共用计数/成本/透支保留，删去覆盖历史合理 |
| 行内：闪避取消 | §5 保留地空及资源条件 |
| §3 受击打断修订 | §3 保护阶段、扣血反馈、致死优先与预留 STAGGER 保留 |
| §8.2 单色灰盒 | 数值、低血冷却、退路检查及动作取消窗口保留 |
| §8.3 天人灰盒 | 数值、格挡破绽、共享名额与自由操作介绍保留 |
| 追加 1：救场与协同 | §9～11 移入有效规则，旧前后摇和一轮协同被较新修订覆盖合理 |
| 追加 2：秒杀展示 | §10 保留 0.35 / 1.2 / 1 秒时序、空场、暂停、不可跳过和失败重试 |
| 追加 3：强化与最终战 | §9/11 数值、三波、增援、预算、死亡/超时、胜利保存与结束保留 |
| 追加 4：平台上行 | §7.1 上行、950/1 秒、遮挡与碰撞保护保留 |
| 追加 5：平台下行 | 地形规则保留，但活动路线暂停/超时遗漏，见 R2 |
| 追加 6：Boss 范围强化 | 范围/事务主体保留，旧领取转换与互斥遗漏，见 R1 |
| 追加 7：bug2 绕行 | §7.1 96 / 960、重新扫描、遮挡与安全走行保留 |
| 追加 8：bug3 矮台 | §7.1 登台再下、后退与路线比较保留 |
| 追加 9：bug4 | §7.1 有向路线、角点、恢复、480/600、不可达压迫等保留；审计统计可留引用 |
| bug4 飞行附记 | §7.1 32 像素净空、绕行后直追及数值不变保留 |
| 珍珠附记 | 成长效果保留，持久化/旧档兼容遗漏，见 R1 |
| B-024：伤害 / 连闪 / 恢复 | §4～6 与 T3 第4～6、12节冻结值一致 |
| B-011：旧两条件救场 | §10/11 改成三条件，严格低于一半即两人全倒，保持一次事件 |
| §12 奖励 | +2/+7/+11 保留，删旧覆盖说明不改义 |

## 八条歧义与解释依据

1. 普通命中不清除天人待反击：成立，原修订明确覆盖较早的相反实现记录，非自行增加保护。
2. 救场三条件 / 优先级：成立，原文已规定致命伤扣血前拦截及共享一次事件；没有另造条件排序。
3. 当前全部敌人：成立，10-14 补丁、10-16 修订与 T5.4 配置一致。
4. 时间暂停：成立，剧情冻结战斗、救场完成继续与 §11 剧情不扣时合读，没有放开救场计时。
5. 死亡 / 失败：成立，普通死亡沿用检查点，超时是独立重试；界面引用 T5.4，不把 A-011 扩大到普通死亡。
6. 10 前后摇：成立，较新 0.18/0.32 覆盖 0.3/0.65，每击10与不可败不变。
7. 救场后战斗：成立，较新三波覆盖原一轮阶段记录，救场前第二波兜底不是救场后三波之一。
8. outputs 审计：成立，移除不入库文件引用、保留入库实施说明合理；不能据此删除有效行为规则（R2）。

## 测试与独立证据

- 只改了 T2 断言；既有规则断言未删除，新增现行版检查能拦住旧正文、旧救场条件和若干关键数值，但无法替代逐条语义核对。
- 独立内存变异不写被测文件：规划文档套件基线 **35/0**；换回旧 T2 **3 失败**、同帧改超时优先 **2**、删除不回血 **1**、加入留到 T3 **2**，与交付一致；反转珍珠兼容条件仍 **35/0**。无错误异常。日志及结果 `codexandclaude/runs/doc008-review-mutations.json`。
- 跨文档清单的 T1 按标题引用、T5.4 §7 未决旧话、§6.3 威胁单位旧话、T5.3 旧前后摇/阶段记录均存在，留后续改写符合范围。本任务没有擅自修这些文件；审查也不要求越界修改。
- 固定交付 SHA 独立 G3 **109/109 + 67/67**，起止干净、content_stable=True；纯文档未跑 G2。自动摘要如下。

变异结果 SHA256：`fec88a4361635a566c466f4e295ccc8d421ab87c2604977c9ca81c8de3a15fa4`。

<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`focused`。
被测SHA：`8726ab4e3b5fad1b26a881f1933a607376c9251b`；工作区：`D:\31days\codexandclaude\worktrees\codex`。
工作区状态：**干净**。
开始：2026-10-23T19:43:19.904319+00:00；结束：2026-10-23T19:43:35.459107+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\codex\\codexandclaude\\tools\\run_checks.py", "focused", "--python-all"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G3:tests：实际109 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\cmd\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`6fc679a2b101aff827c38532aeba5eb2628cfd5f`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`450ad934b66366a75de851f533b856a3b68aecec5e38ed10da7030c6fbb1664e`；工作区范围指纹（原始字节）：`5e52a016c977cd588ba823a8e126ae22014eb037ffaa6ed657b3b92331d2b8fc`。
全工作区指纹：`01b4071a81db922187c1034e4a32e1f4d3d2ea3f974534c8933b75ce64122a55`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\cmd\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T194319.903319Z\001.txt`；SHA256=`289f21d8089ec88c091a8038f1ed86f32e0915f5a604b6d63fc6719e39c5a2e3`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T194319.903319Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.266秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T194319.903319Z\003.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\cmd\\git.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T194319.903319Z\004.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T194319.903319Z\005.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.203秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T194319.903319Z\006.txt`；SHA256=`3bf72a12298d660c634d52b3b8c0c0725341041d4f746d86fe15b891d0274fe4`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=10.953秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\codex\codexandclaude\runs\20261023T194319.903319Z\007.txt`；SHA256=`56e382daac9f3dae183e3f288316bb218280ef9c8b05421b5a743a22ea3af6f0`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
