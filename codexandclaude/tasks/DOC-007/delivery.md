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

- SYS-003 合并后，任务板与路线图中“待合并”字样需要规划维护者刷新（BL-090 改为已完成）。
- 路线图只排序，不估工期。
