# DOC-010 交付记录：T4 改写为现行版

状态：已交付，待 Codex 审查｜实现：Claude｜日期：2026-10-25

## 固定对象

- 基线：master `68e8a9993e1327a96720ad506eada8d9184cf33a`（PLN-002 集成之后）。
- 实现提交：`3bab3d52804d653269adb7662261753a82862de8`（分支 `claude/DOC-010`），只改 `Words/T4_3天倒计时系统.md` 与 `tests/test_planning_documents.py` 的 T4 断言。
- 本记录与任务卡首部状态另行提交。

## 改动概要

- **T4**：删除顶部两段补丁、6 行行内修订标记、§10 两段实施修订与文末 3 个按日期追加段，全部并入正文；§1～§9 编号与标题不变；原 §10“来源与确认记录”改为“10. 变更记录”（来源说明 + 12 行变更表，本次改写为最后一行）。
- **统一阶段用语**（DOC-009 审查教训）：首部定义“日内时间”“第3日剩余”“最终战预算”“正式开战”，全文统一使用；尤其把原 §3.3“触发10剧情时启动15分钟倒计时”改为“最终战正式开战时启动最终战15分钟倒计时”（依据 B-009 与 2026-10-17 修订“正式开战取15分钟与第三日剩余较小值”），并写明“正式开战不是进入逆时战场或触发10剧情的时刻”。
- **B-005～B-010 写成现行规则**：日期推进（§2）、Day2 Boss 为寄生同伴者（§3.2）、最终战预算（§3.3）、超时处理（§4）、随日期变化与救助过期（§5）；§9 只保留 A-004、A-005 的两项未决内容。
- **tests/test_planning_documents.py**：
  - `test_t4_accepted_revisions_and_scope_boundaries`：原要求 §9 仍列出六项（多数已解决）；改为 §9 须列出仍未决的两项、已解决的五项不得再留在 §9，其余三条断言保留。
  - 新增 `test_t4_is_current_spec_with_change_log`：无标记与日期段、10 节标题逐一核对、变更记录表头与 9 个日期；正文不得出现 10 条旧表述；§2～§5 逐节断言 35 条现行规则；阶段用语定义断言，并对“进入逆时战场时启动”“触发10剧情时启动”“死亡与正常读档回补”“超时优先”做反向断言。
  - 其余 T4 断言（时钟与日期转换、世界变化与 31 天分离、“未来已失”界面、同帧胜利优先等）全部保留，未放宽。

## 修订去向对照表

| 原位置 | 原修订 | 改写后位置 | 说明 |
| --- | --- | --- | --- |
| 顶部 | 2026-10-18 日期影响批次 | §5“已确定的随日期变化”；§9（换怪、地形变体） | 救助过期与旧槽保护按 B-005 写全 |
| 顶部 | 后续配置更新（2026-10-14） | §3.3、§4；§10 变更记录 | “失败菜单、重试及暂停细则仍需明确”已由 B-010、A-011 解决 |
| §4 表 | 【10-15】玩家拖延 | §4 表 | 去掉标记 |
| §4 表 | 【10-15】刷怪机制 | §4 表 | 去掉标记 |
| §4 末段 | 【10-15】普通敌人重置后照常发可能性 | §4 末段 | 去掉标记；“覆盖此前有限刷新方向”移入变更记录 |
| §9 | 【10-15】刷新额度 | §4（规则已在表中） | 已解决，从 §9 删去 |
| §9 | 日期推进 | §2“日期推进” | B-007 |
| §9 | Day2线索BOSS | §3.2 | B-008 |
| §9 | 临界计时 | §3.3“最终战预算” | B-009 |
| §9 | 超时结算 | §4“超时处理” | B-010 |
| §9 | 配置与存档 | §2（存档字段、保存时机）；§5（NPC 窗口）；§9（世界变化阈值仍未决） | 拆分 |
| §10 | 【10-15】入口灰盒：沟壑入口至少第 2 日，不重复不倒退，同次保存；旧槽默认第 1 日 | §2“日期推进” | “自然计时、超时、离线、敌人强化未实现”“HUD 仅日期”为阶段记录，已被后续修订取代 |
| §10 | 【10-16】寄生同伴者通路至少第 3 日，同次保存 | §2、§3.2 | “强化待领取”已由渴望俯视战斗成长修订取代（T2 §2）；“仅事件日期”为阶段记录 |
| 追加 1 | 2026-10-17 10 强化与最终战闭环 | §3.3、§4、§2（旧档第 3 日初始化） | 计时、超时、重试、胜利停表、保存重试写入本文；10 的数值、波次构成与增援、平台、普通死亡检查点属于 T2 §9、§11 与 T3 §10，只引用 |
| 追加 2 | 2026-10-18 三日自然计时 | §2（停表范围、日期推进、存档字段、保存时机）、§4（探索超时、Esc 不能绕过重试） | 末段“自然日期不会自动判NPC死亡/失救、不新增或强化敌人”与同日日期影响批次相反（B-005），删去；“HUD 显示日期/分秒”已被 UI-002 取代 |
| 追加 3 | 2026-10-21 正式 HUD 时间显示 | §2“HUD时间显示” | “第四批暂停菜单任务实现”为阶段说明，删去 |

