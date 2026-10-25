# DOC-009 交付记录：T3 改写为现行版

状态：已交付，待 Codex 审查｜实现：Claude｜日期：2026-10-24

## 固定对象

- 基线：master `6af7804399644ca936ebe78ab65fee6a0210c2ba`（SYS-011 集成之后）。
- 实现提交：`4c685be7021554009c31ae081b2ba948ca5430cf`（分支 `claude/DOC-009`），只改 `Words/T3_可能性_基础属性_成长_死亡.md`、`Words/T1_核心玩法与玩家操作.md`（两处引用）与 `tests/test_planning_documents.py`。
- 本记录与任务卡首部状态另行提交，不改实现文件。

## 改动概要

- **T3**：
  - 删除顶部三段补丁、12 行行内修订标记、§10 的“实施标记”与 §14 之后的 7 个按日期追加段（含其中的行内修订与 2 段加粗附记），全部并入正文。
  - §1～§13 编号与标题不变；§5 下新增 “5.1 应急药包”。原 §14“来源与确认记录”改为 “14. 变更记录”：先写来源与冻结时的确认事项，再列 20 行变更表，本次改写为最后一行。
  - B-001～B-005、B-025、B-026 改为现行规则（见“B 类去向”）；§12 只保留仍未定的三项。
  - 首部加“现行版更新：2026-10-24”和说明：本文是资源与成本数值的权威位置，战斗细则见 T2、计时见 T4、Room 与 Node 见 T5.3／T5.4。
- **T1**：§4.2 与 §9 两处“见T2‘2026-10-16追加修订：10一次性救场与协同测试’”改为“见T2第10节”（DOC-008 跨文档清单第一项）。T1 其余内容与变更记录表不动。
- **tests/test_planning_documents.py**（只改 T3 断言与 T1 那一处引用断言）：
  - T1：原“必须含旧修订标题、不得含 T2第10节”改为“§4.2 须含‘见T2第10节’、全文不得再含旧修订标题”，三个触发条件与两种旧表述的反向断言保留。
  - `test_t3_unresolved_edges_are_visible`：原要求 §12 仍列出七项（多数已确认）；改为 §12 须列出仍未定的三项，已解决的六项不得再留在 §12，其余两条断言保留。
  - 新增 `test_t3_is_current_spec_with_change_log`：无行内标记、加粗日期段与日期标题；14 节标题逐一核对；变更记录表头与 8 个日期；正文不得出现 16 条旧表述；§2～§10 逐节断言 54 条现行规则（含存档兼容、互斥、回滚、过期与旧档保护等约束）；另对 4 种反写措辞做反向断言。
  - 其余 T3 断言（恢复 3→2、上限序列、击杀奖励、生命与伤害算术、死亡 -9 与 50%、死亡菜单、残存可能性实体等）全部保留，未放宽。

## 修订去向对照表

