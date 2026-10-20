# DOC-007 交付记录

实现者：Claude｜审查者：Codex｜分支：`claude/DOC-007`｜基线：`2013c34117d37cbb66ce62ef29b9dfbc850abd48`
实现 SHA：`58348bbf0c407a66df238bc4a923176e5a1397a8`

## 改动

| 文件 | 内容 |
| --- | --- |
| `codexandclaude/ROADMAP.md`（新增） | 现状快照（每条注明代码或文档位置）、里程碑 M1～M5、M2 UI 分批、第一批建议、需要用户提供或决定的事项、变更记录 |
| `codexandclaude/README.md` | “任务”一节链接路线图 |
| `codexandclaude/BOARD.md` | 汇总基线改为 master@2013c34；DOC-006 改为已完成；SYS-003 改为待合并（审查通过）；登记 DOC-007；页脚链接路线图 |
| `codexandclaude/BACKLOG.md` | BL-021 改为“已立项 DOC-007”；新增 BL-106、BL-107（SYS-003 审查的两条非阻断建议，P3） |
| `codexandclaude/tests/test_collaboration.py` | 新增 `test_roadmap_covers_every_open_backlog_item`：README 与任务板都链接路线图；章节编号连续；引用的 BL 编号都存在；所有未完成的 P1、P2 事项（BL-021 本身除外）都被引用；BL-021 状态为已立项 DOC-007；M1～M5 各有一行 |
| `codexandclaude/tasks/DOC-007/task.md` | 任务卡 |

未修改规格、游戏代码或 T6、T7 表格。

## 完成标准对照

1. 现状快照：路线图第 2 节，每行“依据”列给出路径；起草时核对了主场景配置（`game/project.godot` 第 6 行）、`verify_game.py` 登记的 73 个引擎套件、`game/world/` 下 21 个会话脚本、`game/systems/` 子目录、UI 脚本中的菜单项与启动调用 `show_slots`。
2. 完整性：由新测试自动检查；P3 与观察项在第 3 节末尾列出、不排入里程碑。
3. 里程碑表含目标、包含事项、负责、依赖、完成标志；M2 先探索后实现（第 4 节）。
4. 第一批建议（第 5 节）与依赖用户的事项（第 6 节）。
5. 排期之外的设计（视觉方向、资源来源、M5 内容）均列为待用户决定，未替用户决定。

## 检查证据

- 工具：Python 3.12.14（openpyxl 3.1.5）、Git 2.56.0.windows.2；纯文档任务不需要 Godot。
- 先写测试再写路线图：新测试与任务板测试按预期失败 2 项（缺 ROADMAP.md、DOC-007 无任务板行）。
- 实现后（未提交）：`python codexandclaude/tools/run_checks.py focused --python-all` → `tests` 92/92、`codexandclaude/tests` 43/43，全部完成并通过。
- 提交后：同一命令，被测 SHA `58348bbf0c407a66df238bc4a923176e5a1397a8`，dirty=false → `tests` 92/92、`codexandclaude/tests` 43/43，全部完成并通过；摘要 `codexandclaude/runs/20261020T085356.780498Z/summary.json`（运行目录不入库）。
- 旧失败：无；新失败：无。

## 请审查重点关注

- 现状快照是否与 master 实际代码一致（尤其 UI 菜单项、资源与音频的“只有占位”判断）。
- 有无未进入待办清单、因而也未进入路线图的剩余工作。
- 里程碑依赖与分工是否合理：BL-103 先于大批 UI 任务、BL-091 先于存档选择界面、M4 可穿插。
- 第一批三个任务是否确实互不重叠。

## 已知限制

- 路线图只排序，不估工期。

## 第1轮修订（回应审查 SHA `7a6c2299a571be44bf22d35d6badee127bda3b50`）

分支先快进到审查提交，再合并 master@`b572c7efb6bffa5dca2044d35b77b9ad0969e68c`（SYS-003 已合入，无冲突，合并提交 `209221d`）。修订 SHA：`4924ed73ad9f6b228f6d60a9f1b5d041f03409e0`。

| 意见 | 处理 |
| --- | --- |
| R1 快照漏记 | UI 行补记设置中的窗口尺寸（1280×720、1920×1080，`life_ui.gd` 第 215 行起）；音频行改为“警示音与玩家命中音”等程序占位音效，补 `placeholder_visual.gd` 依据。另把已有的珍珠/范围文字、普通敌人介绍卡、探索超时、前摇警示、错失机会文本写进快照，避免后续当作从零新增 |
| R2 必需需求无编号 | G-02→BL-042（M2-a）、G-03→BL-051（M2-b）、G-04→新增 BL-054（P2，M2-c）、G-07→BL-065 与 BL-066（M3）、G-08→BL-048（M2-c）；待办条目写明对应 G 编号和现有灰盒；路线图第 4 节新增“需求、待办、批次、现有灰盒”对照表，删除原 M2-d 行 |
| R3 BL-107 对象错误 | 改为 Room 实例 ID（`_final_resolution_room = room.get_instance_id()`）排除切房后的过期回调，保留“没有对象池，暂作观察” |
| N1 | 第一批写明各自文件范围；ENV-004 与 SYS-004 都由 Codex 做，按 ENV-004 → SYS-004 先后，或在 SYS-004 不新增套件时独立工作区并行 |
| N2 | 第 4 节开头与 M2-c 改为：新增或明显改变交互先做原型，只沿用已选交互或小修复才直接实现 |
| N3 | M1 改为“结算与存档逻辑收尾”，注明界面相关裁决在 M2 实现 |
| N4 | P3 段补 BL-106、BL-107；BL-106 写明父类 `BattlefieldRoom` 与继承链 |
| SYS-003 刷新 | BL-090 已完成（SYS-003）；任务板 SYS-003 已完成；快照与 M1 同步 |

测试改动：
- `test_roadmap_covers_every_open_backlog_item`：只有里程碑行、M2 批次行和工具线这一行算作分配；新增 G-02/03/04/07/08 的追踪检查（对照表有且只有一行，引用的待办在 BACKLOG 中写明该 G 编号，且该待办确实在所写批次里）。
- 新增 `test_roadmap_snapshot_mentions_existing_graybox_settings_and_audio`：代码中有窗口尺寸、命中音时，快照必须提到。

变异检查（在内存中替换 `Path.read_text`，只跑上述两个测试，磁盘文件不变）：

| 变异 | 结果 |
| --- | --- |
| 从 M2-b 删去 BL-040，只在文末写“未分配：BL-040” | 1 个失败 |
| 添加不存在的 BL-999 | 1 个失败 |
| 删除 G-04 对照行 | 1 个失败 |
| 把 G-03 的批次改成 M2-a | 1 个失败 |
| BACKLOG 删去所有 G-02 字样 | 1 个失败 |
| 快照删去“窗口尺寸” | 1 个失败 |
| 快照删去“命中音” | 1 个失败 |

修订后证据：
- 未提交时：`python codexandclaude/tools/run_checks.py focused --python-all` → `tests` 92/92、`codexandclaude/tests` 44/44 通过。
- 提交后：同一命令，被测 SHA `4924ed73ad9f6b228f6d60a9f1b5d041f03409e0`，dirty=false → `tests` 92/92、`codexandclaude/tests` 44/44，complete=true、passed=true；摘要 `codexandclaude/runs/20261020T093200.026213Z/summary.json`（不入库）。协作测试由 43 项增至 44 项，是新增的快照测试。
- 旧失败：无；新失败：无。工具版本同上。