## 歧义与解释依据

1. **倒计时的起点**：原 §3.3 写“触发10剧情时启动15分钟倒计时”，2026-10-14 补丁写“大战Node启动最长15分钟临界计时”，2026-10-17 修订写“正式开战取15分钟与第三日剩余较小值”。按 B-009 与 T5.4 N004 统一为“最终战正式开战（NSZC_10003_1_N004）”；10 剧情（救场）发生在正式开战之前，见 T2 §10、§11。
2. **“不新增或强化敌人”**：2026-10-18 自然计时修订末段说时钟本身不新增或强化敌人，同日日期影响批次随后给出了无色实体随日强化。两句不矛盾（前者说时钟交付本身，后者是另一批次），但“不强化”一语现已不成立，所以不写入正文；随日变化以第 5 节为准。
3. **最终战保存失败**：原文“保存失败均保留重试，不提前宣告完成”是对 10-17 修订中开战、胜利、对话、结束状态各次保存的总括；§3.3 照此写成一条，不再细分到具体界面提示文字（那是实现）。
4. **旧档初始化**：10-17 修订“旧档第三日从本版本采用时按30分钟初始化”与 10-18 修订“已有第三日 / 最终战计时原样保留”同时成立：前者针对缺少第 3 日剩余字段的旧档，后者针对已有该字段的存档；§2 两句并写。
5. **救助过期与主动放弃**：原文“过期无奖励且与主动放弃独立”，写作“两种独立的情况”，避免用“结局”一词与 T0“不做多结局”混淆。

## 跨文档不一致清单（不在本任务修改）

| 位置 | 问题 | 建议 |
| --- | --- | --- |
| T5.4 2026-10-18 三日自然计时修订末段 | 仍写“自然日期不会自动判NPC死亡/失救” | 已登记在 BL-025 |
| T5.4 §7“倒计时”“日期推进” | 仍列为需明确 | 随 BL-025 改为引用 T4 §2、§3.3 |
| T2 §11、T3 §10 | 用“正式开战”“最终战预算”的说法与本文一致，未见冲突 | — |

## 检查

实现提交上起点干净执行 `focused --python-all`：**通过**，G3 tests **111/111**（新增 1 个测试），codexandclaude/tests **67/67**，content_stable=True。摘要 `codexandclaude/runs/20261025T094446.587081Z/`（不入库）。

**变异**（逐项只改一处，跑 `tests.test_planning_documents` 与 `tests.test_game_project`，按原字节恢复；结果 `codexandclaude/runs/doc010-mutations.json`，不入库）：

| 变异 | 结果 |
| --- | --- |
| T4 换回改写前全文 | 2 个测试失败 |
| 同帧改回超时优先 | 2 项失败 |
| 写回“自然日期不会自动判NPC死亡/失救” | 1 项失败 |
| 删去普通对话、放弃确认、死亡菜单停表 | 1 项失败 |
| 删去“死亡与正常读档不回补最终战预算” | 1 项失败 |
| 删去“Esc 不能绕过明确重试” | 1 项失败 |
| 倒计时改为“触发10剧情时启动” | 2 项失败 |
| 删去“不重复补时，也不倒退” | 1 项失败 |
| 删去旧存档已见 NPC 的救助机会保护 | 1 项失败 |