| 原位置 | 原修订 | 改写后位置 | 说明 |
| --- | --- | --- | --- |
| 顶部 | 2026-10-18 应急药包修订 | §5.1 | 全部条款保留；补“位置见T5.3”“使用时机见T1第5节” |
| 顶部 | 2026-10-18 日期批次：无色实体 13/15/17，救助过期 | §7（生命）；§9“随日期过期” | 旧槽保护按 B-005 写全 |
| 首部下方 | 关联修订标记（2026-10-15）：下攻击弹起 50%，伤害仍 5 | §7 表“下落攻击伤害” | “修订前的2倍”移入变更记录 |
| §3 末段 | 【10-15 用户追加确认】敌人重置后再次击杀仍获得可能性 | §3 末段 | 去掉标记 |
| §4 第 2 段 | 【10-15 追加修订】地面/空中闪避共用规则 | §4 第 2 段 | 去掉标记 |
| §4 第 3 段 | 【10-15 确认】扣费低于 -9 拒绝 | §4 第 3 段 | 与 §12 的透支边界合并 |
| §5 末段 | 【10-15 用户确认】滑步取消、松键不退款 | §5 末段 | 与 §12 主动中止恢复合并 |
| §7 表 | 【10-15 追加关联修订】下攻击弹起 50% | §7 表 | 去掉标记 |
| §10 首部 | 实施标记（10-15）：检查点、分槽存档接入灰盒 | §14 变更记录 | 实施进度不是规则；“原生命测试场景保留无存档出生点重试”是灰盒实验室说明，不写入规格 |
| §10 末段 | 【10-15 用户确认并实施】50% 向下取整 | §10 | 去掉标记 |
| §12 | 【10-15】透支边界 | §4 第 3 段 | B-003 |
| §12 | 【10-15】连闪计时 | §4 第 2 段 | B-003 |
| §12 | 【10-15】主动中止恢复 | §5 末段 | B-003 |
| §12 | 【10-15】死亡保留，正常退出不扣减、不发复活无敌 | §10 | B-003 |
| §12 | 剧情奖励未决 | §3 表“7剧情奖励” | B-001 |
| §12 | 重复帮助未决 | §8 | B-002 |
| §12 | 保底实体 | §12（仍未定部分）、§11 | 原文同时在两处，保留 §12 的未定部分 |
| 追加 1 | 2026-10-15 麦秆镇救助与首次成长 | §3、§8、§9 | “后续 13～15 仍待接入”“其他 NPC 奖励口径待落实”是阶段记录，已被后续修订与 B-002 取代 |
| 追加 1 内 | 【10-16】沟壑第二间救助 | §8、§9 | “14/15 尚未实现”为阶段记录；“新增独立来源校验”写成“成长按 NPC 来源分别记录与校验” |
| 追加 1 内 | 【10-16】沟壑第三间清敌救助 | §8、§9 | “珍珠仍为持久占位”已被 10-18 珍珠修订取代 |
| 追加 2 | 2026-10-17 寄生同伴者闪避强化 | §2、§4 末段 | “外围门内 NPC 及 15 上限仍未接入”为阶段记录，已被追加 3 取代 |
| 追加 3 | 2026-10-17 外围尖刺救助 | §8、§9 | 挑战参数、放弃、回滚、工程事件名全部保留 |
| 追加 4 | 2026-10-17 渴望俯视攻击范围强化 | §2（摘要）→ T2 §2 | 规则与保存条款已在 T2 §2 完整写明（DOC-008 第1轮审查补齐），T3 只引用，避免同一规则两处完整描述 |
| 追加 5 | 2026-10-18 三日自然计时 | §10“计时与死亡”；其余见 T4 | T4 有同一修订全文，为计时的权威位置；T3 只保留与资源、死亡相关的部分，见歧义第 3 条 |
| 追加 5 内 | **珍珠范围强化**（加粗） | §2（摘要）→ T2 §2 | 同追加 4 |
| 追加 6 | 2026-10-21 UI-002 画面表现 | §2 末段 | 全文保留 |

## B 类去向

| 编号 | 改写后 |
| --- | --- |
| B-001 剧情奖励 | §3 表：7 剧情结束后补满可能性；返回 7 完成注视结算时 10→12、余额不补满；不另发固定 +10，不叠加 |
| B-002 重复帮助 | §8：四位可帮助 NPC 各 +4 一次、成长一次；同一 NPC 不能用两种方式各领一次 |
| B-003 四条已确认细则 | §4、§5、§10，见对照表 |
| B-004 注视前帮助 | §8 结算规则第 3 条 |
| B-005 NPC 随日期过期 | §9“随日期过期”，含旧存档已见 NPC 的一次救助机会保护 |
| B-025 永久成长范围 | §2：上限、攻击范围、闪避速度三类 |
| B-026 不新增 Boss | §7 末段与 §10 表“敌人状态”：Boss 未击败时死亡重置该场 Boss 战，击败后永久保留 |

## 歧义与解释依据

1. **“清敌前可确认永久放弃并撤回”**（沟壑第三间）：原句可读成“确认放弃后撤离”或“可以撤回放弃”。没有其他文档能定，原句照写，不自行解释。
2. **外围的“开门、救助、确认放弃均保存成功才生效”**：原文只出现在外围修订里，改写时只用于外围；其他 NPC 写的是“救助与注视分别与各自奖励同次保存，失败回滚并可重试”，没有把外围条款推广到全部 NPC。
3. **三日自然计时与 NPC 失救**：该修订末段写“自然日期不会自动判 NPC 死亡/失救”，与同日的日期影响批次相反。按 B-005 的结论（日期影响批次明确写明覆盖 NPC 时间窗的阶段记录）写成 §9 的过期规则，删去这句。计时的其余条款（停表范围、存档字段、Esc 不能绕过重试等）以 T4 的同名修订为准，T3 只保留与资源、死亡相关的部分：死亡动画与菜单停表；第 3 日探索超时保留生命、可能性与永久进度，不补满、不做死亡扣减；最终战已开始时沿用原预算，不赠送 30 分钟，死亡与读档不回补该预算。“死亡与读档不回补”在原文中只针对最终战预算，改写时也只写在那里。
4. **Boss 战死亡**：原 §10 写“V0.1 不新增 Boss，因此本版敌人按此规则重置”。按 B-026（来源 T0 第 7 节 2026-10-11 行、T5.4 的 Boss 实施补充）写成“非 Boss 敌人重置；Boss 未击败时死亡重置该场 Boss 战，击败后永久保留击败记录”。
5. **永久成长不只上限**：原 §2“只开放可能性上限”按 B-025 改写；攻击范围与闪避速度的数值与保存规则分别以 T2 §2 与本文 §4 为准。
6. **“首次救助任务”**：§8 表原文保留；正文写明这对应麦秆镇救助后返回 7 完成注视（来源 10-15 修订）。

