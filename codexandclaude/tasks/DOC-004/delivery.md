# DOC-004 交付记录

实现者：Claude｜日期：2026-10-19
基线：`82ba37e`（master，含 SYS-002 收尾与待办清单）
实现 SHA：`6595c88705b8f4b5355c87c3fe14d67b359f7deb`｜分支：`claude/DOC-004`｜工作区：`worktrees/claude`

## 改动

| 文件 | 内容 |
| --- | --- |
| `codexandclaude/collaboration.md` | 改写为 V2.3 唯一现行规范（12 节）：原则、角色、任务类型与分级（含方案探讨、探索型任务）、目录与状态、生命周期、任务卡模板、质量门矩阵、审查要求、Git 与工作区、文档规则、人工执行与许可、修订记录 |
| `codexandclaude/plan_v2.md` | 首部状态改为“已并入”并链接 collaboration.md；修订记录加一行；其余正文保留为历史 |
| `codexandclaude/env.md` | 新增“Git 与提交（V2.3）”：safe.directory、`git commit -F`、CRLF、`.svg.import` 还原 |
| `codexandclaude/README.md` | 现行依据改为协作规范 V2.3；plan_v2 标为历史记录 |
| `codexandclaude/BOARD.md` | 规则链接改为 collaboration.md；表头注明汇总基线；SYS-002 已完成；新增 DOC-004 行 |
| `codexandclaude/BACKLOG.md` | 表头注明汇总基线；BL-001 已完成（SYS-002）；BL-002～005 已立项 DOC-004；BL-103 按 Codex 意见改写并升为 P1；新增 BL-104 证据自动汇总（P1）、BL-105 通用 G4 验收启动器（P2） |
| `codexandclaude/tests/test_collaboration.py` | plan_v2 测试改为检查“已并入”与 README 指向；新增 V2.3 规范测试，检查从 V2.2 继承的 20 条安全边界与 9 条新增规则、S/M/L 分级、章节编号，以及 env.md 的四项环境细节 |
| `codexandclaude/tasks/DOC-004/task.md` | 新增任务卡（含用户批准原话与三方意见原文要点） |

## 三方意见的落实位置

| 意见 | collaboration.md 位置 |
| --- | --- |
| 用户 1：保留转话 | §1 原则 2；§5 末“用户转话的固定要素” |
| 用户 2：相互优化代码、探讨需求 | §1 原则 6；§3.2 方案探讨；§8 第 3 条优化建议 |
| 用户 3：UI 与交互不要死板 | §1 原则 6；§3.3 探索型任务（2～3 个可操作原型、规格可偏离但需标出并经用户选中后同步修订）；§7 矩阵“探索型原型”行 |
| Codex 1：规划合并简化 | §5 第 3 步（M/L 默认先行、批量合入、S 级与会话批准可同分支） |
| Codex 2：提交说明用文件 | §9；env.md“Git 与提交” |
| Codex 3：G4 入口前置 | §5 第 6 步；§6 模板“验收入口”；§7 矩阵“验收脚本”行 |
| Codex 4：测试分散登记 | 工具任务，记入 BACKLOG BL-103 |
| Codex 5：证据自动汇总 | 工具任务，记入 BACKLOG BL-104 |
| Codex 6：收尾责任与主目录例外 | §4 第 2 条（刷新责任与基线 SHA）；§5 第 9 步；§9 第 1 条（集成者在 master 的例外） |
| Claude 1：变异检查 | §8 第 2 条 |
| Claude 2：S 级界线 | §3.1 表格 S 行（四个同时满足的条件） |
| Claude 3：环境细节 | env.md“Git 与提交” |

## 从原规范与 V2.2 保留的安全边界

原 collaboration.md（V1）的人工触发、手动审批、不互传令牌、不安装依赖/推送/删除工作区/改全局配置、保护未提交改动、同一文件只属于一方、跨职责改动须用户同意、UI 归属先调查等规则，全部保留在 §1、§2、§9、§11。V2.2 的固定 SHA 审查与合并、两轮上限、失败暂停与 revert、交付记录不写自身哈希、质量门矩阵与通过条件等，全部保留在 §5～§7。

## 需审查者留意

1. **本任务自身的流程**：按用户在会话中批准的简化规则，任务卡与实现放在同一分支，没有单独规划合并。该规则在 V2.3 §5 第 3 步中成文。
2. **探索型任务的原型位置**：写为 `codexandclaude/prototypes/<ID>/` 或游戏内预览场景，并要求不得修改正式游戏代码、存档或输入配置。若 Codex 认为游戏内预览场景放在 `game/` 下会与“不改正式代码”冲突，请提出具体放置约定。
3. **方案探讨的适用范围**：写为功能类任务必做，小缺陷修复、文档改写和工具任务可跳过。请判断这个界线是否合适。

## 先失败、后修复

本任务先改文档、后改测试。为确认新测试能区分新旧规范，核对了基线 `82ba37e` 中的 collaboration.md：“状态：现行规范”“方案探讨”“探索型任务”“变异检查”“批量合入”“git commit -F”“集成者可以在 master 上直接提交”均不存在；基线 plan_v2.md 也没有“状态：已并入”。因此新断言在基线上必然失败，在实现上通过。

## 检查结果

纯文档：只跑 G3，不需要 G2、G4。

| 检查 | 命令 | 结果 |
| --- | --- | --- |
| G1 | `python -m unittest discover -s codexandclaude/tests -p test_collaboration.py` | 14/14 通过 |
| G3（提交前） | `python codexandclaude/tools/run_checks.py focused --python-all` | tests/ 81/81，codexandclaude/tests/ 39/39，退出码 0 |
| G3（实现 SHA） | 提交后同一命令 | sha=实现 SHA，dirty=false，81/81 + 39/39，退出码 0 |

## 审查请求

请 Codex 以 `git switch --detach <交付SHA>` 固定后审查：确认实现到交付之间只有本记录与任务卡状态变化；对照任务卡“依据”逐条核对三方意见是否如实、完整地写入；检查是否遗漏 V2.2 或原规范的有效规则、新规则之间有无矛盾；判断上面“需审查者留意”的三点；独立复跑 G3。