<!-- G3 自动摘要 -->
<!-- run_checks evidence v1 -->
总结果：**通过**；模式：`focused`。
被测SHA：`3bab3d52804d653269adb7662261753a82862de8`；工作区：`D:\31days\codexandclaude\worktrees\claude`。
工作区状态：**干净**。
开始：2026-10-25T09:44:46.588083+00:00；结束：2026-10-25T09:45:10.090892+00:00。

入口命令（JSON参数数组）：`["C:\\Users\\Administrator\\AppData\\Local\\Programs\\Python\\Python310\\python.exe", "D:\\31days\\codexandclaude\\worktrees\\claude\\codexandclaude\\tools\\run_checks.py", "focused", "--python-all"]`。
检查（缺项均不通过；env只代表环境探测，不代表G2/G3）：
- G3:tests：实际111 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。
- G3:codexandclaude/tests：实际67 / 预期unittest发现数（未独立枚举）；完整=True；通过=True。

工具版本：
- python：`3.12.14 / openpyxl=3.1.5`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`。
- git：`git version 2.56.0.windows.2`；`C:\Program Files\Git\ucrt64\bin\git.exe`。
- node：`v24.22.1`；`C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe`。

提交树：`11a29aea3a77303d16d2e4b72d4d0c8cfd86f90a`；指纹范围：`['exclude codexandclaude/runs/**', 'exclude codexandclaude/tasks/<ID>/{delivery,review,integration,acceptance}.md']`。
已提交范围指纹：`1deb4d048b5b90bec758ddae4b6bee0226ed3d9fa584f5909ab5515cfc765126`；工作区范围指纹（原始字节）：`6ce05e19c8c5dfbb4f96cf3d0960b04d50f2077d9347043f474bf7bdbf155f15`。
全工作区指纹：`1c9455c1fd35e71c19085ff61d3d8c65435c11a5b311ac2aefeb57d52a0e2b1a`；运行前后内容稳定：`True`。
内容身份说明：起止快照不一致时，检查结果照实保留，但该运行不可作为复用来源；不是对运行期间每次瞬时写入的监控。
已跟踪总diff SHA256：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`；未暂存diff：`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。

实际命令与日志（参数为JSON数组）：
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "rev-parse", "HEAD"]`；退出=0；耗时=0.032秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T094446.587081Z\001.txt`；SHA256=`80a549238ffb369f4e4e5c93f26fad0c71c192273466009ebeb9b5bfdfc1e309`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "status", "--porcelain", "--untracked-files=all"]`；退出=0；耗时=0.046秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T094446.587081Z\002.txt`；SHA256=`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-c", "import sys,openpyxl; print(sys.version.split()[0]); print(\"openpyxl=\"+openpyxl.__version__)"]`；退出=0；耗时=0.328秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T094446.587081Z\003.txt`；SHA256=`6d8032bb36596789957df461b308076a9002b5585e5b4d43f8a62b51f0ac622b`。
- `["C:\\Program Files\\Git\\ucrt64\\bin\\git.exe", "--version"]`；退出=0；耗时=0.047秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T094446.587081Z\004.txt`；SHA256=`dc0a995f896e73e8fc394cc5dc4d8cabfea65b5eb2db4a40d134dc21c4feb3c0`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\node\\bin\\node.exe", "--version"]`；退出=0；耗时=0.015秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T094446.587081Z\005.txt`；SHA256=`b8a527ca60b496131eccd1fcbeccf289ebc0a7e63be57e4b4c6f8f67648bcc07`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "tests", "-v"]`；退出=0；耗时=3.172秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T094446.587081Z\006.txt`；SHA256=`ba3ed30db3c6a9b8ec4c7608aa6e16f36178920703e8ed385f8608a81b55cafb`。
- `["C:\\Users\\Administrator\\.cache\\codex-runtimes\\codex-primary-runtime\\dependencies\\python\\python.exe", "-m", "unittest", "discover", "-s", "codexandclaude/tests", "-v"]`；退出=0；耗时=18.485秒；超时=False；日志=`D:\31days\codexandclaude\worktrees\claude\codexandclaude\runs\20261025T094446.587081Z\007.txt`；SHA256=`156de998fde1dc7edd5e63efa4688f83a9ee02b15bb061026e16e63191d7d03e`。

失败清单：无。
失败归因：未提供基线失败证据，不自动区分旧失败与新失败。
复用限制：只比较内容不替代审查/授权；须成功完整且干净、运行前后稳定、范围相同的来源；只改记录时G2可复用，G3必须重跑；另核对工具、命令和外部依赖。