## 跨文档不一致清单（不在本任务修改）

| 位置 | 问题 | 建议 |
| --- | --- | --- |
| T4 2026-10-18 三日自然计时修订末段 | 仍写“自然日期不会自动判 NPC 死亡/失救”，与日期影响批次相反（B-005） | T4 改写（BL-024）时按 B-005 处理 |
| T5.4 同名修订末段 | 同上 | BL-025 |
| T7 核对表 §1 第 29 行 | 仍按旧口径写“T3 §10（死亡菜单：返回检查点、返回标题、设置）”，A-014 已改为四项 | 核对表是历史核对记录，如需可在下次规划刷新时加注 |
| T1 §9 变更记录 | 本次只改了 T1 两处引用，没有为此加变更行（任务卡限定“不改其他内容”） | 若希望 T1 变更记录也反映这次引用修正，可在后续文档任务补一行 |
| DOC-008 清单中 T5.4 §7、§6.3 与 T5.3 的旧表述 | 未处理 | 随 BL-025 |

## 检查

实现提交上起点干净执行 `python codexandclaude/tools/run_checks.py focused --python-all`：**通过**，G3 tests **110/110**（新增 1 个测试），codexandclaude/tests **67/67**，content_stable=True。摘要 `codexandclaude/runs/20261025T054402.360558Z/`（不入库）。

**变异**（逐项只改一处，跑 `tests.test_planning_documents` 与 `tests.test_game_project`，按原字节恢复；结果 `codexandclaude/runs/doc009-mutations.json`，不入库）：

| 变异 | 结果 |
| --- | --- |
| T3 换回改写前全文 | 2 个测试失败（现行版测试、§12 未决测试） |
| 药包旧档兼容反写为“旧存档补发” | 1 项失败 |
| 删去“同一 NPC 不能用两种帮助方式各领一次” | 1 项失败 |
| 删去旧存档已见 NPC 的救助机会保护 | 1 项失败 |
| 剧情奖励改为另发固定 +10 并叠加 | 1 项失败 |
| 注视前帮助改为立即提高上限 | 1 项失败 |
| Boss 重置写回“不新增 Boss” | 2 项失败 |
| 过期救助仍发 +4 | 1 项失败 |
| T1 退回按旧修订标题引用 T2 | 1 项失败 |

<!-- G3 自动摘要 -->
<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`focused`。
被测SHA：`4c685be7021554009c31ae081b2ba948ca5430cf`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-25T05:44:02.360558+00:00；结束：2026-10-25T05:44:32.778985+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "focused", "--python-all"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G3:tests：实际110 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`7c57e4335962eb2707c6e9f9d864dff552eb93f4`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`404ee75fdc23bb6a1853b0a49383c9a20e87e87793d8f8049a95160a07025344`；工作区范围指纹（原始字节）：`8ada66e685bafe9096f5eb085eab4380f45ca1f4969f4f88c43f1728c86f68eb`。
全工作区指纹：`21a8893ed9b8a820f0a2014b6cd2fa3256a604bac1be98513b01e2b27ff95a67`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T054402.360558Z\001.txt`；SHA256=`095c9b666562d757558d4f6b67a823dcb7eef1c199a67ceba87f013ea6a87539`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.094秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T054402.360558Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.437秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T054402.360558Z\003.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.031秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T054402.360558Z\004.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.016秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T054402.360558Z\005.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=4.703秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T054402.360558Z\006.txt`；SHA256=`83963c1b0ace361f3fee5172e98fe4fdafc54fcd43939d5f8f1299a2c0ac9fb0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=23.062秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T054402.360558Z\007.txt`；SHA256=`cb4439eeafdf678a10b5301798aa7800f0783dd27cfafb0ea7688b85e3cfcebe`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
